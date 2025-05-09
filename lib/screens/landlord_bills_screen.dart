import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';
import '../providers/bill_provider.dart';
import '../models/tenant_model.dart';
import '../models/bill_model.dart';

class LandlordBillsScreen extends StatefulWidget {
  const LandlordBillsScreen({super.key});

  @override
  State<LandlordBillsScreen> createState() => _LandlordBillsScreenState();
}

class _LandlordBillsScreenState extends State<LandlordBillsScreen> {
  TenantModel? selectedTenant;
  String? selectedBillType;
  final _amountController = TextEditingController();
  DateTime? dueDate;
  final List<String> billTypes = ['WIFI', 'WATER', 'SECURITY', 'PARKING'];

  @override
  void initState() {
    super.initState();
    Provider.of<TenantProvider>(context, listen: false).fetchTenants();
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = Provider.of<TenantProvider>(context);
    final billProvider = Provider.of<BillProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Bills')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tenant Dropdown
            DropdownButtonFormField<TenantModel>(
              value: selectedTenant,
              hint: const Text('Select Tenant'),
              items: tenantProvider.tenants.map((tenant) {
                return DropdownMenuItem(
                  value: tenant,
                  child: Text(tenant.fullName),
                );
              }).toList(),
              onChanged: (tenant) {
                setState(() {
                  selectedTenant = tenant;
                });
              },
            ),
            const SizedBox(height: 16),
            // Bill Type Dropdown
            DropdownButtonFormField<String>(
              value: selectedBillType,
              hint: const Text('Select Bill Type'),
              items: billTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (type) => setState(() => selectedBillType = type),
            ),
            const SizedBox(height: 16),
            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Due Date Picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    dueDate == null
                        ? 'Select Due Date'
                        : 'Due: ${dueDate!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => dueDate = picked);
                  },
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Assign Bill Button
            ElevatedButton(
              onPressed: selectedTenant != null &&
                      selectedBillType != null &&
                      _amountController.text.isNotEmpty &&
                      dueDate != null
                  ? () async {
                      final bill = BillModel(
                        id: '', // New bill, backend will generate
                        type: selectedBillType!,
                        amount: double.parse(_amountController.text),
                        status: 'unpaid',
                        dueDate: dueDate!,
                        propertyId: '', // Set to empty or get from context if available
                        tenantId: selectedTenant!.id,
                      );
                      await billProvider.addBill(bill, '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bill assigned!')),
                      );
                      setState(() {}); // Refresh the FutureBuilder
                    }
                  : null,
              child: const Text('Assign Bill'),
            ),
            const SizedBox(height: 24),
            // List of Bills for Selected Tenant
            if (selectedTenant != null)
              Expanded(
                child: FutureBuilder<List<BillModel>>(
                  future: billProvider.fetchTenantBillsFuture(selectedTenant!.id, ''),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No bills for this tenant.');
                    }
                    return ListView(
                      children: snapshot.data!.map((bill) {
                        String dueDateStr = bill.dueDate.toLocal().toString().split(' ')[0];
                        return ListTile(
                          title: Text('${bill.type} - KES ${bill.amount}'),
                          subtitle: Text('Due: $dueDateStr'),
                          trailing: Text(
                            bill.status.toUpperCase(),
                            style: TextStyle(
                              color: bill.status == 'paid' ? Colors.green : Colors.red,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:provider/provider.dart';

class TenantBillsScreen extends StatefulWidget {
  const TenantBillsScreen({super.key});

  @override
  _TenantBillsScreenState createState() => _TenantBillsScreenState();
}

class _TenantBillsScreenState extends State<TenantBillsScreen> {
  String? selectedStatus;
  String? selectedType;
  DateTime? startDate;
  DateTime? endDate;
  String tenantName = ''; 

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final tenantId = authProvider.auth!.id;

    // Fetch tenant bills when the screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      billProvider.fetchTenantBills(tenantId, authProvider.auth!.token, context);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Bills')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Status Filter Dropdown
                DropdownButton<String>(
                  hint: const Text('Status'),
                  value: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                    billProvider.fetchFilteredBills(
                      tenantId,
                      authProvider.auth!.token,
                      status: selectedStatus,
                      type: selectedType,
                      startDate: startDate,
                      endDate: endDate,
                      tenantName: tenantName,
                    );
                  },
                  items: <String>['Paid', 'Unpaid', 'Pending'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 16),
                // Type Filter Dropdown
                DropdownButton<String>(
                  hint: const Text('Type'),
                  value: selectedType,
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                    billProvider.fetchFilteredBills(
                      tenantId,
                      authProvider.auth!.token,
                      status: selectedStatus,
                      type: selectedType,
                      startDate: startDate,
                      endDate: endDate,
                      tenantName: tenantName,
                    );
                  },
                  items: <String>['Rent', 'Utilities', 'Maintenance'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 16),
                // Date Range Picker Button
                ElevatedButton(
                  onPressed: () async {
                    DateTimeRange? pickedDateRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDateRange != null) {
                      setState(() {
                        startDate = pickedDateRange.start;
                        endDate = pickedDateRange.end;
                      });
                      billProvider.fetchFilteredBills(
                        tenantId,
                        authProvider.auth!.token,
                        status: selectedStatus,
                        type: selectedType,
                        startDate: startDate,
                        endDate: endDate,
                        tenantName: tenantName,
                      );
                    }
                  },
                  child: const Text('Select Date Range'),
                ),
              ],
            ),
          ),
          // Tenant Name Filter Text Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tenant Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  tenantName = value;
                });
                billProvider.fetchFilteredBills(
                  tenantId,
                  authProvider.auth!.token,
                  status: selectedStatus,
                  type: selectedType,
                  startDate: startDate,
                  endDate: endDate,
                  tenantName: tenantName,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Bill List Display
          Expanded(
            child: billProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : billProvider.tenantBills.isEmpty
                    ? const Center(child: Text('No bills found'))
                    : ListView.builder(
                        itemCount: billProvider.tenantBills.length,
                        itemBuilder: (context, index) {
                          final bill = billProvider.tenantBills[index];
                          return ListTile(
                            title: Text('${bill.type} - ${bill.amount}'),
                            subtitle: Text('Due: ${bill.dueDateFormatted}'),
                            trailing: Chip(
                              label: Text(bill.status),
                              backgroundColor: bill.status == 'Paid'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

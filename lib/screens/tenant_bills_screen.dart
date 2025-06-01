import 'package:flutter/material.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/models/bill_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final userId = authProvider.auth?.id;

    if (userId != null) {
      await billProvider.fetchTenantBills(userId, context);
    }
  }

  List<BillModel> _getFilteredBills(List<BillModel> bills) {
    return bills.where((bill) {
      final matchesStatus = selectedStatus == null || bill.status.name == selectedStatus;
      final matchesType = selectedType == null || bill.type.toString().split('.').last == selectedType;
      final matchesDate = (startDate == null || bill.dueDate.isAfter(startDate!)) &&
          (endDate == null || bill.dueDate.isBefore(endDate!));
      return matchesStatus && matchesType && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final tenantId = authProvider.auth?.id;

    if (tenantId == null) {
      return const Center(child: Text('Please log in to view your bills'));
    }

    final filteredBills = _getFilteredBills(billProvider.tenantBills);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bills'),
        backgroundColor: const Color(0xFF90CAF9),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter Bills'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ...BillStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status.name,
                              child: Text(status.displayName),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => selectedStatus = value);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ...BillType.values.map((type) {
                            return DropdownMenuItem(
                              value: type.toString().split('.').last,
                              child: Text(type.displayName),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => selectedType = value);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBills,
        child: billProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredBills.isEmpty
                ? const Center(child: Text('No bills found'))
                : ListView.builder(
                    itemCount: filteredBills.length,
                    itemBuilder: (context, index) {
                      final bill = filteredBills[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: bill.status == BillStatus.paid
                                ? Colors.green
                                : bill.status == BillStatus.overdue
                                    ? Colors.red
                                    : Colors.orange,
                            child: Icon(
                              bill.status == BillStatus.paid
                                  ? Icons.check
                                  : Icons.pending,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(bill.displayDescription),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Amount: ${bill.formattedAmount}'),
                              Text('Due: ${bill.formattedDueDate}'),
                              Text('Status: ${bill.statusDisplay}'),
                            ],
                          ),
                          trailing: bill.status == BillStatus.pending
                              ? ElevatedButton(
                                  onPressed: () {
                                    context.push('/tenant/payment/${bill.id}');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF90CAF9),
                                  ),
                                  child: const Text('Pay Now'),
                                )
                              : bill.status == BillStatus.paid
                                  ? const Icon(Icons.receipt, color: Colors.green)
                                  : null,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

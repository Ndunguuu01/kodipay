import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bill_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';

class TenantBillsScreen extends StatefulWidget {
  const TenantBillsScreen({super.key});

  @override
  State<TenantBillsScreen> createState() => _TenantBillsScreenState();
}

class _TenantBillsScreenState extends State<TenantBillsScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    if (authProvider.auth != null) {
      billProvider.fetchBillsForTenant(authProvider.auth!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bills"),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: billProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : billProvider.tenantBills.isEmpty
              ? const Center(child: Text("No bills found."))
              : ListView.builder(
                  itemCount: billProvider.tenantBills.length,
                  itemBuilder: (context, index) {
                    BillModel bill = billProvider.tenantBills[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.receipt, color: bill.status == 'paid' ? Colors.green : Colors.red),
                        title: Text('${bill.type} - Kes ${bill.amount.toStringAsFixed(0)}'),
                        subtitle: Text('Due: ${bill.dueDate.toLocal().toString().split(' ')[0]}'),
                        trailing: Text(bill.status, style: TextStyle(color: bill.status == 'paid' ? Colors.green : Colors.red)),
                      ),
                    );
                  },
                ),
    );
  }
}

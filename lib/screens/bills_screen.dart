import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    final userId = authProvider.auth?.id;

    if (userId != null) {
      billProvider.fetchTenantBills(userId, context);
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
      body: RefreshIndicator(
        onRefresh: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await Provider.of<BillProvider>(context, listen: false)
              .fetchTenantBills(authProvider.auth?.id ?? '', context);
        },
        child: billProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : billProvider.tenantBills.isEmpty
                ? const Center(child: Text("No bills found."))
                : ListView.builder(
                    itemCount: billProvider.tenantBills.length,
                    itemBuilder: (context, index) {
                      return BillListItem(bill: billProvider.tenantBills[index]);
                    },
                  ),
      ),
    );
  }
}

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  _BillsScreenState createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<BillProvider>(context, listen: false).fetchBills(context);
        },
        child: Consumer<BillProvider>(
          builder: (context, billProvider, child) {
            if (billProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final bills = billProvider.bills;

            return ListView.builder(
              itemCount: bills.length,
              itemBuilder: (context, index) {
                return BillListItem(bill: bills[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class BillListItem extends StatelessWidget {
  final BillModel bill;

  const BillListItem({super.key, required this.bill});

  String getBillTypeLabel(BillType type) {
    switch (type) {
      case BillType.rent:
        return 'Rent';
      case BillType.utility:
        return 'Utility';
      case BillType.water:
        return 'Water';
      case BillType.electricity:
        return 'Electricity';
      case BillType.other:
        return 'Other';
      case BillType.maintenance:
        return 'Maintenance';
    }
  }

  String getBillStatusLabel(BillStatus status) {
    switch (status) {
      case BillStatus.paid:
        return 'PAID';
      case BillStatus.pending:
        return 'PENDING';
      case BillStatus.overdue:
        return 'OVERDUE';
    }
  }

  Color getStatusColor(BillStatus status) {
    switch (status) {
      case BillStatus.paid:
        return Colors.green;
      case BillStatus.pending:
        return Colors.orange;
      case BillStatus.overdue:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.receipt,
          color: getStatusColor(bill.status),
        ),
        title: Text('${getBillTypeLabel(bill.type)} - Kes ${bill.amount.toStringAsFixed(0)}'),
        subtitle: Text('Due: ${DateFormat.yMMMMd().format(bill.dueDate)}'),
        trailing: Text(
          getBillStatusLabel(bill.status),
          style: TextStyle(
            color: getStatusColor(bill.status),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

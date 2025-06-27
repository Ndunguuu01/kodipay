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
    final totalAmount = filteredBills.fold<double>(0, (sum, bill) => sum + bill.amount);
    final paidBills = filteredBills.where((bill) => bill.status == BillStatus.paid).length;
    final pendingBills = filteredBills.where((bill) => bill.status == BillStatus.pending).length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBills,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Gradient
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF90CAF9),
                      Colors.blue.shade700,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    // Back Button
                    Positioned(
                      top: 40,
                      left: 20,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/tenant-home'),
                      ),
                    ),
                    // Filter Button
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                        onPressed: () => _showFilterDialog(),
                      ),
                    ),
                    // Title
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Bills',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'View and manage your bills',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bills Overview
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Amount',
                            'KES ${totalAmount.toStringAsFixed(2)}',
                            Icons.account_balance_wallet,
                            const Color(0xFF90CAF9),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Paid',
                            paidBills.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            pendingBills.toString(),
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bills List
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Bills',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    billProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredBills.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No bills found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredBills.length,
                                itemBuilder: (context, index) {
                                  final bill = filteredBills[index];
                                  return _buildBillCard(bill);
                                },
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(BillModel bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bill.status == BillStatus.paid
                    ? Colors.green.withOpacity(0.1)
                    : bill.status == BillStatus.overdue
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                bill.status == BillStatus.paid
                    ? Icons.check_circle
                    : bill.status == BillStatus.overdue
                        ? Icons.warning
                        : Icons.pending,
                color: bill.status == BillStatus.paid
                    ? Colors.green
                    : bill.status == BillStatus.overdue
                        ? Colors.red
                        : Colors.orange,
              ),
            ),
            title: Text(
              bill.displayDescription,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Amount: ${bill.formattedAmount}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ${bill.formattedDueDate}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bill.status == BillStatus.paid
                    ? Colors.green.withOpacity(0.1)
                    : bill.status == BillStatus.overdue
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                bill.statusDisplay,
                style: TextStyle(
                  color: bill.status == BillStatus.paid
                      ? Colors.green
                      : bill.status == BillStatus.overdue
                          ? Colors.red
                          : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (bill.status == BillStatus.pending)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/tenant/payment/${bill.id}', extra: bill);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90CAF9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Pay Now'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bills'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterDropdown(
              value: selectedStatus,
              label: 'Status',
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
            _buildFilterDropdown(
              value: selectedType,
              label: 'Type',
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
  }

  Widget _buildFilterDropdown<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

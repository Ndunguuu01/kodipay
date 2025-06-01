import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:kodipay/models/bill_model.dart';
import 'package:intl/intl.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<BillProvider>(context, listen: false).fetchBills(context);
    } catch (e) {
      // Optionally handle error here, e.g., show a snackbar
    } finally {
      setState(() => _isLoading = false);
    }
  }
  List<BillModel> _getFilteredBills(List<BillModel> bills) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    return bills.where((bill) {
      final billDate = bill.createdAt;
      return billDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
             billDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, double> _calculateTotals(List<BillModel> bills) {
    double totalAmount = 0;
    double totalPaid = 0;
    double totalPending = 0;

    for (var bill in bills) {
      totalAmount += bill.amount;
      if (bill.status == BillStatus.paid) {
        totalPaid += bill.amount;
      } else {
        totalPending += bill.amount;
      }
    }

    return {
      'total': totalAmount,
      'paid': totalPaid,
      'pending': totalPending,
    };
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);
    final bills = _getFilteredBills(billProvider.bills);
    final totals = _calculateTotals(bills);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Ledger'),
        backgroundColor: const Color(0xFF90CAF9),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialEntryMode: DatePickerEntryMode.calendar,
              );
              if (date != null) {
                setState(() => _selectedMonth = date);
                _loadBills();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Amount',
                          amount: totals['total']!,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Paid',
                          amount: totals['paid']!,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Pending',
                          amount: totals['pending']!,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Month Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                            );
                          });
                          _loadBills();
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          if (_selectedMonth.isBefore(DateTime.now())) {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                            _loadBills();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Bills List
                Expanded(
                  child: ListView.builder(
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          title: Text(bill.description ?? ''), // Replace 'description' with the correct property from BillModel
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Room: ${bill.roomId ?? 'N/A'}'),
                              Text(
                                'Due: ${DateFormat('MMM dd, yyyy').format(bill.dueDate)}',
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'KES ${bill.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: bill.status == BillStatus.paid
                                      ? Colors.green
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  bill.status.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'KES ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
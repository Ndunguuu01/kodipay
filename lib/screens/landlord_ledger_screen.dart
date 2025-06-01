import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill_model.dart';
import '../providers/property_provider.dart';
import 'package:intl/intl.dart';

class LandlordLedgerScreen extends StatefulWidget {
  const LandlordLedgerScreen({super.key});

  @override
  _LandlordLedgerScreenState createState() => _LandlordLedgerScreenState();
}

class _LandlordLedgerScreenState extends State<LandlordLedgerScreen> {
  List<BillModel> _bills = [];
  bool _isLoading = true;
  String? _selectedPropertyId;
  DateTimeRange? _selectedDateRange;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() {
      _isLoading = true;
    });
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    try {
      final bills = await billProvider.fetchAllBills(context);
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bills: $e')),
        );
      }
    }
  }

  List<BillModel> get _filteredBills {
    return _bills.where((bill) {
      final matchesProperty = _selectedPropertyId == null || bill.propertyId == _selectedPropertyId;
      final matchesStatus = _selectedStatus == null || bill.status.name == _selectedStatus;
      final matchesDate = _selectedDateRange == null ||
          (bill.dueDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              bill.dueDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      return matchesProperty && matchesStatus && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final totalAmount = _filteredBills.fold<double>(0, (sum, bill) => sum + bill.amount);
    final paidAmount = _filteredBills
        .where((bill) => bill.status == BillStatus.paid)
        .fold<double>(0, (sum, bill) => sum + bill.amount);
    final pendingAmount = _filteredBills
        .where((bill) => bill.status == BillStatus.pending)
        .fold<double>(0, (sum, bill) => sum + bill.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBills,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:'),
                            Text(
                              NumberFormat.currency(symbol: 'KES ').format(totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paid Amount:'),
                            Text(
                              NumberFormat.currency(symbol: 'KES ').format(paidAmount),
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pending Amount:'),
                            Text(
                              NumberFormat.currency(symbol: 'KES ').format(pendingAmount),
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Property',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedPropertyId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Properties'),
                      ),
                      ...propertyProvider.properties.map((property) {
                        return DropdownMenuItem(
                          value: property.id,
                          child: Text(property.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedStatus,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Status'),
                      ),
                      ...BillStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status.name,
                          child: Text(status.displayName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(_selectedDateRange == null
                  ? 'Select Date Range'
                  : '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}'),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _selectedDateRange,
                );
                if (picked != null) {
                  setState(() {
                    _selectedDateRange = picked;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBills.isEmpty
                    ? const Center(child: Text('No bills found'))
                    : ListView.builder(
                        itemCount: _filteredBills.length,
                        itemBuilder: (context, index) {
                          final bill = _filteredBills[index];
                          final property = propertyProvider.getPropertyById(bill.propertyId);
                          String roomNumber = '';
                          if (property != null) {
                            for (var floor in property.floors) {
                              for (var room in floor.rooms) {
                                if (room.tenantId == bill.tenantId) {
                                  roomNumber = room.roomNumber;
                                  break;
                                }
                              }
                              if (roomNumber.isNotEmpty) break;
                            }
                          }
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text('${bill.displayDescription} - ${bill.formattedAmount}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Room: $roomNumber'),
                                  Text('Due: ${bill.formattedDueDate}'),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(bill.statusDisplay),
                                backgroundColor: bill.status == BillStatus.paid
                                    ? Colors.green
                                    : bill.status == BillStatus.overdue
                                        ? Colors.red
                                        : Colors.orange,
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

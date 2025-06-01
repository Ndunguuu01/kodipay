import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/tenant_model.dart';
import '../models/bill_model.dart';
import 'landlord_ledger_screen.dart';
import '../providers/property_provider.dart';
import '../providers/auth_provider.dart';
import '../models/property.dart';
import '../models/floor_model.dart';
import '../models/room_model.dart';

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
  final List<String> billTypes = ['rent', 'water', 'electricity', 'maintenance', 'other'];

  PropertyModel? _selectedProperty;
  FloorModel? _selectedFloor;
  RoomModel? _selectedRoom;

  late Future<List<BillModel>> _allBillsFuture;

  @override
  void initState() {
    super.initState();
    Provider.of<PropertyProvider>(context, listen: false).fetchProperties(context);
    _allBillsFuture = Provider.of<BillProvider>(context, listen: false).fetchAllBills(context);
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final billProvider = Provider.of<BillProvider>(context);
    Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Ledger',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LandlordLedgerScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<BillModel>>(
              future: _allBillsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bills = snapshot.data ?? [];
                final total = bills.fold<double>(0, (sum, b) => sum + b.amount);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Bills: KES ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('All Tenant Bills:', style: TextStyle(fontWeight: FontWeight.bold)),
                    bills.isEmpty
                      ? const Text('No bills found.')
                      : SizedBox(
                          height: 120,
                          child: ListView.builder(
                            itemCount: bills.length,
                            itemBuilder: (context, index) {
                              final bill = bills[index];
                              return ListTile(
                                title: Text('${bill.type} - KES ${bill.amount}'),
                                subtitle: Text('Tenant: ${bill.tenantId} | Due: ${bill.dueDate.toLocal().toString().split(' ')[0]}'),
                                trailing: Text(
                                  bill.statusDisplay,
                                  style: TextStyle(
                                    color: bill.status == BillStatus.paid ? Colors.green : Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Property Bill (All Tenants)'),
              onPressed: () {
                _showCreatePropertyBillDialog();
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PropertyModel>(
              value: _selectedProperty,
              decoration: const InputDecoration(labelText: 'Select Property *'),
              items: propertyProvider.properties.map((property) {
                return DropdownMenuItem(
                  value: property,
                  child: Text(property.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProperty = value;
                  _selectedFloor = null;
                  _selectedRoom = null;
                });
              },
            ),
            if (_selectedProperty != null)
              DropdownButtonFormField<FloorModel>(
                value: _selectedFloor,
                decoration: const InputDecoration(labelText: 'Select Floor *'),
                items: _selectedProperty!.floors.map((floor) {
                  return DropdownMenuItem(
                    value: floor,
                    child: Text('Floor ${floor.floorNumber}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFloor = value;
                    _selectedRoom = null;
                  });
                },
              ),
            if (_selectedFloor != null)
              DropdownButtonFormField<RoomModel>(
                value: _selectedRoom,
                decoration: const InputDecoration(labelText: 'Select Room *'),
                items: _selectedFloor!.rooms.where((room) => room.isOccupied).map((room) {
                  return DropdownMenuItem(
                    value: room,
                    child: Text(room.roomNumber),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoom = value;
                  });
                },
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedBillType,
              decoration: const InputDecoration(labelText: 'Select Bill Type'),
              items: billTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (type) => setState(() => selectedBillType = type),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    dueDate == null ? 'Select Due Date' : 'Due: ${dueDate!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
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
            ElevatedButton(
              onPressed: (_selectedProperty != null &&
                      _selectedFloor != null &&
                      _selectedRoom != null &&
                      selectedBillType != null &&
                      _amountController.text.isNotEmpty &&
                      dueDate != null)
                  ? () async {
                      await _createBill();
                    }
                  : null,
              child: const Text('Assign Bill'),
            ),
            const SizedBox(height: 24),
            if (_selectedRoom != null)
              Expanded(
                child: FutureBuilder<List<BillModel>>(
                  future: billProvider.fetchTenantBills(_selectedRoom!.tenantId ?? '', context),
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
                            bill.statusDisplay,
                            style: TextStyle(
                              color: bill.status == BillStatus.paid ? Colors.green : Colors.red,
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

  void _showCreatePropertyBillDialog() {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    String? selectedPropertyId;
    String? selectedType;
    final amountController = TextEditingController();
    DateTime? selectedDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 5);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Property Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Property'),
                  value: selectedPropertyId,
                  items: propertyProvider.properties.map((property) {
                    return DropdownMenuItem(
                      value: property.id,
                      child: Text(property.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPropertyId = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Bill Type'),
                  value: selectedType,
                  items: billTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedType = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'KES ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(selectedDate == null
                      ? 'Select Due Date'
                      : 'Due Date: ${selectedDate.toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedPropertyId == null ||
                    selectedType == null ||
                    amountController.text.isEmpty ||
                    selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await Provider.of<BillProvider>(context, listen: false).createPropertyBills(
                    propertyId: selectedPropertyId!,
                    type: BillType.values.firstWhere((e) => e.name == selectedType!),
                    amount: double.parse(amountController.text),
                    dueDate: selectedDate!,
                    context: context,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _allBillsFuture = Provider.of<BillProvider>(context, listen: false).fetchAllBills(context);
                    });
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create Bills'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBill() async {
    if (_selectedProperty == null || _selectedRoom == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final bill = BillModel(
        id: '',
        tenantId: _selectedRoom!.tenantId!,
        propertyId: _selectedProperty!.id,
        roomId: _selectedRoom!.id,
        amount: double.parse(_amountController.text),
        status: BillStatus.pending,
        paymentMethod: 'manual',
        createdAt: DateTime.now(),
        dueDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
        description: selectedBillType,
      );

      await Provider.of<BillProvider>(context, listen: false).addBill(bill, context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill created successfully')),
      );
      setState(() {
        _allBillsFuture = Provider.of<BillProvider>(context, listen: false).fetchAllBills(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating bill: $e')),
      );
    }
  }
}

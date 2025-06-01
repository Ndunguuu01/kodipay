import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kodipay/models/bill_model.dart';
import 'package:kodipay/models/property.dart';
import 'package:kodipay/models/floor_model.dart';
import 'package:kodipay/models/room_model.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:provider/provider.dart';

class AssignBillsScreen extends StatefulWidget {
  final String propertyId;

  const AssignBillsScreen({super.key, required this.propertyId});

  @override
  State<AssignBillsScreen> createState() => _AssignBillsScreenState();
}

class _AssignBillsScreenState extends State<AssignBillsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  BillType? _selectedBillType;
  PropertyModel? _selectedProperty;
  FloorModel? _selectedFloor;
  RoomModel? _selectedRoom;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dueDate = DateTime(now.year, now.month + 1, 5);

    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    propertyProvider.fetchProperties(context).then((_) {
      final property = propertyProvider.properties.firstWhere(
        (p) => p.id == widget.propertyId,
        orElse: () => propertyProvider.properties.first,
      );
      if (mounted) {
        setState(() {
          _selectedProperty = property;
        });
      }
    });
  }

  bool _validateCommonFields() {
    return _selectedBillType != null &&
        _selectedProperty != null &&
        _dueDate != null &&
        _amountController.text.isNotEmpty;
  }

  Future<void> _assignBill() async {
    if (_selectedRoom == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final bill = BillModel(
        id: '', // Will be set by the server
        tenantId: _selectedRoom!.tenantId!,
        propertyId: widget.propertyId,
        roomId: _selectedRoom!.id,
        amount: double.parse(_amountController.text),
        status: BillStatus.pending,
        paymentMethod: 'manual',
        createdAt: DateTime.now(),
        dueDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
        description: _selectedBillType!.toString().split('.').last,
      );

      await Provider.of<BillProvider>(context, listen: false).addBill(bill, context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill assigned successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning bill: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final properties = propertyProvider.properties;

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Bills')),
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    DropdownButtonFormField<PropertyModel>(
                      value: _selectedProperty,
                      decoration: const InputDecoration(labelText: 'Select Property *'),
                      items: properties.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.name));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProperty = value;
                          _selectedFloor = null;
                          _selectedRoom = null;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a property' : null,
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
                        validator: (value) => value == null ? 'Please select a floor' : null,
                      ),
                    if (_selectedFloor != null)
                      DropdownButtonFormField<RoomModel>(
                        value: _selectedRoom,
                        decoration: const InputDecoration(labelText: 'Select Room *'),
                        items: _selectedFloor!.rooms.where((room) => room.isOccupied).map((room) {
                          return DropdownMenuItem(value: room, child: Text(room.roomNumber));
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedRoom = value),
                        validator: (value) => value == null ? 'Please select a room' : null,
                      ),
                    DropdownButtonFormField<BillType>(
                      value: _selectedBillType,
                      decoration: const InputDecoration(labelText: 'Bill Type *'),
                      items: BillType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedBillType = value),
                      validator: (value) => value == null ? 'Please select a bill type' : null,
                    ),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (KES) *',
                        prefixText: 'KES ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an amount';
                        if (double.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    ListTile(
                      title: Text(
                        _dueDate == null
                            ? 'Select Due Date *'
                            : 'Due Date: ${DateFormat('dd MMM yyyy').format(_dueDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<BillProvider>(
                      builder: (context, billProvider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              icon: billProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.group),
                              label: const Text('Create Property Bill (All Tenants)'),
                              onPressed: billProvider.isLoading
                                  ? null
                                  : () async {
                                      if (!_validateCommonFields()) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please fill in all required fields for property bill'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      try {
                                        await billProvider.createPropertyBills(
                                          propertyId: _selectedProperty!.id,
                                          type: _selectedBillType!,
                                          amount: double.parse(_amountController.text),
                                          dueDate: _dueDate!,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Property bills created successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error creating property bills: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: billProvider.isLoading ? null : _assignBill,
                              child: billProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Assign Bill'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

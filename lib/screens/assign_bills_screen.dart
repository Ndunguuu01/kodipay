import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:kodipay/models/bill_model.dart';
import 'package:kodipay/models/property_model.dart';
import 'package:kodipay/models/floor_model.dart';
import 'package:kodipay/models/room_model.dart';
import 'package:intl/intl.dart';

class AssignBillsScreen extends StatefulWidget {
  const AssignBillsScreen({super.key});

  @override
  State<AssignBillsScreen> createState() => _AssignBillsScreenState();
}

class _AssignBillsScreenState extends State<AssignBillsScreen> {
  late Future<void> _propertiesFuture;
  PropertyModel? _selectedProperty;
  FloorModel? _selectedFloor;
  RoomModel? _selectedRoom;
  String? _selectedBillType;
  final _amountController = TextEditingController();
  DateTime? _dueDate;
  final List<String> _billTypes = ['rent', 'water', 'electricity', 'maintenance', 'other'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = _loadProperties();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    if (!mounted) return;
    await context.read<PropertyProvider>().fetchProperties(context);
  }

  Future<void> _createBill() async {
    if (_selectedProperty == null || _selectedRoom == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
        dueDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
        description: _selectedBillType,
      );

      await context.read<BillProvider>().addBill(bill, context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating bill: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedProperty = null;
      _selectedFloor = null;
      _selectedRoom = null;
      _selectedBillType = null;
      _amountController.clear();
      _dueDate = null;
    });
  }

  Future<void> _showCreatePropertyBillDialog() async {
    String? selectedType;
    final amountController = TextEditingController();
    DateTime? selectedDate;
    final propertyProvider = context.read<PropertyProvider>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Property Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Bill Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _billTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedType = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: 'KES ',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? 'Select Due Date'
                        : DateFormat('MMM dd, yyyy').format(selectedDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
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
                if (selectedType == null ||
                    amountController.text.isEmpty ||
                    selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await context.read<BillProvider>().createPropertyBills(
                    propertyId: _selectedProperty!.id,
                    type: BillType.values.firstWhere((e) => e.name == selectedType!),
                    amount: double.parse(amountController.text),
                    dueDate: selectedDate!,
                    context: context,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bills created successfully')),
                    );
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

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();
    final properties = propertyProvider.properties;

    return Scaffold(
      body: FutureBuilder(
        future: _propertiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading properties: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _propertiesFuture = _loadProperties();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (properties.isEmpty) {
            return const Center(child: Text('No properties available'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF90CAF9),
                          Colors.blue.shade700,
                        ],
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
                            onPressed: () => context.go('/landlord-home'),
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
                                'Assign Bills',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Manage tenant bills and payments',
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
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property Selection
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Property',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<PropertyModel>(
                                value: _selectedProperty,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: properties.map((property) {
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Floor and Room Selection
                      if (_selectedProperty != null) ...[
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Floor & Room',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<FloorModel>(
                                  value: _selectedFloor,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
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
                                if (_selectedFloor != null) ...[
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<RoomModel>(
                                    value: _selectedRoom,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: _selectedFloor!.rooms
                                        .where((room) => room.isOccupied)
                                        .map((room) {
                                      return DropdownMenuItem(
                                        value: room,
                                        child: Text('Room ${room.roomNumber}'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedRoom = value);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Bill Details
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bill Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedBillType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: _billTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedBillType = value);
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixText: 'KES ',
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                title: Text(
                                  _dueDate == null
                                      ? 'Select Due Date'
                                      : DateFormat('MMM dd, yyyy').format(_dueDate!),
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() => _dueDate = date);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Create Property Bill (All Tenants)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF90CAF9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _selectedProperty == null
                                  ? null
                                  : () => _showCreatePropertyBillDialog(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedProperty != null &&
                                  _selectedFloor != null &&
                                  _selectedRoom != null &&
                                  _selectedBillType != null &&
                                  _amountController.text.isNotEmpty &&
                                  _dueDate != null)
                              ? _isLoading
                                  ? null
                                  : _createBill
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF90CAF9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Assign Bill'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/bill_provider.dart';
import '../models/tenant_model.dart';
import '../models/bill_model.dart';
import '../providers/property_provider.dart';
import '../providers/auth_provider.dart';
import '../models/property_model.dart';
import '../models/floor_model.dart';
import '../models/room_model.dart';

class LandlordBillsScreen extends StatefulWidget {
  final String? propertyId;
  
  const LandlordBillsScreen({
    super.key,
    this.propertyId,
  });

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
    
    // If propertyId is provided, set it as the selected property
    if (widget.propertyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
        final matchingProperty = propertyProvider.properties.firstWhere(
          (p) => p.id == widget.propertyId,
          orElse: () => propertyProvider.properties.first,
        );
        setState(() {
          _selectedProperty = matchingProperty;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final billProvider = Provider.of<BillProvider>(context);
    Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
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
                      onPressed: () => context.go('/landlord-home'),
                    ),
                  ),
                  // Ledger Button
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                      onPressed: () => context.push('/landlord-home/ledger'),
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
            // Bills Overview
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<BillModel>>(
                future: _allBillsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bills = snapshot.data ?? [];
                  final total = bills.fold<double>(0, (sum, b) => sum + b.amount);
                  final paidBills = bills.where((b) => b.status == BillStatus.paid).length;
                  final pendingBills = bills.where((b) => b.status == BillStatus.pending).length;

                  return Column(
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
                              'Total Bills',
                              'KES ${total.toStringAsFixed(2)}',
                              Icons.receipt,
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
                  );
                },
              ),
            ),
            // Create Property Bill Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                onPressed: () => _showCreatePropertyBillDialog(),
              ),
            ),
            // Bill Assignment Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Bill to Tenant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      value: _selectedProperty,
                      label: 'Select Property',
                      items: propertyProvider.properties,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedProperty = value;
                            _selectedFloor = null;
                            _selectedRoom = null;
                          });
                        }
                      },
                      itemBuilder: (property) => Text(property.name),
                    ),
                    if (_selectedProperty != null) ...[
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        value: _selectedFloor,
                        label: 'Select Floor',
                        items: _selectedProperty!.floors,
                        onChanged: (value) {
                          setState(() {
                            _selectedFloor = value;
                            _selectedRoom = null;
                          });
                        },
                        itemBuilder: (floor) => Text('Floor ${floor.floorNumber}'),
                      ),
                    ],
                    if (_selectedFloor != null) ...[
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        value: _selectedRoom,
                        label: 'Select Room',
                        items: _selectedFloor!.rooms.where((room) => room.isOccupied).toList(),
                        onChanged: (value) {
                          setState(() => _selectedRoom = value);
                        },
                        itemBuilder: (room) => Text(room.roomNumber),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      value: selectedBillType,
                      label: 'Bill Type',
                      items: billTypes,
                      onChanged: (value) => setState(() => selectedBillType = value),
                      itemBuilder: (type) => Text(type),
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
                    _buildDatePickerField(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF90CAF9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Assign Bill'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tenant Bills List
            if (_selectedRoom != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tenant Bills',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<BillModel>>(
                      future: billProvider.fetchTenantBills(_selectedRoom!.tenantId ?? '', context),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final bills = snapshot.data ?? [];
                        return bills.isEmpty
                            ? const Center(child: Text('No bills found for this tenant.'))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bills.length,
                                itemBuilder: (context, index) {
                                  final bill = bills[index];
                                  return _buildBillCard(bill);
                                },
                              );
                      },
                    ),
                  ],
                ),
              ),
          ],
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

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required List<T> items,
    required Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePickerField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dueDate == null ? 'Select Due Date' : 'Due: ${dueDate!.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                color: dueDate == null ? Colors.grey : Colors.black,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dueDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => dueDate = picked);
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Pick Date'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF90CAF9),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bill.status == BillStatus.paid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            bill.status == BillStatus.paid ? Icons.check_circle : Icons.pending,
            color: bill.status == BillStatus.paid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          '${bill.type} - KES ${bill.amount}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Due: ${bill.dueDate.toLocal().toString().split(' ')[0]}',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bill.status == BillStatus.paid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            bill.statusDisplay,
            style: TextStyle(
              color: bill.status == BillStatus.paid ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
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

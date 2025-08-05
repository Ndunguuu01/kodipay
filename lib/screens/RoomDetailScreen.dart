import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/models/room_model.dart'; 
import 'package:kodipay/models/tenant_model.dart';
import 'package:kodipay/models/property_model.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/models/bill_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/providers/tenant_provider.dart';
import 'package:intl/intl.dart';

class RoomDetailScreen extends StatefulWidget {
  final RoomModel room;
  final TenantModel? tenant;
  final String propertyId;

  const RoomDetailScreen({
    required this.room,
    required this.propertyId,
    this.tenant,
    super.key,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<List<BillModel>> _billsFuture;
  late PropertyModel _property;
  TenantModel? _tenant;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedBillType;
  final List<String> _billTypes = ['rent', 'water', 'electricity', 'internet', 'maintenance', 'other'];
  bool _isCreatingBill = false;

  @override
  void initState() {
    super.initState();
    _billsFuture = Provider.of<BillProvider>(context, listen: false)
        .fetchTenantBills(widget.room.tenantId ?? '', context);
    
    // Get property information
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    _property = propertyProvider.properties.firstWhere(
      (p) => p.id == widget.propertyId,
      orElse: () => PropertyModel(
        id: '',
        name: '',
        address: '',
        rentAmount: 0,
        totalRooms: 0,
        floors: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    // Always fetch the latest tenant info by ID
    if (widget.room.isOccupied && widget.room.tenantId != null) {
      final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
      _tenant = tenantProvider.tenants.firstWhere(
        (t) => t.id == widget.room.tenantId,
        orElse: () => TenantModel(
          id: '',
          phoneNumber: '',
          firstName: 'Unknown',
          lastName: 'Tenant',
          status: 'Unknown',
          paymentStatus: 'Unknown',
        ),
      );
    } else {
      _tenant = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    await propertyProvider.fetchProperties(context);
    setState(() {
      _billsFuture = Provider.of<BillProvider>(context, listen: false)
          .fetchTenantBills(widget.room.tenantId ?? '', context);
    });
  }

  Future<void> _generateAndShareReceipt(BillModel bill) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Payment Receipt'),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Receipt Number: ${bill.id}'),
            pw.Text('Date: ${bill.createdAt.toString().split(' ')[0]}'),
            pw.Text('Tenant: ${widget.tenant?.fullName}'),
            pw.Text('Room: ${widget.room.roomNumber}'),
            pw.Text('Amount: KES ${bill.amount}'),
            pw.Text('Payment Status: ${bill.status}'),
            pw.Text('Payment Method: ${bill.paymentMethod}'),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${bill.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Payment Receipt for ${widget.tenant?.fullName}',
    );
  }

  Future<void> _showCreateBillDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedBillType,
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
                  onChanged: (value) => setState(() => _selectedBillType = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
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
                    _dueDate == null
                        ? 'Select Due Date'
                        : DateFormat('MMM dd, yyyy').format(_dueDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isCreatingBill || _selectedBillType == null || _amountController.text.isEmpty || _dueDate == null
                  ? null
                  : () => _createBill(),
              child: _isCreatingBill
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBill() async {
    if (_tenant == null || _selectedBillType == null || _amountController.text.isEmpty || _dueDate == null) {
      return;
    }

    setState(() => _isCreatingBill = true);

    try {
      final bill = BillModel(
        id: '',
        tenantId: _tenant!.id,
        propertyId: widget.propertyId,
        roomId: widget.room.id,
        amount: double.parse(_amountController.text),
        status: BillStatus.pending,
        paymentMethod: 'manual',
        createdAt: DateTime.now(),
        dueDate: _dueDate!,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : _selectedBillType,
      );

      await context.read<BillProvider>().addBill(bill, context);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully')),
        );
        _resetBillForm();
        _refreshData(); // Refresh bills list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating bill: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingBill = false);
      }
    }
  }

  void _resetBillForm() {
    setState(() {
      _amountController.clear();
      _descriptionController.clear();
      _selectedBillType = null;
      _dueDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${widget.room.roomNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          if (widget.tenant != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                context.go(
                  '/tenant-details',
                  extra: {
                    'tenantId': widget.tenant!.id,
                    'propertyId': widget.propertyId,
                  },
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Room Number: ${widget.room.roomNumber}'),
                      Text('Status: ${widget.room.isOccupied ? 'Occupied' : 'Vacant'}'),
                      Text('Rent Amount: KES ${_property.rentAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              if (_tenant != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tenant Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Name: ${_tenant!.fullName}'),
                        Text('Phone: ${_tenant!.phoneNumber}'),
                        if (_tenant!.nationalId != null && _tenant!.nationalId!.isNotEmpty)
                          Text('National ID: ${_tenant!.nationalId}'),
                        if (_tenant!.status != null)
                          Text('Status: ${_tenant!.status}'),
                        if (_tenant!.paymentStatus != null)
                          Text('Payment Status: ${_tenant!.paymentStatus}'),
                        if (_tenant!.property != null)
                          Text('Property: ${_tenant!.property?.name ?? 'Unknown'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showCreateBillDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF90CAF9),
                      ),
                    ),
                  ],
                ),
                FutureBuilder<List<BillModel>>(
                  future: _billsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No bills found'),
                            SizedBox(height: 8),
                            Text('Click "Add Bill" to create one'),
                          ],
                        ),
                      );
                    }

                    final bills = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            title: Text('${bill.description ?? 'Bill'} - KES ${bill.amount.toStringAsFixed(2)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Due: ${bill.formattedDueDate}'),
                                Text('Status: ${bill.statusDisplay}'),
                              ],
                            ),
                            trailing: bill.status == BillStatus.paid
                                ? IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () => _generateAndShareReceipt(bill),
                                    tooltip: 'Download Receipt',
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              if (!widget.room.isOccupied)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
                      final property = propertyProvider.properties.firstWhere(
                        (p) => p.id == widget.propertyId,
                        orElse: () => PropertyModel(
                          id: '',
                          name: '',
                          address: '',
                          rentAmount: 0,
                          totalRooms: 0,
                          floors: [],
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );

                      final result = await context.push(
                        '/landlord-home/tenants/add?propertyId=${widget.propertyId}&roomId=${widget.room.id}&floorNumber=${int.parse(widget.room.roomNumber.split('-')[0])}&roomNumber=${widget.room.roomNumber}',
                        extra: {'property': property},
                      );
                      if (result == true && mounted) {
                        _refreshData();
                      }
                    },
                    child: const Text('Assign Tenant'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

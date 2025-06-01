import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/models/room_model.dart'; 
import 'package:kodipay/models/tenant_model.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:kodipay/models/bill_model.dart';
import 'package:kodipay/screens/add_tenant_screen.dart';
import 'package:kodipay/screens/tenant_details_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _billsFuture = Provider.of<BillProvider>(context, listen: false)
        .fetchTenantBills(widget.room.tenantId ?? '', context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${widget.room.roomNumber}'),
        actions: [
          if (widget.tenant != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TenantDetailsScreen(
                      tenantId: widget.tenant!.id,
                      propertyId: widget.propertyId,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                  ],
                ),
              ),
            ),
            if (widget.tenant != null) ...[
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
                      Text('Name: ${widget.tenant!.fullName}'),
                      Text('Phone: ${widget.tenant!.phoneNumber}'),
                      // Text('Email: ${widget.tenant!.email}'), // TenantModel has no email property
                      Text('Status: ${widget.tenant!.status}'),
                      Text('Payment Status: ${widget.tenant!.paymentStatus}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: FutureBuilder<List<BillModel>>(
                  future: _billsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No bills found'));
                    }

                    final bills = snapshot.data!;
                    return ListView.builder(
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            title: Text('${bill.description} - KES ${bill.amount.toStringAsFixed(2)}'),
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
              ),
            ],
            if (!widget.room.isOccupied)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTenantScreen(
                          propertyId: widget.propertyId,
                          roomId: widget.room.id,
                          floorNumber: int.parse(widget.room.roomNumber.split('-')[0]),
                          roomNumber: widget.room.roomNumber,
                          excludeTenantIds: widget.tenant != null ? [widget.tenant!.id] : [],
                        ),
                      ),
                    );
                  },
                  child: const Text('Assign Tenant'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

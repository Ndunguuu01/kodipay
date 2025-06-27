import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/models/tenant_model.dart';
import 'package:kodipay/models/bill_model.dart';
import 'package:kodipay/models/lease_model.dart';
import 'package:kodipay/providers/tenant_provider.dart';
import 'package:kodipay/providers/bill_provider.dart';

class TenantDetailsScreen extends StatefulWidget {
  final String tenantId;
  final String propertyId;

  const TenantDetailsScreen({
    required this.tenantId,
    required this.propertyId,
    super.key,
  });

  @override
  State<TenantDetailsScreen> createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends State<TenantDetailsScreen> {
  late Future<TenantModel> _tenantFuture;
  late Future<List<BillModel>> _billsFuture;
  late Future<List<LeaseModel>> _leasesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tenantProv = Provider.of<TenantProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);

    setState(() {
      _tenantFuture = Future.value(tenantProv.tenants.firstWhere(
        (t) => t.id == widget.tenantId,
        orElse: () => TenantModel(
          id: '',
          phoneNumber: '',
          firstName: 'Unknown',
          lastName: '',
          status: '',
          paymentStatus: '',
          property: null,
        ),
      ));
      _billsFuture = billProvider.fetchTenantBills(widget.tenantId, context);
      
      // Create lease information based on assignment date
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = DateTime(now.year, now.month + 1, now.day);
      final dueDate = DateTime(now.year, now.month, 5);
      
      _leasesFuture = Future.value([
        LeaseModel(
          id: '',
          tenantId: widget.tenantId,
          propertyId: widget.propertyId,
          roomId: '',
          leaseType: 'Monthly',
          amount: 0, // Will be set from property
          balance: 0,
          payableAmount: 0,
          startDate: startDate.toIso8601String(),
          dueDate: dueDate.toIso8601String(),
          status: 'Active',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FutureBuilder<TenantModel>(
        future: _tenantFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No tenant data found'),
            );
          }

          final tenant = snapshot.data!;

          return SingleChildScrollView(
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
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Name', '${tenant.firstName} ${tenant.lastName}'),
                        _buildInfoRow('Phone', tenant.phoneNumber),
                        _buildInfoRow('Status', tenant.status ?? 'Active'),
                        _buildInfoRow('Payment Status', tenant.paymentStatus ?? 'Pending'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lease Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<LeaseModel>>(
                          future: _leasesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text('No lease information available'),
                              );
                            }

                            final lease = snapshot.data!.first;
                            return Column(
                              children: [
                                _buildInfoRow('Start Date', DateTime.parse(lease.startDate).toString().split(' ')[0]),
                                _buildInfoRow('End Date', DateTime.parse(lease.dueDate).toString().split(' ')[0]),
                                _buildInfoRow('Rent Due Date', '5th of every month'),
                                _buildInfoRow('Rent Amount', 'KES ${lease.amount}'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bills',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<BillModel>>(
                          future: _billsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text('No bills found'),
                              );
                            }

                            final bills = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: bills.length,
                              itemBuilder: (context, index) {
                                final bill = bills[index];
                                return ListTile(
                                  title: Text(bill.description ?? 'No description'),
                                  subtitle: Text(bill.dueDate.toString()),
                                  trailing: Text(
                                    'KES ${bill.amount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
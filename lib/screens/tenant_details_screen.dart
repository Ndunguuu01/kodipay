import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/models/tenant_model.dart';
import 'package:kodipay/providers/tenant_provider.dart' as tenantProvider;
import 'package:kodipay/providers/lease_provider.dart';
import 'package:kodipay/providers/auth_provider.dart';

class TenantDetailsScreen extends StatefulWidget {
  final String tenantId;
  final String propertyId;

  const TenantDetailsScreen({
    super.key,
    required this.tenantId,
    required this.propertyId,
  });

  @override
  State<TenantDetailsScreen> createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends State<TenantDetailsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return; // Ensure widget is still mounted
    final tenantProv = Provider.of<tenantProvider.TenantProvider>(context, listen: false);
    final leaseProvider = Provider.of<LeaseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.auth?.token;
    if (token != null && !tenantProv.isLoading && tenantProv.tenants.isEmpty) {
      tenantProv.fetchTenants(token);
    }
    if (token != null && !leaseProvider.isLoading && leaseProvider.leases.isEmpty) {
      leaseProvider.fetchLeases(widget.tenantId, token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantProv = Provider.of<tenantProvider.TenantProvider>(context);
    final leaseProvider = Provider.of<LeaseProvider>(context);
    final tenant = tenantProv.tenants.firstWhere(
      (t) => t.id == widget.tenantId,
      orElse: () => TenantModel(
        id: '',
        phoneNumber: '',
        name: '',
        email: '',
        status: '',
        paymentStatus: '',
        propertyId: '',
      ),
    );
    final leases = leaseProvider.leases;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Details - ${tenant.fullName}'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${tenant.fullName}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Phone: ${tenant.phoneNumber}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Status: ${tenant.status}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            const Text('Leases:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: leaseProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : leases.isEmpty && leaseProvider.error != null
                      ? Center(child: Text(leaseProvider.error!))
                      : leases.isEmpty
                          ? const Center(child: Text('No leases available'))
                          : ListView.builder(
                              itemCount: leases.length,
                              itemBuilder: (context, index) {
                                final lease = leases[index];
                                return ListTile(
                                  title: Text('Lease #${lease.id} - ${lease.leaseType}'),
                                  subtitle: Text(
                                    'Start: ${lease.startDate} | Due: ${lease.dueDate} | Amount: KES ${lease.amount}',
                                  ),
                                  trailing: Text(
                                    'Balance: KES ${lease.balance} | Payable: KES ${lease.payableAmount}',
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
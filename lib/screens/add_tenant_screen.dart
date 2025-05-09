import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/tenant_provider.dart';

class AddTenantScreen extends StatefulWidget {
  final String propertyId;
  final String roomId;
  final List<String> excludeTenantIds;

  const AddTenantScreen({
    super.key,
    required this.propertyId,
    required this.roomId,
    required this.excludeTenantIds,
  });

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('RoomId: ${widget.roomId}'); // Debug log
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    tenantProvider.fetchTenants();
  }

  void _submitTenant() async {
    if (_formKey.currentState!.validate()) {
      final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token is missing')),
        );
        return;
      }

      // Check for duplicate phone number using any()
    final phoneNumber = _phoneController.text.trim();
    final hasDuplicate = tenantProvider.tenants.any((t) => t.phoneNumber == phoneNumber);
    if (hasDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant with this phone number already exists')),
      );
      return;
    }

      print('Token: $token'); // Debug log
      final success = await tenantProvider.createAndAssignTenant(
        roomId: widget.roomId,
        propertyId: widget.propertyId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        nationalId: _idController.text.trim(),
        token: token,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant created and assigned successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tenantProvider.error ?? 'Failed to create and assign tenant')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = Provider.of<TenantProvider>(context);
    final isLoading = tenantProvider.isLoading;

    // Filter tenants to exclude already assigned ones
    final availableTenants = tenantProvider.tenants
        .where((tenant) => !widget.excludeTenantIds.contains(tenant.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Tenant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : availableTenants.isEmpty
                      ? const Center(child: Text('No available tenants to assign'))
                      : ListView.builder(
                          itemCount: availableTenants.length,
                          itemBuilder: (context, index) {
                            final tenant = availableTenants[index];
                            return ListTile(
                              title: Text(
                                  tenant.fullName.isNotEmpty ? tenant.fullName : 'Unknown'),
                              subtitle: Text(tenant.phoneNumber),
                              onTap: () async {
                                final tenantProvider =
                                    Provider.of<TenantProvider>(context, listen: false);
                                final authProvider =
                                    Provider.of<AuthProvider>(context, listen: false);
                                final token = authProvider.auth?.token;

                                if (token == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Authentication token is missing')),
                                  );
                                  return;
                                }

                                print('Token: $token'); // Debug log
                                final success = await tenantProvider.assignExistingTenant(
                                  roomId: widget.roomId,
                                  tenantId: tenant.id,
                                  token: token,
                                );

                                if (!mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Tenant assigned successfully')),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(tenantProvider.error ??
                                            'Failed to assign tenant')),
                                  );
                                }
                              },
                            );
                          },
                        ),
            ),
            const Divider(),
            const Text('Or create a new tenant:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (!RegExp(r'^\+?\d{10,12}$').hasMatch(value)) {
                        return 'Enter a valid phone number (e.g., +254729836029)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email (Optional)'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(labelText: 'National ID (Optional)'),
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitTenant,
                          child: const Text('Create and Assign Tenant'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idController.dispose();
    super.dispose();
  }
}
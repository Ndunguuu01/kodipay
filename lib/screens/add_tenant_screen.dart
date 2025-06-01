import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/tenant_provider.dart';
import 'package:kodipay/screens/create_tenant_button.dart';

class AddTenantScreen extends StatefulWidget {
  final String propertyId;
  final String roomId;
  final int floorNumber;
  final String roomNumber;
  final List<String> excludeTenantIds;

  const AddTenantScreen({
    super.key,
    required this.propertyId,
    required this.roomId,
    required this.floorNumber,
    required this.roomNumber,
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
      print('initState: Fetching unassigned tenants for propertyId: ${widget.propertyId}, roomId: ${widget.roomId}');
      tenantProvider.fetchUnassignedTenants();
      // Initialize phone number with +254
      _phoneController.text = '+254';
      _phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: _phoneController.text.length),
      );
    });
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

      setState(() => _isLoading = true);

      try {
        final name = _nameController.text.trim();
        String phone = _phoneController.text.trim();
        final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
        final nationalId = _idController.text.trim().isEmpty ? null : _idController.text.trim();

        // Normalize phone number: remove spaces, dashes, parentheses
        phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        // Ensure phone number starts with +254
        if (!phone.startsWith('+254')) {
          if (phone.startsWith('0')) {
            phone = '+254${phone.substring(1)}';
          } else if (phone.startsWith('7') && phone.length == 9) {
            phone = '+254$phone';
          }
        }

        print('Normalized phone number: $phone');

        print('Creating and assigning tenant: name=$name, phone=$phone, email=$email, nationalId=$nationalId, '
            'propertyId=${widget.propertyId}, roomId=${widget.roomId}, floorNumber=${widget.floorNumber}, roomNumber=${widget.roomNumber}');

        final success = await tenantProvider.createAndAssignTenant(
          propertyId: widget.propertyId,
          name: name,
          phone: phone,
          email: email,
          nationalId: nationalId,
          token: token,
          roomId: widget.roomId,
          floorNumber: widget.floorNumber,
          roomNumber: widget.roomNumber,
        );

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tenant created and assigned successfully')),
          );
          Navigator.pop(context, {
            'tenant': {
              '_id': tenantProvider.lastCreatedTenantId,
              'fullName': name,
              'phoneNumber': phone,
              'email': email,
            }
          });
        } else {
          String errorMessage = tenantProvider.error ?? 'Failed to create and assign tenant';
          if (errorMessage.toLowerCase().contains('duplicate key')) {
            if (errorMessage.toLowerCase().contains('phone')) {
              errorMessage = 'Phone number already exists. Please use a different phone number.';
            } else if (errorMessage.toLowerCase().contains('email')) {
              errorMessage = 'Email address already exists. Please use a different email or leave it blank.';
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        print('Error creating tenant: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = Provider.of<TenantProvider>(context);
    final isLoading = tenantProvider.isLoading || _isLoading;

    final availableTenants = tenantProvider.tenants
        .where((tenant) => !widget.excludeTenantIds.contains(tenant.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tenant'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigning tenant to:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Floor: ${widget.floorNumber}'),
                Text('Room: ${widget.roomNumber}'),
                const SizedBox(height: 16),
                Expanded(
                  child: tenantProvider.error != null
                      ? Center(child: Text('Error: ${tenantProvider.error}'))
                      : Column(
                          children: [
                            Expanded(
                              child: availableTenants.isEmpty
                                  ? const Center(child: Text('No available tenants to assign'))
                                  : ListView.builder(
                                      itemCount: availableTenants.length,
                                      itemBuilder: (context, index) {
                                        final tenant = availableTenants[index];
                                        return ListTile(
                                          title: Text(
                                            tenant.fullName.isNotEmpty
                                                ? tenant.fullName
                                                : 'Unknown (${tenant.phoneNumber.isNotEmpty ? tenant.phoneNumber : "No Phone"})',
                                          ),
                                          subtitle: Text(
                                            tenant.phoneNumber.isNotEmpty ? tenant.phoneNumber : 'No Phone Number',
                                          ),
                                          onTap: _isLoading
                                              ? null
                                              : () async {
                                                  setState(() => _isLoading = true);
                                                  final token = Provider.of<AuthProvider>(context, listen: false).auth?.token;

                                                  if (token == null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Authentication token is missing')),
                                                    );
                                                    setState(() => _isLoading = false);
                                                    return;
                                                  }

                                                  print('Assigning existing tenant: tenantId=${tenant.id}, '
                                                      'propertyId=${widget.propertyId}, roomId=${widget.roomId}, '
                                                      'floorNumber=${widget.floorNumber}, roomNumber=${widget.roomNumber}');

                                                  final success = await tenantProvider.assignExistingTenant(
                                                    roomId: widget.roomId,
                                                    tenantId: tenant.id,
                                                    token: token,
                                                    floorNumber: widget.floorNumber,
                                                    roomNumber: widget.roomNumber,
                                                    propertyId: widget.propertyId,
                                                  );

                                                  if (!mounted) return;

                                                  if (success) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Tenant assigned successfully')),
                                                    );
                                                    Navigator.pop(context, {
                                                      'tenant': {
                                                        '_id': tenant.id,
                                                        'fullName': tenant.fullName,
                                                        'phoneNumber': tenant.phoneNumber,
                                                      }
                                                    });
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(tenantProvider.error ?? 'Failed to assign tenant')),
                                                    );
                                                  }

                                                  setState(() => _isLoading = false);
                                                },
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Or create a new tenant:'),
                            const SizedBox(height: 16),
                            CreateTenantButton(
                              propertyId: widget.propertyId,
                              roomId: widget.roomId,
                              floorNumber: widget.floorNumber,
                              roomNumber: widget.roomNumber,
                              excludeTenantIds: widget.excludeTenantIds,
                            ),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value?.isEmpty ?? true ? 'Please enter a name' : null,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      border: OutlineInputBorder(),
                                      prefixText: '+254 ',
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a phone number';
                                      }
                                      // Validate only the digits after +254
                                      final phoneDigits = value.startsWith('+254') ? value.substring(4) : value;
                                      if (!RegExp(r'^\d{9}$').hasMatch(phoneDigits)) {
                                        return 'Please enter a valid phone number with 9 digits after +254';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email (Optional)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _idController,
                                    decoration: const InputDecoration(
                                      labelText: 'National ID (Optional)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF90CAF9),
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    onPressed: _isLoading ? null : _submitTenant,
                                    child: const Text('Create and Assign Tenant'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
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
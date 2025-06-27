import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/tenant_provider.dart';
import 'package:kodipay/models/tenant_model.dart';

class MessagingDashboardScreen extends StatefulWidget {
  const MessagingDashboardScreen({super.key});

  @override
  State<MessagingDashboardScreen> createState() => _MessagingDashboardScreenState();
}

class _MessagingDashboardScreenState extends State<MessagingDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch properties and tenants when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
      propertyProvider.fetchProperties(context);
      tenantProvider.fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);

    final userRole = authProvider.auth?.role;
    if (userRole == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: const Color(0xFF90CAF9),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Group Chats'),
              Tab(text: 'Direct Messages'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Group Chats Tab
            _buildGroupChatsTab(context, propertyProvider, userRole),
            // Direct Messages Tab
            _buildDirectMessagesTab(context, propertyProvider, tenantProvider, userRole),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChatsTab(BuildContext context, PropertyProvider propertyProvider, String userRole) {
    if (propertyProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (propertyProvider.properties.isEmpty) {
      return const Center(child: Text('No properties available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: propertyProvider.properties.length,
      itemBuilder: (context, index) {
        final property = propertyProvider.properties[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF90CAF9),
              child: Icon(Icons.group, color: Colors.white),
            ),
            title: Text(property.name),
            subtitle: Text('${property.address}\nGroup chat for all tenants and landlord'),
              onTap: () {
              context.push('/messaging/group/${property.id}');
            },
          ),
        );
      },
    );
  }

  Widget _buildDirectMessagesTab(
    BuildContext context,
    PropertyProvider propertyProvider,
    TenantProvider tenantProvider,
    String userRole,
  ) {
    if (propertyProvider.isLoading || tenantProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (propertyProvider.properties.isEmpty) {
      return const Center(child: Text('No properties available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
                itemCount: propertyProvider.properties.length,
                itemBuilder: (context, index) {
                  final property = propertyProvider.properties[index];
                  final allRooms = property.floors.expand((floor) => floor.rooms).toList();
                  final occupiedRooms = allRooms.where((room) => room.tenantId != null && room.tenantId!.isNotEmpty).toList();

                  if (occupiedRooms.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                property.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
                      ...occupiedRooms.map((room) {
              final tenant = tenantProvider.tenants.firstWhere(
                (t) => t.id == room.tenantId,
                orElse: () => TenantModel(
                  id: '',
                  phoneNumber: '',
                  firstName: '',
                  lastName: '',
                  status: '',
                  paymentStatus: '',
                  property: null,
                ),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF90CAF9),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                          title: Text('Room ${room.roomNumber}'),
                  subtitle: Text(tenant.fullName),
                          onTap: () {
                    context.push('/messaging/direct/${room.tenantId}/${tenant.phoneNumber}');
                          },
                ),
                        );
                      }),
            const SizedBox(height: 16),
                    ],
                  );
                },
    );
  }
}

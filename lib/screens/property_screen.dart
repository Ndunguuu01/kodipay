import 'package:flutter/material.dart';
import 'package:kodipay/models/tenant_model.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/models/property.dart';
import 'package:kodipay/models/room_model.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/tenant_provider.dart' as tenantProvider;
import 'package:kodipay/providers/message_provider.dart';

class PropertyScreen extends StatelessWidget {
  final String propertyId;

  const PropertyScreen({super.key, required this.propertyId});

  Future<void> _assignTenant(
    BuildContext context,
    String propertyId,
    int floorNumber,
    RoomModel room,
  ) async {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final tenantProviderInstance = Provider.of<tenantProvider.TenantProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    await tenantProviderInstance.fetchTenants();
    final selectedTenant = await showDialog<TenantModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Tenant'),
          content: tenantProviderInstance.isLoading
              ? const Center(child: CircularProgressIndicator())
              : tenantProviderInstance.tenants.isEmpty
                  ? const Text('No tenants available')
                  : SingleChildScrollView(
                      child: Column(
                        children: tenantProviderInstance.tenants.map((tenant) {
                          return ListTile(
                            title: Text(tenant.fullName),
                            subtitle: Text(tenant.phoneNumber),
                            onTap: () => Navigator.pop(context, tenant),
                          );
                        }).toList(),
                      ),
                    ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
final result = await GoRouter.of(context).push<Map<String, dynamic>>(
  '/landlord-home/properties/add-tenant',
  extra: {
    'propertyId': propertyId,
    'roomId': room.id,
    'floorNumber': floorNumber,
    'roomNumber': room.roomNumber,
'excludeTenantIds': <String>[],
  },
);

                if (result != null && result['tenant'] != null) {
                  await propertyProvider.assignTenantToRoom(
                    propertyId: propertyId,
                    floorNumber: floorNumber,
                    roomNumber: room.roomNumber,
                    tenantId: result['tenant']['_id'],
                    messageProvider: messageProvider,
                  );

                  if (propertyProvider.errorMessage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tenant assigned successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(propertyProvider.errorMessage!)),
                    );
                  }
                }
              },
              child: const Text('Create New Tenant'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedTenant != null) {
      await propertyProvider.assignTenantToRoom(
        propertyId: propertyId,
        floorNumber: floorNumber,
        roomNumber: room.roomNumber,
        tenantId: selectedTenant.id,
        messageProvider: messageProvider,
      );

      if (propertyProvider.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tenant assigned to ${room.roomNumber} successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(propertyProvider.errorMessage!)),
        );
      }
    }
  }

  String _getTenantName(BuildContext context, String tenantId) {
    final tenantProviderInstance = Provider.of<tenantProvider.TenantProvider>(context, listen: false);
    final tenant = tenantProviderInstance.tenants.firstWhere(
      (t) => t.id == tenantId,
      orElse: () => TenantModel(
        id: '',
        phoneNumber: '',
        firstName: 'Unknown',
        lastName: '',
        status: '',
        paymentStatus: '',
        propertyId: '',
      ),
    );
    return tenant.fullName;
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);

    final property = propertyProvider.properties.firstWhere(
      (p) => p.id == propertyId,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: property.id.isEmpty
          ? const Center(child: Text('Property not found.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Address: ${property.address}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Rent: KES ${property.rentAmount}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text('Total Rooms: ${property.totalRooms}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Occupied Rooms: ${property.occupiedRooms}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Floors and Rooms:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (var floor in property.floors)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Floor ${floor.floorNumber}:',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        for (var room in floor.rooms)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${room.roomNumber} (${room.isOccupied ? 'Occupied' : 'Vacant'})'
                                    '${room.tenantId != null ? " - Assigned to ${_getTenantName(context, room.tenantId!)}" : ""}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                if (!room.isOccupied)
                                  TextButton(
                                    onPressed: () => _assignTenant(
                                      context,
                                      property.id,
                                      floor.floorNumber,
                                      room,
                                    ),
                                    child: const Text('Assign Tenant'),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
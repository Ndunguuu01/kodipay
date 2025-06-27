import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/property_provider.dart';
import '../providers/tenant_provider.dart';
import '../models/tenant_model.dart' as tenantModel;
import 'package:go_router/go_router.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);

    final updatedProperty = propertyProvider.properties.firstWhere(
      (p) => p.id == property.id,
      orElse: () => property,
    );

    // ✅ Updated getTenantName to show actual name
    String getTenantName(String? tenantId) {
      final tenant = tenantProvider.tenants.firstWhere(
        (t) => t.id == tenantId,
        orElse: () => tenantModel.TenantModel(
          id: '',
          phoneNumber: '',
          status: '',
          paymentStatus: '',
        ),
      );
      return tenant.fullName.isNotEmpty ? tenant.fullName : 'Unknown Tenant';
    }

    final assignedTenantIds = updatedProperty.floors
        .expand((floor) => floor.rooms)
        .where((room) => room.tenantId != null)
        .map((room) => room.tenantId!)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(updatedProperty.address),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${updatedProperty.address}'),
            Text('Rent: KES ${updatedProperty.rentAmount.toStringAsFixed(1)}'),
            Text('Total Rooms: ${updatedProperty.totalRooms}'),
            Text('Occupied Rooms: ${updatedProperty.occupiedRooms ?? 0}'),
            const SizedBox(height: 16),
            const Text('Floors and Rooms:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: updatedProperty.floors.map((floor) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Floor ${floor.floorNumber}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...floor.rooms.map((room) {
                        return room.tenantId == null
                            ? ListTile(
                                title: Text('${room.roomNumber} (Vacant)'),
                                trailing: TextButton(
                                  onPressed: () async {
                                    print('Assigning tenant to room:');
                                    print('Property ID: ${updatedProperty.id}');
                                    print('Room ID: ${room.id}');
                                    print('Floor Number: ${floor.floorNumber}');
                                    print('Room Number: ${room.roomNumber}');

                                    if (room.id.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Invalid room information')),
                                      );
                                      return;
                                    }

                                    await context.push(
                                      '/landlord-home/tenants/add?propertyId=${updatedProperty.id}&roomId=${room.id}&floorNumber=${floor.floorNumber}&roomNumber=${room.roomNumber}',
                                      extra: {
                                        'property': updatedProperty,
                                        'excludeTenantIds': assignedTenantIds.toList(),
                                      },
                                    );
                                  },
                                  child: const Text("Assign Tenant"),
                                ),
                              )
                            : ListTile(
                                onTap: () {
                                  final tenant = tenantProvider.tenants.firstWhere(
                                    (t) => t.id == room.tenantId,
                                    orElse: () => tenantModel.TenantModel(
                                      id: '',
                                      phoneNumber: '',
                                      status: '',
                                      paymentStatus: '',
                                    ),
                                  );
                                  context.go(
                                    '/room-detail',
                                    extra: {
                                      'room': room,
                                      'propertyId': updatedProperty.id,
                                      'tenant': tenant,
                                    },
                                  );
                                },
                                title: Text('${room.roomNumber} (Occupied)'),
                                subtitle: Text('Assigned to tenant: ${getTenantName(room.tenantId)}'),
                                trailing: const Icon(Icons.info_outline, color: Colors.blue),
                              );
                      }),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

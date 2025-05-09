import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/property_provider.dart';
import '../providers/tenant_provider.dart';
import '../models/tenant_model.dart' as tenantModel;
import 'add_tenant_screen.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({Key? key, required this.property}) : super(key: key);

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
          email: '',
          status: '',
          paymentStatus: '',
        ),
      );
      return tenant.fullName.isNotEmpty ? tenant.fullName : tenant.name;
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
                        return ListTile(
                          title: Text('${room.roomNumber} (${room.tenantId != null ? "Occupied" : "Vacant"})'),
                          subtitle: room.tenantId != null
                              ? Text('Assigned to tenant: ${getTenantName(room.tenantId)}')
                              : null,
                          trailing: room.tenantId == null
                              ? TextButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddTenantScreen(
                                          propertyId: updatedProperty.id,
                                          roomId: room.roomNumber,
                                          excludeTenantIds: assignedTenantIds.toList(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Assign Tenant"),
                                )
                              : null,
                        );
                      }).toList(),
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

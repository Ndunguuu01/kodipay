import 'package:flutter/material.dart';
import 'package:kodipay/models/tenant_model.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/models/room_model.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/tenant_provider.dart';
import 'package:kodipay/models/property_model.dart';
import 'package:kodipay/models/floor_model.dart';

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
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);

    // Fetch tenants before showing the add tenant screen
    await tenantProvider.fetchTenants();

    if (!context.mounted) return;

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

    final result = await context.push(
      '/landlord-home/tenants/add?propertyId=$propertyId&roomId=${room.id}&floorNumber=$floorNumber&roomNumber=${room.roomNumber}',
      extra: {'property': property},
    );

    if (result == true && context.mounted) {
      // Refresh property data to show updated room status
      await propertyProvider.fetchProperties(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant assigned successfully')),
        );
      }
    }
  }

  String _getTenantName(BuildContext context, String tenantId) {
    final tenantProviderInstance = Provider.of<TenantProvider>(context, listen: false);
    final tenant = tenantProviderInstance.tenants.firstWhere(
      (t) => t.id == tenantId,
      orElse: () => TenantModel(
        id: '',
        phoneNumber: '',
        firstName: 'Unknown',
        lastName: '',
        status: '',
        paymentStatus: '',
        property: null,
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

    // Calculate total rooms and occupied rooms
    int totalRooms = 0;
    int occupiedRooms = 0;
    double totalRevenue = 0;
    for (var floor in property.floors) {
      totalRooms += floor.rooms.length;
      occupiedRooms += floor.rooms.where((room) => room.isOccupied).length;
      // Add rent amount for each occupied room
      totalRevenue += floor.rooms.where((room) => room.isOccupied).length * property.rentAmount;
    }

    return Scaffold(
      body: property.id.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Property not found',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section with Gradient
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF90CAF9),
                          Colors.blue.shade700,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Back Button
                        Positioned(
                          top: 40,
                          left: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => context.go('/landlord-home'),
                            ),
                          ),
                        ),
                        // Property Name
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      property.address,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Property Stats
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF90CAF9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.analytics,
                                color: Color(0xFF90CAF9),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Rooms',
                                totalRooms.toString(),
                                Icons.meeting_room,
                                const Color(0xFF90CAF9),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Occupied',
                                occupiedRooms.toString(),
                                Icons.person,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Revenue',
                                'KES ${totalRevenue.toStringAsFixed(2)}',
                                Icons.attach_money,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Floors and Rooms
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF90CAF9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.layers,
                                color: Color(0xFF90CAF9),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Floors & Rooms',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: property.floors.length,
                          itemBuilder: (context, index) {
                            final floor = property.floors[index];
                            return _buildFloorCard(context, property, floor);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorCard(BuildContext context, PropertyModel property, FloorModel floor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF90CAF9).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF90CAF9).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.layers,
                    color: Color(0xFF90CAF9),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Floor ${floor.floorNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: floor.rooms.length,
            itemBuilder: (context, index) {
              final room = floor.rooms[index];
              return _buildRoomTile(context, property, floor, room);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(BuildContext context, PropertyModel property, FloorModel floor, RoomModel room) {
    print('Room: id=${room.id}, number=${room.roomNumber}, isOccupied=${room.isOccupied}, tenantId=${room.tenantId}');
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: room.isOccupied ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            room.isOccupied ? Icons.person : Icons.meeting_room,
            color: room.isOccupied ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          'Room ${room.roomNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: room.isOccupied
            ? Text(
                _getTenantName(context, room.tenantId!),
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              )
            : const Text(
                'Vacant',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
        trailing: room.isOccupied
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Occupied',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : TextButton.icon(
                onPressed: () => _assignTenant(context, property.id, floor.floorNumber, room),
                icon: const Icon(Icons.person_add),
                label: const Text('Assign'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF90CAF9),
                ),
              ),
        onTap: () {
          final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
          final tenant = room.isOccupied
              ? tenantProvider.tenants.firstWhere(
                  (t) => t.id == room.tenantId,
                  orElse: () => TenantModel(
                    id: '',
                    phoneNumber: '',
                    firstName: 'Unknown',
                    lastName: '',
                    status: '',
                    paymentStatus: '',
                    property: null,
                  ),
                )
              : null;

          context.go(
            '/room-detail',
            extra: {
              'room': room,
              'propertyId': property.id,
              'tenant': tenant,
            },
          );
        },
      ),
    );
  }
}
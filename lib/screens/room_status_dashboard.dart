import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:kodipay/models/property.dart';
import 'package:kodipay/models/room_model.dart';
import 'package:kodipay/models/bill_model.dart';

class RoomStatusDashboard extends StatefulWidget {
  const RoomStatusDashboard({super.key});

  @override
  State<RoomStatusDashboard> createState() => _RoomStatusDashboardState();
}

class _RoomStatusDashboardState extends State<RoomStatusDashboard> {
  PropertyModel? _selectedProperty;
  String? _selectedFloor;
  String? _selectedStatus;
  String? _selectedPaymentStatus;

  @override
  void initState() {
    super.initState();
    // Fetch properties and bills when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      propertyProvider.fetchProperties(context);
      billProvider.fetchAllBills(context);
    });
  }

  List<RoomModel> _getFilteredRooms() {
    if (_selectedProperty == null) return [];

    List<RoomModel> rooms = [];
    for (var floor in _selectedProperty!.floors) {
      if (_selectedFloor == null || floor.floorNumber.toString() == _selectedFloor) {
        rooms.addAll(floor.rooms);
      }
    }

    return rooms.where((room) {
      final matchesStatus = _selectedStatus == null || 
          (_selectedStatus == 'occupied' && room.isOccupied) ||
          (_selectedStatus == 'vacant' && !room.isOccupied);
      
      final matchesPaymentStatus = _selectedPaymentStatus == null ||
          (_selectedPaymentStatus == 'paid' && _isRoomPaid(room)) ||
          (_selectedPaymentStatus == 'pending' && !_isRoomPaid(room));

      return matchesStatus && matchesPaymentStatus;
    }).toList();
  }

  bool _isRoomPaid(RoomModel room) {
    if (!room.isOccupied) return true;
    
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final roomBills = billProvider.bills.where((bill) => 
      bill.roomId == room.id && 
      bill.status == BillStatus.pending
    ).toList();
    
    return roomBills.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final billProvider = Provider.of<BillProvider>(context);

    if (propertyProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final properties = propertyProvider.properties;
    if (properties.isEmpty) {
      return const Center(child: Text('No properties available'));
    }

    // Set default selected property if none is selected
    if (_selectedProperty == null && properties.isNotEmpty) {
      _selectedProperty = properties.first;
    }

    final filteredRooms = _getFilteredRooms();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Status Dashboard'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Property Dropdown
                DropdownButtonFormField<PropertyModel>(
                  value: _selectedProperty,
                  decoration: const InputDecoration(
                    labelText: 'Select Property',
                    border: OutlineInputBorder(),
                  ),
                  items: properties.map((property) {
                    return DropdownMenuItem(
                      value: property,
                      child: Text(property.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProperty = value;
                      _selectedFloor = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Floor Dropdown
                if (_selectedProperty != null)
                  DropdownButtonFormField<String>(
                    value: _selectedFloor,
                    decoration: const InputDecoration(
                      labelText: 'Select Floor',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Floors')),
                      ..._selectedProperty!.floors.map((floor) {
                        return DropdownMenuItem(
                          value: floor.floorNumber.toString(),
                          child: Text('Floor ${floor.floorNumber}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedFloor = value);
                    },
                  ),
                const SizedBox(height: 16),
                
                // Status Filter
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Room Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Status')),
                    DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                    DropdownMenuItem(value: 'vacant', child: Text('Vacant')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Payment Status Filter
                DropdownButtonFormField<String>(
                  value: _selectedPaymentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Payments')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPaymentStatus = value);
                  },
                ),
              ],
            ),
          ),

          // Room List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final room = filteredRooms[index];
                final isPaid = _isRoomPaid(room);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: room.isOccupied
                          ? (isPaid ? Colors.green : Colors.orange)
                          : Colors.grey,
                      child: Icon(
                        room.isOccupied ? Icons.person : Icons.home,
                        color: Colors.white,
                      ),
                    ),
                    title: Text('Room ${room.roomNumber}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Floor ${room.floorNumber}'),
                        Text(
                          room.isOccupied
                              ? 'Occupied by: ${room.tenantId ?? "Unknown"}'
                              : 'Vacant',
                        ),
                        Text(
                          'Payment Status: ${isPaid ? "Paid" : "Pending"}',
                          style: TextStyle(
                            color: isPaid ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        // TODO: Show room details
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 
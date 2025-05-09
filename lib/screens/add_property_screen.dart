import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/models/room_model.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/models/property.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _numberOfFloors = 1;
  List<int> _roomsPerFloor = [1];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _rentAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<RoomModel> _generateRooms(int floorNumber, int roomCount) {
    List<RoomModel> rooms = [];
    for (int i = 0; i < roomCount; i++) {
      final roomNumber = '$floorNumber${String.fromCharCode(97 + i)}';
      rooms.add(RoomModel(
        id: 'floor${floorNumber}_room$i',
        roomNumber: roomNumber,
        tenantId: null,
        isOccupied: false,
      ));
    }
    return rooms;
  }

  Future<void> _addProperty(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);

    if (authProvider.auth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add a property')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final rentAmountText = _rentAmountController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || address.isEmpty || rentAmountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final rentAmount = double.tryParse(rentAmountText);
    if (rentAmount == null || rentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid rent amount')),
      );
      return;
    }

    List<FloorModel> floors = [];
    for (int i = 0; i < _numberOfFloors; i++) {
      final floorNumber = i + 1;
      final rooms = _generateRooms(floorNumber, _roomsPerFloor[i]);
      floors.add(FloorModel(floorNumber: floorNumber, rooms: rooms));
    }

    await propertyProvider.addProperty(
      name: name,
      address: address,
      rentAmount: rentAmount,
      description: description.isEmpty ? null : description,
      floors: floors,
    );

    if (propertyProvider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property added successfully')),
      );
      context.go('/landlord-home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(propertyProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Property'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Property Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rentAmountController,
              decoration: const InputDecoration(
                labelText: 'Rent Amount (KES) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Number of Floors:',
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _numberOfFloors > 1
                          ? () {
                              setState(() {
                                _numberOfFloors--;
                                _roomsPerFloor.removeLast();
                              });
                            }
                          : null,
                    ),
                    Text('$_numberOfFloors'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _numberOfFloors++;
                          _roomsPerFloor.add(1);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < _numberOfFloors; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rooms on Floor ${i + 1}:',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _roomsPerFloor[i] > 1
                              ? () {
                                  setState(() {
                                    _roomsPerFloor[i]--;
                                  });
                                }
                              : null,
                        ),
                        Text('${_roomsPerFloor[i]}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _roomsPerFloor[i]++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Room Numbers Preview:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _numberOfFloors; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Floor ${i + 1}: ${_generateRooms(i + 1, _roomsPerFloor[i]).map((room) => room.roomNumber).join(", ")}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
            propertyProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: propertyProvider.isLoading ? null : () => _addProperty(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF90CAF9),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Add Property'),
                  ),
          ],
        ),
      ),
    );
  }
}

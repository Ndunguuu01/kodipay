import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/services/api.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _rentAmountController = TextEditingController();
  bool _isLoading = false;

  List<int> floors = [1];
  Map<int, int> roomsPerFloor = {1: 1};

  void _incrementRooms(int floor) {
    setState(() {
      roomsPerFloor[floor] = (roomsPerFloor[floor] ?? 0) + 1;
    });
  }

  void _decrementRooms(int floor) {
    setState(() {
      if ((roomsPerFloor[floor] ?? 0) > 1) {
        roomsPerFloor[floor] = (roomsPerFloor[floor] ?? 0) - 1;
      }
    });
  }

  void _addFloor() {
    setState(() {
      int newFloor = floors.isNotEmpty ? floors.last + 1 : 1;
      floors.add(newFloor);
      roomsPerFloor[newFloor] = 1;
    });
  }

  void _removeFloor() {
    setState(() {
      if (floors.isNotEmpty) {
        int removedFloor = floors.removeLast();
        roomsPerFloor.remove(removedFloor);
      }
    });
  }

  String _roomLabel(int index) {
    // Convert 0-based index to alphabet (A, B, C, ...)
    return String.fromCharCode(65 + index);
  }

  void _submitProperty() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token is missing')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        List<Map<String, dynamic>> floorsPayload = [];
        for (var floor in floors) {
          int roomCount = roomsPerFloor[floor] ?? 0;
          List<Map<String, dynamic>> rooms = [];
          for (int i = 0; i < roomCount; i++) {
            rooms.add({
              '_id': '${floor}_${_roomLabel(i)}',
              'roomNumber': _roomLabel(i),
              'tenantId': null,
              'isOccupied': false,
            });
          }
          floorsPayload.add({
            'floorNumber': floor,
            'rooms': rooms,
          });
        }

        final payload = {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'rentAmount': double.parse(_rentAmountController.text.trim()),
          'floors': floorsPayload,
          'landlordId': authProvider.auth?.id,
        };

        final response = await ApiService.post(
          '/properties',
          payload,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property added successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add property: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding property: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Property Name'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rentAmountController,
                decoration: const InputDecoration(labelText: 'Rent Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final n = num.tryParse(value);
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Must be greater than zero';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _removeFloor,
                    child: const Text('-'),
                  ),
                  const SizedBox(width: 8),
                  const Text('Floors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addFloor,
                    child: const Text('+'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: floors.length,
                  itemBuilder: (context, index) {
                    int floor = floors[index];
                    int roomCount = roomsPerFloor[floor] ?? 0;
                    return ListTile(
                      title: Text('Floor $floor', style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _decrementRooms(floor),
                          ),
                          Text(roomCount.toString(), style: const TextStyle(fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _incrementRooms(floor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitProperty,
                        child: const Text('Add Property'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _rentAmountController.dispose();
    super.dispose();
  }
}
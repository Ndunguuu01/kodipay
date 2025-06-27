import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
          const SnackBar(
            content: Text('Authentication token is missing'),
            backgroundColor: Colors.red,
          ),
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
            const SnackBar(
              content: Text('Property added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add property: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding property: $e'),
            backgroundColor: Colors.red,
          ),
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
      body: SingleChildScrollView(
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
                  // Title
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Property',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fill in the details below to add a new property',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Form Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Details Section
                    _buildSectionHeader('Property Details'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Property Name',
                      icon: Icons.business,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Property Address',
                      icon: Icons.location_on,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _rentAmountController,
                      label: 'Rent Amount (KES)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final n = num.tryParse(value);
                        if (n == null) return 'Enter a valid number';
                        if (n <= 0) return 'Must be greater than zero';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Floor Management Section
                    _buildSectionHeader('Floor Management'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFloorButton(
                            onPressed: _removeFloor,
                            icon: Icons.remove,
                            label: 'Remove Floor',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFloorButton(
                            onPressed: _addFloor,
                            icon: Icons.add,
                            label: 'Add Floor',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
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
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: floors.length,
                        itemBuilder: (context, index) {
                          int floor = floors[index];
                          int roomCount = roomsPerFloor[floor] ?? 0;
                          return _buildFloorCard(floor, roomCount);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Preview Section
                    _buildSectionHeader('Property Preview'),
                    const SizedBox(height: 16),
                    _buildPreviewCard(),
                    const SizedBox(height: 24),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submitProperty,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF90CAF9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Add Property',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF90CAF9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.settings,
            color: Color(0xFF90CAF9),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF90CAF9)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF90CAF9)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildFloorButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF90CAF9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFloorCard(int floor, int roomCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
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
        title: Text(
          'Floor $floor',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$roomCount ${roomCount == 1 ? 'Room' : 'Rooms'}',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
              onPressed: () => _decrementRooms(floor),
            ),
            Text(
              roomCount.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.green,
              onPressed: () => _incrementRooms(floor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final totalRooms = roomsPerFloor.values.fold(0, (sum, count) => sum + count);
    
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF90CAF9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.preview,
                  color: Color(0xFF90CAF9),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewItem(
            'Property Name',
            _nameController.text.isEmpty ? 'Not set' : _nameController.text,
            Icons.business,
          ),
          const SizedBox(height: 8),
          _buildPreviewItem(
            'Address',
            _addressController.text.isEmpty ? 'Not set' : _addressController.text,
            Icons.location_on,
          ),
          const SizedBox(height: 8),
          _buildPreviewItem(
            'Rent Amount',
            _rentAmountController.text.isEmpty
                ? 'Not set'
                : 'KES ${_rentAmountController.text}',
            Icons.attach_money,
          ),
          const SizedBox(height: 8),
          _buildPreviewItem(
            'Total Floors',
            floors.length.toString(),
            Icons.layers,
          ),
          const SizedBox(height: 8),
          _buildPreviewItem(
            'Total Rooms',
            totalRooms.toString(),
            Icons.meeting_room,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
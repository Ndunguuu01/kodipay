import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/tenant_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/models/property_model.dart';
import 'package:kodipay/models/room_model.dart';
import 'package:go_router/go_router.dart';

class AddTenantEnhancedScreen extends StatefulWidget {
  final String propertyId;
  final String roomId;
  final int floorNumber;
  final String roomNumber;
  final List<String> excludeTenantIds;
  final PropertyModel property;

  const AddTenantEnhancedScreen({
    super.key,
    required this.propertyId,
    required this.roomId,
    required this.floorNumber,
    required this.roomNumber,
    required this.property,
    this.excludeTenantIds = const [],
  });

  @override
  State<AddTenantEnhancedScreen> createState() => _AddTenantEnhancedScreenState();
}

class _AddTenantEnhancedScreenState extends State<AddTenantEnhancedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  bool _isLoading = false;
  
  // Property and room selection
  PropertyModel? _selectedProperty;
  RoomModel? _selectedRoom;
  int _currentStep = 0;
  List<PropertyModel> _availableProperties = [];
  List<RoomModel> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    // Fetch properties if not already loaded
    if (propertyProvider.properties.isEmpty) {
      await propertyProvider.fetchProperties(context);
    }
    
    // Set initial property if provided
    if (widget.propertyId.isNotEmpty) {
      _selectedProperty = propertyProvider.properties.firstWhere(
        (p) => p.id == widget.propertyId,
        orElse: () => widget.property,
      );
      _loadAvailableRooms();
      _currentStep = 1; // Skip property selection if property is pre-selected
    } else {
      // Get all properties with available rooms
      _availableProperties = propertyProvider.properties.where((property) {
        return property.floors.any((floor) => 
          floor.rooms.any((room) => !room.isOccupied)
        );
      }).toList();
    }
    
    setState(() {});
  }

  void _loadAvailableRooms() {
    if (_selectedProperty == null) return;
    
    _availableRooms = [];
    for (var floor in _selectedProperty!.floors) {
      for (var room in floor.rooms) {
        if (!room.isOccupied) {
          _availableRooms.add(room);
        }
      }
    }
    setState(() {});
  }

  void _selectProperty(PropertyModel property) {
    setState(() {
      _selectedProperty = property;
      _selectedRoom = null;
      _loadAvailableRooms();
      _currentStep = 1;
    });
  }

  void _selectRoom(RoomModel room) {
    setState(() {
      _selectedRoom = room;
      _currentStep = 2;
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitTenant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProperty == null || _selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a property and room first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
      final result = await tenantProvider.createTenant(
        propertyId: _selectedProperty!.id,
        roomId: _selectedRoom!.id,
        name: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        phone: _phoneController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        context: context,
      );

      if (result == true) {
        // Refresh properties to update room occupancy
        final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
        await propertyProvider.refreshProperties(context);
        if (mounted) {
          context.pop({'success': true});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tenantProvider.error ?? 'Failed to create tenant'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
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
                        onPressed: () => context.pop(),
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
                          'Add New Tenant',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStepDescription(),
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
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildProgressStep(0, 'Property', Icons.home),
                  _buildProgressLine(),
                  _buildProgressStep(1, 'Room', Icons.meeting_room),
                  _buildProgressLine(),
                  _buildProgressStep(2, 'Details', Icons.person),
                ],
              ),
            ),
            // Content based on current step
            _buildStepContent(),
          ],
        ),
      ),
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Select a property with available rooms';
      case 1:
        return 'Choose an empty room from ${_selectedProperty?.name ?? "the property"}';
      case 2:
        return 'Fill in the tenant details';
      default:
        return 'Add a new tenant to your property';
    }
  }

  Widget _buildProgressStep(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted 
                ? const Color(0xFF90CAF9)
                : isActive 
                  ? const Color(0xFF90CAF9).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isCompleted || isActive 
                ? Colors.white 
                : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isCompleted || isActive 
                ? const Color(0xFF90CAF9)
                : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine() {
    return Container(
      height: 2,
      width: 20,
      color: _currentStep > 0 ? const Color(0xFF90CAF9) : Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPropertySelection();
      case 1:
        return _buildRoomSelection();
      case 2:
        return _buildTenantDetails();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPropertySelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Property',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_availableProperties.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No properties with available rooms found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableProperties.length,
              itemBuilder: (context, index) {
                final property = _availableProperties[index];
                final availableRooms = property.floors
                    .expand((floor) => floor.rooms)
                    .where((room) => !room.isOccupied)
                    .length;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF90CAF9).withOpacity(0.1),
                      child: const Icon(Icons.home, color: Color(0xFF90CAF9)),
                    ),
                    title: Text(property.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(property.address),
                        Text('$availableRooms rooms available'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectProperty(property),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRoomSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              ),
              const Text(
                'Select Room',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedProperty != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProperty!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_selectedProperty!.address),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_availableRooms.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No available rooms in this property',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableRooms.length,
              itemBuilder: (context, index) {
                final room = _availableRooms[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: const Icon(Icons.meeting_room, color: Colors.green),
                    ),
                    title: Text('Room ${room.roomNumber}'),
                    subtitle: Text('Floor ${_getFloorNumber(room)}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectRoom(room),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  int _getFloorNumber(RoomModel room) {
    for (var floor in _selectedProperty!.floors) {
      if (floor.rooms.any((r) => r.id == room.id)) {
        return floor.floorNumber;
      }
    }
    return 0;
  }

  Widget _buildTenantDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              ),
              const Text(
                'Tenant Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedProperty != null && _selectedRoom != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProperty!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Room ${_selectedRoom!.roomNumber}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                      return 'Must be a valid phone number, e.g. +254703969986';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nationalIdController,
                  label: 'National ID',
                  icon: Icons.badge,
                  validator: (value) => value == null || value.isEmpty ? 'National ID is required' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitTenant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF90CAF9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add Tenant',
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
        ],
      ),
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
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      // Add the name property for accessibility
      autofillHints: [label],
    );
  }
} 
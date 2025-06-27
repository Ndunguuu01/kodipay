import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/models/property_model.dart';

class CreateTenantButton extends StatelessWidget {
  final String propertyId;
  final String roomId;
  final int floorNumber;
  final String roomNumber;
  final List<String> excludeTenantIds;

  const CreateTenantButton({
    super.key,
    required this.propertyId,
    required this.roomId,
    required this.floorNumber,
    required this.roomNumber,
    this.excludeTenantIds = const [],
  });

  void _navigateToAddTenant(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final property = propertyProvider.properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => PropertyModel(
        id: propertyId,
        name: 'Property',
        address: '',
        rentAmount: 0,
        totalRooms: 0,
        floors: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    context.go(
      '/landlord-home/tenants/add?propertyId=$propertyId&roomId=$roomId&floorNumber=$floorNumber&roomNumber=$roomNumber',
      extra: {
        'property': property,
        'excludeTenantIds': excludeTenantIds,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add),
      label: const Text('Create a new tenant'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF90CAF9),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () => _navigateToAddTenant(context),
    );
  }
}

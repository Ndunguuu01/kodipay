import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    context.go(
      '/landlord-home/properties/add-tenant',
      extra: {
        'propertyId': propertyId,
        'roomId': roomId,
        'floorNumber': floorNumber,
        'roomNumber': roomNumber,
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/models/property.dart';
import 'package:kodipay/models/floor_model.dart';
import 'package:kodipay/services/api.dart';
import 'package:kodipay/providers/message_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PropertyProvider with ChangeNotifier {
  List<PropertyModel> _properties = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PropertyModel> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch properties for a landlord
  Future<void> fetchProperties(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await ApiService.get(
        '/properties/landlord',
        context: context,
      );

      print('Fetch properties API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> propertiesJson = jsonDecode(response.body);
        _properties = propertiesJson.map((json) => PropertyModel.fromJson(json)).toList();

        // Calculate occupiedRooms dynamically for each property
        _properties = _properties.map((property) {
          int occupiedCount = 0;
          for (var floor in property.floors) {
            occupiedCount += floor.rooms.where((room) => room.isOccupied).length;
          }
          return PropertyModel(
            id: property.id,
            name: property.name,
            address: property.address,
            rentAmount: property.rentAmount,
            totalRooms: property.totalRooms,
            occupiedRooms: occupiedCount,
            floors: property.floors,
            description: property.description,
            landlordId: property.landlordId,
            imageUrl: property.imageUrl,
            createdAt: property.createdAt,
            updatedAt: property.updatedAt,
          );
        }).toList();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        _errorMessage = 'Failed to fetch properties: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Error fetching properties: ${e.toString()}';
      print('Error details: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Add a new property
  Future<void> addProperty({
    required String name,
    required String address,
    required double rentAmount,
    String? description,
    required List<FloorModel> floors,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final propertyData = {
        'name': name,
        'address': address,
        'rentAmount': rentAmount,
        'description': description,
        'floors': floors.map((floor) => floor.toJson()).toList(),
      };

      final response = await ApiService.post(
        '/properties',
        propertyData,
        context: null,
      );

      if (response.statusCode == 201) {
        final newProperty = PropertyModel.fromJson(jsonDecode(response.body));
        _properties.add(newProperty);
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = 'Failed to add property: ${response.statusCode} - ${response.body}';
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Error adding property: ${e.toString()}';
      print('Error details: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Assign tenant to a room
  Future<void> assignTenantToRoom({
    required String propertyId,
    required int floorNumber,
    required String roomNumber,
    required String tenantId,
    required MessageProvider messageProvider,
    String? roomId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final payload = {
        'floorNumber': floorNumber,
        'roomNumber': roomNumber,
        'tenantId': tenantId,
        if (roomId != null) 'roomId': roomId,
      };

      print('Assigning tenant with payload: $payload, roomId: ${roomId ?? "not provided"}');

      final response = await ApiService.put(
        '/properties/$propertyId/assign-tenant',
        payload,
        context: null,
      );

      print('Assign tenant response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedProperty = PropertyModel.fromJson(responseData['property']);
        final index = _properties.indexWhere((p) => p.id == propertyId);
        if (index != -1) _properties[index] = updatedProperty;

        await _notifyAssignedTenant(
          property: updatedProperty,
          floorNumber: floorNumber,
          roomNumber: roomNumber,
          tenantId: tenantId,
          messageProvider: messageProvider,
        );
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
      } else if (response.statusCode == 404 && response.body.contains('Tenant not found')) {
        _errorMessage = 'Tenant does not exist. Please verify the tenant ID.';
      } else {
        _errorMessage = 'Failed to assign tenant: ${response.statusCode} - ${response.body}';
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Error assigning tenant: ${e.toString()}';
      print('Error details: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Delete a property
  Future<void> deleteProperty(String propertyId, BuildContext context) async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await ApiService.delete(
        '/properties/$propertyId',
        context: context,
      );

      if (response.statusCode == 200) {
        _properties.removeWhere((property) => property.id == propertyId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property deleted successfully')),
        );
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        _errorMessage = 'Failed to delete property: ${response.statusCode} - ${response.body}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete property: ${response.body}')),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Error deleting property: ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Notify tenant about assignment
  Future<void> _notifyAssignedTenant({
    required PropertyModel property,
    required int floorNumber,
    required String roomNumber,
    required String tenantId,
    required MessageProvider messageProvider,
  }) async {
    try {
      if (property.landlordId == null) {
        print('Warning: landlordId is null for property ${property.id}');
        return;
      }

      final message = 'You have been assigned to room $roomNumber on floor $floorNumber in ${property.name} at ${property.address}. Rent: KES ${property.rentAmount}.';
      await messageProvider.sendDirectMessage(
        senderId: property.landlordId!,
        recipientId: tenantId,
        content: message,
      );
    } catch (e) {
      print('Error notifying tenant: $e');
    }
  }

  /// Clear all properties
  void clearProperties() {
    _properties = [];
    _errorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Get property by ID
  PropertyModel? getPropertyById(String propertyId) {
    try {
      return _properties.firstWhere((p) => p.id == propertyId);
    } catch (_) {
      return null;
    }
  }
}
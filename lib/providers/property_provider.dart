import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/models/property_model.dart';
import 'package:kodipay/models/floor_model.dart';
import 'package:kodipay/services/api.dart';
import 'package:kodipay/providers/message_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';

class PropertyProvider with ChangeNotifier {
  List<PropertyModel> _properties = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<PropertyModel> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch properties for a landlord
  Future<void> fetchProperties(BuildContext context) async {
    // Check if we have a valid cache
    if (_lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _properties.isNotEmpty) {
      return; // Use cached data
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Ensure we have a valid token before making the request
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.auth?.token == null) {
        _errorMessage = 'Authentication required. Please log in again.';
        if (context.mounted) {
          context.go('/login');
        }
        return;
      }

      final response = await ApiService.get('/properties', context: context);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _properties = data.map((json) => PropertyModel.fromJson(json)).toList();
        _lastFetchTime = DateTime.now();
        _errorMessage = null;

        // Calculate occupiedRooms dynamically for each property
        _properties = _properties.map((property) {
          int occupiedCount = 0;
          for (var floor in property.floors) {
            occupiedCount += floor.rooms.where((room) => room.isOccupied || room.tenantId != null).length;
          }
          return PropertyModel(
            id: property.id,
            name: property.name,
            address: property.address,
            rentAmount: property.rentAmount,
            totalRooms: property.totalRooms,
            occupiedRooms: occupiedCount,
            floors: property.floors,
            createdAt: property.createdAt,
            updatedAt: property.updatedAt,
          );
        }).toList();
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
        // Clear the auth state and redirect to login
        authProvider.logout();
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        _errorMessage = 'Failed to fetch properties: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Error fetching properties: ${e.toString()}';
      print('Error details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProperties(BuildContext context) async {
    _lastFetchTime = null; // Clear cache
    await fetchProperties(context);
  }

  /// Add a new property
  Future<void> addProperty({
    required String name,
    required String address,
    required double rentAmount,
    required List<FloorModel> floors,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final propertyData = {
        'name': name,
        'address': address,
        'rentAmount': rentAmount,
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
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error adding property: ${e.toString()}';
      print('Error details: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
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
    notifyListeners();

    try {
      final payload = {
        'floorNumber': floorNumber,
        'roomNumber': roomNumber,
        'tenantId': tenantId,
        if (roomId != null) 'roomId': roomId,
      };

      print('Assigning tenant with payload: $payload, roomId: ${roomId ?? "not provided"}');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }
      await ApiService.setAuthToken(token);
      final response = await ApiService.put(
        '/properties/$propertyId/rooms/${roomId ?? ""}/assign-tenant',
        payload,
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
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error assigning tenant: ${e.toString()}';
      print('Error details: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a property
  Future<void> deleteProperty(String propertyId, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

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
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error deleting property: ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _notifyAssignedTenant({
    required PropertyModel property,
    required int floorNumber,
    required String roomNumber,
    required String tenantId,
    required MessageProvider messageProvider,
  }) async {
    try {
      final messageContent = 'You have been assigned to Room $roomNumber on Floor $floorNumber in ${property.name}';
      
      await messageProvider.sendMessage(
        messageContent,
        tenantId,
      );
    } catch (e) {
      print('Error sending tenant assignment notification: $e');
    }
  }

  /// Clear all properties
  void clearProperties() {
    _properties = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Get property by ID
  PropertyModel? getPropertyById(String propertyId) {
    try {
      return _properties.firstWhere((p) => p.id == propertyId);
    } catch (_) {
      return null;
    }
  }

  /// Remove tenant from a room
  Future<void> removeTenantFromRoom({
    required String propertyId,
    required String roomId,
    required MessageProvider messageProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }
      await ApiService.setAuthToken(token);
      
      final response = await ApiService.put(
        '/properties/$propertyId/rooms/$roomId/remove-tenant',
        {},
      );

      print('Remove tenant response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedProperty = PropertyModel.fromJson(responseData['property']);
        final index = _properties.indexWhere((p) => p.id == propertyId);
        if (index != -1) _properties[index] = updatedProperty;

        // Notify the tenant about removal
        final room = updatedProperty.floors
            .expand((floor) => floor.rooms)
            .firstWhere((room) => room.id == roomId);
        
        if (room.tenantId != null) {
          await messageProvider.sendMessage(
            'You have been removed from Room ${room.roomNumber} in ${updatedProperty.name}',
            room.tenantId!,
          );
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = 'Failed to remove tenant: ${response.statusCode} - ${response.body}';
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error removing tenant: ${e.toString()}';
      print('Error details: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
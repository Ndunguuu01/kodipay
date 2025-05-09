import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/models/property.dart';
import 'package:kodipay/providers/message_provider.dart';
import 'package:kodipay/services/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PropertyProvider with ChangeNotifier {
  static const String baseUrl = 'http://192.168.0.102:5000/api';
  List<PropertyModel> _properties = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PropertyModel> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

    // Helper method to get auth token
  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return token;
  }

  /// Fetch properties for a landlord
  Future<void> fetchProperties(BuildContext context,) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/properties/landlord'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> propertiesJson = jsonDecode(response.body);
        _properties = propertiesJson.map((json) => PropertyModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to fetch properties: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error fetching properties: ${e.toString()}';
      print('Error details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
    notifyListeners();

    try {
      final token = await _getAuthToken();
      final propertyData = {
        'name': name,
        'address': address,
        'rentAmount': rentAmount,
        'description': description,
        'floors': floors.map((floor) => floor.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(propertyData),
      );

      if (response.statusCode == 201) {
        final newProperty = PropertyModel.fromJson(jsonDecode(response.body));
        _properties.add(newProperty);
      } else {
        _errorMessage = 'Failed to add property: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error adding property: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //// Assign tenant to a room
  Future<void> assignTenantToRoom({
    required String propertyId,
    required int floorNumber,
    required String roomNumber,
    required String tenantId,
    required MessageProvider messageProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      final response = await http.put(
        Uri.parse('$baseUrl/properties/$propertyId/assign-tenant'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'floorNumber': floorNumber,
          'roomNumber': roomNumber,
          'tenantId': tenantId,
        }),
      );

      if (response.statusCode == 200) {
        final updatedProperty = PropertyModel.fromJson(jsonDecode(response.body));
        final index = _properties.indexWhere((p) => p.id == propertyId);
        if (index != -1) _properties[index] = updatedProperty;

        await _notifyAssignedTenant(
          property: updatedProperty,
          floorNumber: floorNumber,
          roomNumber: roomNumber,
          tenantId: tenantId,
          messageProvider: messageProvider,
        );
      } else {
        _errorMessage = 'Failed to assign tenant: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error assigning tenant: ${e.toString()}';
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
      final response = await ApiService.delete('/properties/$propertyId', context: context);
      if (response.statusCode == 200) {
        _properties.removeWhere((property) => property.id == propertyId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete property')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
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
      final message = 'You have been assigned to room $roomNumber on floor $floorNumber in ${property.name} at ${property.address}. Rent: KES ${property.rentAmount}.';
      await messageProvider.sendDirectMessage(
        senderId: property.landlordId,
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
}


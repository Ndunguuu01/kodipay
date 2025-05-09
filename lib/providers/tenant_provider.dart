import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/models/tenant_model.dart';
import 'package:kodipay/services/api.dart';

class TenantProvider with ChangeNotifier {
  final String baseUrl = 'http://192.168.0.102:5000/api';

  List<TenantModel> _tenants = [];
  bool _isLoading = false;
  String? _error;

  List<TenantModel> get tenants => _tenants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch tenants from the server
  Future<void> fetchTenants() async {
    _setLoading(true);

    try {
      final response = await ApiService.get('/users/tenants');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tenants = data.map((json) => TenantModel.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch tenants: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching tenants: $e';
    } finally {
      _setLoading(false);
    }
  }

  // For creating a new tenant and assigning to a room (POST)
  Future<bool> createAndAssignTenant({
  required String roomId,
  required String propertyId,
  required String name,
  required String phone,
  String? email,
  String? nationalId,
  required String token,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final payload = {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId,
      'propertyId': propertyId,
    };
    print('Creating and assigning tenant to roomId: $roomId with payload: $payload');

    final response = await ApiService.post(
      '/rooms/$roomId/assign-tenant',
      payload,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.contains('application/json')) {
        final data = jsonDecode(response.body);
        if (data['tenant'] != null) {
          final newTenant = TenantModel.fromJson(data['tenant']);
          _tenants.add(newTenant);
        }
        return true;
      } else {
        _error = 'Unexpected response format: Expected JSON, got $contentType';
        return false;
      }
    } else if (response.statusCode == 400) {
      _error = 'Invalid input: ${response.body}';
      return false;
    } else if (response.statusCode == 404) {
      _error = 'Room not found. Please ensure the room exists.';
      return false;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      _error = 'Authentication error: Please log in again';
      return false;
    } else {
      _error = 'Failed to create and assign tenant: ${response.statusCode} ${response.reasonPhrase}\nResponse: ${response.body}';
      return false;
    }
  } catch (e) {
    _error = 'Error creating and assigning tenant: $e';
    print(_error);
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // For assigning an existing tenant to a room (PUT)
  Future<bool> assignExistingTenant({
    required String roomId,
    required String tenantId,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = {'tenantId': tenantId};
      print('Assigning existing tenant to roomId: $roomId with payload: $payload');

      final response = await ApiService.put(
        '/rooms/$roomId/assign-tenant',
        payload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          return true;
        } else {
          _error = 'Unexpected response format: Expected JSON, got $contentType';
          return false;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _error = 'Authentication error: Please log in again';
        return false;
      } else {
        _error = 'Failed to assign tenant: ${response.statusCode} ${response.reasonPhrase}\nResponse: ${response.body}';
        return false;
      }
    } catch (e) {
      _error = 'Error assigning tenant: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get tenant by ID
  TenantModel? getTenantById(String id) {
    try {
      return _tenants.firstWhere((tenant) => tenant.id == id);
    } catch (_) {
      return null;
    }
  }

  // Clear tenant list
  void clearTenants() {
    _tenants = [];
    _error = null;
    notifyListeners();
  }

  // Set loading state and notify listeners
  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }
}

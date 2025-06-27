import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/models/tenant_model.dart';
import 'package:kodipay/services/api.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';

class TenantProvider with ChangeNotifier {
  List<TenantModel> _tenants = [];
  bool _isLoading = false;
  String? _error;
  String? _lastCreatedTenantId;

  List<TenantModel> get tenants => _tenants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastCreatedTenantId => _lastCreatedTenantId;

  String normalizePhoneNumber(String phone) {
    if (phone.isEmpty) {
      // print('normalizePhoneNumber: Empty phone number');
      return phone;
    }
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.startsWith('7') && digits.length == 9) {
      // print('normalizePhoneNumber: raw=$phone, normalized=+254$digits');
      return '+254$digits';
    }
    if (digits.startsWith('254') && digits.length == 12) {
      // print('normalizePhoneNumber: raw=$phone, normalized=+$digits');
      return '+$digits';
    }
    if (RegExp(r'^\+2547\d{8}$').hasMatch(phone)) {
      // print('normalizePhoneNumber: raw=$phone, already normalized');
      return phone;
    }
    // print('normalizePhoneNumber: Invalid format for $phone, returning unchanged');
    return phone;
  }

  Future<void> fetchTenants() async {
    _setLoading(true);
    try {
      final response = await ApiService.get('/tenants');
      print('fetchTenants response status: ${response.statusCode}');
      print('fetchTenants response body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tenants = data.map((json) => TenantModel.fromJson(json)).toList();
        print('Tenants fetched: ${_tenants.length}');
      } else {
        _error = 'Failed to fetch tenants: ${response.statusCode} - ${response.body}';
        print(_error);
      }
    } catch (e) {
      _error = 'Error fetching tenants: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUnassignedTenants() async {
    _setLoading(true);
    try {
      final response = await ApiService.get('/tenants/unassigned');
      // print('fetchUnassignedTenants response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tenants = data.map((json) => TenantModel.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch unassigned tenants: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _error = 'Error fetching unassigned tenants: $e';
      // print('fetchUnassignedTenants error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkPhoneNumber(String phone, String token) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phone);
      // print('checkPhoneNumber: raw=$phone, normalized=$normalizedPhone');
      if (!RegExp(r'^\+2547\d{8}$').hasMatch(normalizedPhone)) {
        // print('checkPhoneNumber: Invalid format: $normalizedPhone');
        _error = 'Invalid phone number format: $normalizedPhone';
        return false;
      }
      final response = await ApiService.get(
        '/users/check-phone?phoneNumber=$normalizedPhone',
        headers: {'Authorization': 'Bearer $token'},
      );
      // print('checkPhoneNumber response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exists'] == true) {
          // print('checkPhoneNumber: Phone $normalizedPhone exists');
          return true;
        }
        // print('checkPhoneNumber: Phone $normalizedPhone does not exist');
        return false;
      }
      // print('checkPhoneNumber: Non-200 status: ${response.statusCode}');
      _error = 'Failed to check phone number: ${response.statusCode}';
      return false;
    } catch (e) {
      // print('checkPhoneNumber error: $e');
      _error = 'Error checking phone number: $e';
      return false;
    }
  }

  Future<bool> createAndAssignTenant({
    required String propertyId,
    required String name,
    required String phone,
    String? nationalId,
    String? email,
    required String token,
    required int floorNumber,
    required String roomNumber,
    String? roomId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedPhone = normalizePhoneNumber(phone);
      // print('createAndAssignTenant: raw phone=$phone, normalized=$normalizedPhone');

      if (!RegExp(r'^\+2547\d{8}$').hasMatch(normalizedPhone)) {
        _error = 'Invalid phone number format: $normalizedPhone. Must be +254 followed by 9 digits starting with 7.';
        // print('createAndAssignTenant: Invalid phone format: $normalizedPhone');
        return false;
      }

      final phoneExists = await checkPhoneNumber(normalizedPhone, token);
      if (phoneExists) {
        _error = 'Phone number already exists: $normalizedPhone';
        // print('createAndAssignTenant: Phone number check failed: $normalizedPhone exists');
        return false;
      }

      final createPayload = {
        'fullName': name.trim(),
        'phoneNumber': normalizedPhone,
        'role': 'tenant',
        'password': generatePassword(),
        if (email != null && email.isNotEmpty) 'email': email.trim(),
        if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId.trim(),
      };

      // print('createAndAssignTenant: Creating tenant with payload: ${jsonEncode(createPayload)}');

      final createResponse = await ApiService.post(
        '/users',
        createPayload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // print('createAndAssignTenant response status: ${createResponse.statusCode}');
      // print('createAndAssignTenant response body: ${createResponse.body}');

      if (createResponse.statusCode != 201) {
        String errorMessage = 'Failed to create tenant: ${createResponse.statusCode}';
        try {
          final errorData = jsonDecode(createResponse.body);
          errorMessage += ' - ${errorData['message'] ?? 'Unknown error'}';
        } catch (_) {
          errorMessage += ' - ${createResponse.body}';
        }
        _error = errorMessage;
        // print('createAndAssignTenant: Error: $errorMessage');
        return false;
      }

      final tenantData = jsonDecode(createResponse.body);
      if (tenantData is! Map<String, dynamic> || tenantData['tenant'] is! Map<String, dynamic>) {
        _error = 'Invalid tenant creation response: Expected tenant object';
        // print('createAndAssignTenant: Invalid response format');
        return false;
      }
      if (tenantData['tenant']['id'] == null) {
        _error = 'Tenant creation response missing tenant id';
        // print('createAndAssignTenant: Missing tenant.id');
        return false;
      }
      _lastCreatedTenantId = tenantData['tenant']['id'].toString();

      // Add delay to ensure tenant is committed to database
      // print('createAndAssignTenant: Waiting 500ms before assigning tenant');
      await Future.delayed(const Duration(milliseconds: 500));

      final assignPayload = {
        'floorNumber': floorNumber,
        'roomNumber': roomNumber,
        'tenantId': _lastCreatedTenantId,
        if (roomId != null) 'roomId': roomId,
      };

      // print('createAndAssignTenant: Assigning tenant with payload: ${jsonEncode(assignPayload)}');

      final assignResponse = await ApiService.put(
        '/properties/$propertyId/assign-tenant',
        assignPayload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // print('createAndAssignTenant: Assign tenant response status: ${assignResponse.statusCode}');
      // print('createAndAssignTenant: Assign tenant response body: ${assignResponse.body}');

      if (assignResponse.statusCode == 200) {
        final contentType = assignResponse.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final data = jsonDecode(assignResponse.body);
          if (data['tenant'] != null) {
            final newTenant = TenantModel.fromJson(data['tenant']);
            _tenants.add(newTenant);
          }
          // print('createAndAssignTenant: Success');
          return true;
        } else {
          _error = 'Unexpected response format: Expected JSON, got $contentType';
          // print('createAndAssignTenant: Unexpected response format');
          return false;
        }
      } else {
        _error = 'Failed to assign tenant: ${assignResponse.statusCode} - ${assignResponse.body}';
        // print('createAndAssignTenant: Assign failed: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Error creating and assigning tenant: $e';
      // print('createAndAssignTenant error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignExistingTenant({
    required String propertyId,
    required String tenantId,
    required String token,
    required int floorNumber,
    required String roomNumber,
    String? roomId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = {
        'floorNumber': floorNumber,
        'roomNumber': roomNumber,
        'tenantId': tenantId,
        if (roomId != null) 'roomId': roomId,
      };

      // print('assignExistingTenant: Assigning tenant with payload: ${jsonEncode(payload)}');

      final response = await ApiService.put(
        '/properties/$propertyId/assign-tenant',
        payload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // print('assignExistingTenant response status: ${response.statusCode}');
      // print('assignExistingTenant response body: ${response.body}');

      if (response.statusCode == 200) {
        // print('assignExistingTenant: Success');
        return true;
      } else {
        _error = 'Failed to assign tenant: ${response.statusCode} - ${response.body}';
        // print('assignExistingTenant: Error: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Error assigning tenant: $e';
      // print('assignExistingTenant error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  TenantModel? getTenantById(String id) {
    try {
      return _tenants.firstWhere((tenant) => tenant.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearTenants() {
    _tenants = [];
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }

  String generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<TenantModel?> createTenant({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? email,
    String? nationalId,
    required String propertyId,
    String? roomId,
    required BuildContext context,
  }) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      if (!RegExp(r'^\+2547\d{8}$').hasMatch(normalizedPhone)) {
        _error = 'Invalid phone number format: $normalizedPhone. Must be +254 followed by 9 digits starting with 7.';
        return null;
      }

      // Get auth token
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;
      if (token == null) {
        _error = 'Authentication token not found';
        return null;
      }

      // Use default password as requested
      const defaultPassword = 'password123';

      // Create the user account with the correct API endpoint and field names
      final userPayload = {
        'name': '${firstName.trim()} ${lastName.trim()}',
        'email': email?.trim() ?? '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com',
        'phone': normalizedPhone,
        'password': defaultPassword,
        'role': 'tenant',
        if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId.trim(),
      };

      final userResponse = await ApiService.post(
        '/auth/register',
        userPayload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode != 201) {
        String errorMessage = 'Failed to create user account: ${userResponse.statusCode}';
        try {
          final errorData = jsonDecode(userResponse.body);
          errorMessage += ' - ${errorData['message'] ?? 'Unknown error'}';
        } catch (_) {
          errorMessage += ' - ${userResponse.body}';
        }
        _error = errorMessage;
        return null;
      }

      final userData = jsonDecode(userResponse.body);
      final userId = userData['data']['id'] ?? userData['id'];
      
      if (userId == null) {
        _error = 'User creation response missing user id';
        return null;
      }

      // Create tenant record
      final tenantPayload = {
        'userId': userId,
        'propertyId': propertyId,
        'roomId': roomId,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phoneNumber': normalizedPhone,
        'email': email?.trim(),
        'nationalId': nationalId?.trim(),
        'status': 'active',
        'paymentStatus': 'pending',
      };

      final tenantResponse = await ApiService.post(
        '/tenants',
        tenantPayload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (tenantResponse.statusCode != 201) {
        String errorMessage = 'Failed to create tenant record: ${tenantResponse.statusCode}';
        try {
          final errorData = jsonDecode(tenantResponse.body);
          errorMessage += ' - ${errorData['message'] ?? 'Unknown error'}';
        } catch (_) {
          errorMessage += ' - ${tenantResponse.body}';
        }
        _error = errorMessage;
        return null;
      }

      final tenantData = jsonDecode(tenantResponse.body);
      final newTenant = TenantModel.fromJson(tenantData['data'] ?? tenantData);
      _tenants.add(newTenant);

      // Send SMS notification about default password
      await _sendPasswordNotification(normalizedPhone, defaultPassword, token);

      return newTenant;
    } catch (e) {
      _error = 'Error creating tenant: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _sendPasswordNotification(String phone, String password, String token) async {
    try {
      final smsPayload = {
        'phone': phone,
        'message': 'Welcome to KodiPay! Your default password is: $password. Please change it after your first login for security.',
      };

      await ApiService.post(
        '/notifications/sms',
        smsPayload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Don't fail the tenant creation if SMS fails
      print('Failed to send SMS notification: $e');
    }
  }

  Future<void> deleteTenant(String tenantId, BuildContext context) async {
    _setLoading(true);
    _error = null;
    notifyListeners();
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;
      if (token == null) {
        _error = 'Authentication token not found';
        return;
      }
      await ApiService.setAuthToken(token);
      final response = await ApiService.delete('/tenants/$tenantId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _tenants.removeWhere((t) => t.id == tenantId);
        notifyListeners();
      } else {
        _error = 'Failed to delete tenant: \\${response.statusCode} - \\${response.body}';
      }
    } catch (e) {
      _error = 'Error deleting tenant: \\${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }
}

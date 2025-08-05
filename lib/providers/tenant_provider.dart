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
    if (phone.isEmpty) return phone;
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.startsWith('+')) {
      return '+$digits';
    }
    return '+$digits';
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
      if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(normalizedPhone)) {
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

  Future<Map<String, dynamic>?> createUser({
    required String name,
    required String phone,
    required String nationalId,
    String? email,
    required String password,
    required String token,
  }) async {
    if (nationalId.isEmpty) {
      _error = 'National ID is required.';
      return null;
    }
    try {
      final createPayload = {
        'name': name.trim(),
        'phone': phone,
        'role': 'tenant',
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email.trim(),
        'nationalId': nationalId.trim(),
      };

      final createResponse = await ApiService.post(
        '/auth/register',
        createPayload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (createResponse.statusCode != 201) {
        String errorMessage = 'Failed to create user: ${createResponse.statusCode}';
        try {
          final errorData = jsonDecode(createResponse.body);
          errorMessage += ' - ${errorData['message'] ?? 'Unknown error'}';
        } catch (_) {
          errorMessage += ' - ${createResponse.body}';
        }
        _error = errorMessage;
        return null;
      }

      final userData = jsonDecode(createResponse.body);
      if (userData == null || (userData['id'] == null && (userData['data'] == null || userData['data']['id'] == null))) {
        _error = 'User creation failed or missing user id.';
        return null;
      }
      return userData;
    } catch (e) {
      _error = 'Error creating user: $e';
      return null;
    }
  }

  Future<bool> createTenantRecord({
    required String propertyId,
    required String roomId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String nationalId,
    required String token,
  }) async {
    try {
      final now = DateTime.now();
      final leaseStart = now.toIso8601String();
      final leaseEnd = DateTime(now.year + 1, now.month, now.day).toIso8601String();
      final tenantPayload = {
        'property': propertyId,
        'unit': roomId,
        'name': '${firstName.trim()} ${lastName.trim()}',
        'phone': phoneNumber,
        'nationalId': nationalId.trim(),
        'leaseStart': leaseStart,
        'leaseEnd': leaseEnd,
      };
      print('Sending tenant payload: $tenantPayload');
      final tenantResponse = await ApiService.post(
        '/tenants',
        tenantPayload,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Tenant creation response status: ${tenantResponse.statusCode}');
      print('Tenant creation response body: ${tenantResponse.body}');
      if (tenantResponse.statusCode != 201) {
        String errorMessage = 'Tenant creation failed:  [33m${tenantResponse.statusCode} [0m';
        try {
          final errorData = jsonDecode(tenantResponse.body);
          errorMessage += ' -  [31m${errorData['message'] ?? 'Unknown error'} [0m';
        } catch (_) {
          errorMessage += ' - ${tenantResponse.body}';
        }
        print('Tenant creation error: $errorMessage');
        _error = errorMessage; // <-- Show backend error in UI
        return false;
      }
      print('Tenant created successfully!');
      return true;
    } catch (e) {
      print('Tenant creation error: $e');
      return false;
    }
  }

  Future<bool> createAndAssignTenant({
    required String firstName,
    required String lastName,
    required String phone,
    required String nationalId,
    String? email,
    required String propertyId,
    String? roomId,
    required int floorNumber,
    required String roomNumber,
    required BuildContext context,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedPhone = normalizePhoneNumber(phone);
      if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(normalizedPhone)) {
        _error = 'Invalid phone number format: $normalizedPhone';
        return false;
      }
      if (nationalId.isEmpty) {
        _error = 'National ID is required.';
        return false;
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;
      if (token == null) {
        _error = 'Authentication token not found';
        return false;
      }

      final userExists = await checkPhoneNumber(normalizedPhone, token);
      if (userExists) {
        _error = 'Phone number already exists: $normalizedPhone';
        return false;
      }

      const defaultPassword = 'password123';

      final userData = await createUser(
        name: '$firstName $lastName',
        phone: normalizedPhone,
        nationalId: nationalId,
        email: email,
        password: defaultPassword,
        token: token,
      );

      if (userData == null) {
        // _error is already set in createUser
        return false;
      }
      final userId = userData['id'] ?? (userData['data'] != null ? userData['data']['id'] : null);
      if (userId == null) {
        _error = 'User creation failed or missing user id.';
        return false;
      }

      final tenantCreated = await createTenantRecord(
        propertyId: propertyId,
        roomId: roomId!,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: normalizedPhone,
        nationalId: nationalId,
        token: token,
      );

      if (!tenantCreated) {
        return false;
      }

      // TODO: Assign tenant to property/unit if needed (depends on backend implementation)

      // Send SMS notification about default password
      await _sendPasswordNotification(normalizedPhone, defaultPassword, token);

      return true;
    } catch (e) {
      _error = 'Error creating and assigning tenant: $e';
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

  /// Clean, minimal tenant creation
  Future<bool> createTenant({
    required String propertyId,
    required String roomId,
    required String name,
    required String phone,
    required String nationalId,
    required BuildContext context,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;
      final payload = {
        'property': propertyId,
        'unit': roomId,
        'name': name.trim(),
        'phone': phone.trim(),
        'nationalId': nationalId.trim(),
        'leaseStart': DateTime.now().toIso8601String(),
        'leaseEnd': DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day).toIso8601String(),
      };
      print('Sending tenant payload: $payload');
      final response = await ApiService.post(
        '/tenants',
        payload,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      print('Tenant creation response status:  [33m${response.statusCode} [0m');
      print('Tenant creation response body: ${response.body}');
      if (response.statusCode == 201) {
        print('Tenant created successfully!');
        return true;
      } else {
        String errorMessage = 'Tenant creation failed: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage += ' - ${errorData['message'] ?? 'Unknown error'}';
        } catch (_) {
          errorMessage += ' - ${response.body}';
        }
        print('Tenant creation error: $errorMessage');
        _error = errorMessage;
        return false;
      }
    } catch (e) {
      print('Tenant creation error: $e');
      _error = 'Tenant creation error: $e';
      return false;
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

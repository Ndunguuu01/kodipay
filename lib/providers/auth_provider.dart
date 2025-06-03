import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/services/api.dart'; 
import 'package:kodipay/models/auth.dart'; 
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  AuthModel? _auth;
  String? _errorMessage;
  
  AuthModel? get auth => _auth;
  String? get errorMessage => _errorMessage;
  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  Future<void> login(String phone, String password, BuildContext context) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/login', {
        'phone': phone,
        'password': password,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _auth = AuthModel.fromJson(responseData);
        _errorMessage = null;
        
        // Save credentials and tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phoneNumber', phone);
        await prefs.setString('password', password);
        await prefs.setString('auth_token', responseData['token']);
        await prefs.setString('refresh_token', responseData['refreshToken']);
        
        // Set tokens in ApiService
        await ApiService.setAuthToken(responseData['token']);
        await ApiService.setRefreshToken(responseData['refreshToken']);

        // Navigate based on role
        if (context.mounted) {
          if (_auth?.role == 'tenant') {
            context.go('/tenant-home');
          } else if (_auth?.role == 'landlord') {
            context.go('/landlord-home');
          }
        }
      } else {
        final responseData = jsonDecode(response.body);
        _errorMessage = responseData['message'] ?? 'Login failed';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> register(
    String phoneNumber, 
    String password, 
    String role,
    String firstName,
    String lastName,
    String email,
    BuildContext context, 
  ) async {
    _errorMessage = null;
    notifyListeners();

    try {
      print('Making register API call to /auth/register');
      final response = await ApiService.post(
        '/auth/register',
        {
          'phone': phoneNumber,
          'password': password,
          'role': role,
          'name': '$firstName $lastName',
          'email': email,
        },
        context: context,
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 201) {
        final authJson = jsonDecode(response.body);
        print('Parsed auth JSON: $authJson');
        
        _auth = AuthModel.fromJson(authJson);
        print('Auth model created with name: ${_auth?.name}');
        
        await ApiService.setAuthToken(authJson['token']);
        await ApiService.setRefreshToken(authJson['refreshToken']);
        print('Tokens set in ApiService after registration');
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Registration failed';
        print('Registration failed with message: $_errorMessage');
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (e is UnauthorizedException) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = 'Error during registration: $e';
      }
      print('Registration error: $_errorMessage');
      throw Exception(_errorMessage);
    } finally {
      notifyListeners();
    }
  }

  Future<bool> checkAndRestoreAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final refreshToken = prefs.getString('refresh_token');
      
      if (token != null && refreshToken != null) {
        // Set tokens in ApiService
        await ApiService.setAuthToken(token);
        await ApiService.setRefreshToken(refreshToken);
        
        // Verify token by making a test request
        final response = await ApiService.get('/auth/verify');
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          _auth = AuthModel.fromJson(responseData);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error restoring auth state: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _auth = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('phoneNumber');
    await prefs.remove('password');
    await ApiService.clearAuthToken();
    await ApiService.clearRefreshToken();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void updateAuth(AuthModel updatedAuth) {
    _auth = updatedAuth;
    notifyListeners();
  }
}

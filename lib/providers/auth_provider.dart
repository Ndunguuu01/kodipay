import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/services/api.dart'; 
import 'package:kodipay/models/auth.dart'; 

class AuthProvider with ChangeNotifier {
  AuthModel? _auth;
  bool _isLoading = false;
  String? _errorMessage;
  
  AuthModel? get auth => _auth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> login(String phoneNumber, String password, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/auth/login',
        {
          'phoneNumber': phoneNumber,
          'password': password,
        },
        context: context,
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final authJson = jsonDecode(response.body);
        print('Parsed auth JSON: $authJson');
        print('User data from response: ${authJson['user']}');
        
        _auth = AuthModel.fromJson(authJson);
        print('Auth model created with name: ${_auth?.name}');
        
        final token = authJson['token'];
        print('Token received: $token');
        await ApiService.setAuthToken(token);
        await ApiService.setRefreshToken(authJson['refreshToken']);
        print('Tokens set in ApiService after login');
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Login failed';
        print('Login failed with message: $_errorMessage');
      }
    } catch (e) {
      if (e is UnauthorizedException) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = 'Error during login: $e';
      }
      print('Login error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
    String phoneNumber, 
    String password, 
    String role,
    String firstName,
    String lastName, 
    BuildContext context, 
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/auth/register',
        {
          'phoneNumber': phoneNumber,
          'password': password,
          'role': role,
          'firstName': firstName,
          'lastName': lastName,
          'name': '$firstName $lastName',
        },
        context: context,
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 201) {
        final authJson = jsonDecode(response.body);
        print('Parsed auth JSON: $authJson');
        print('User data from response: ${authJson['user']}');
        
        _auth = AuthModel.fromJson(authJson);
        print('Auth model created with name: ${_auth?.name}');
        
        await ApiService.setAuthToken(authJson['token']);
        await ApiService.setRefreshToken(authJson['refreshToken']);
        print('Tokens set in ApiService after registration');
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Registration failed';
        print('Registration failed with message: $_errorMessage');
      }
    } catch (e) {
      if (e is UnauthorizedException) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = 'Error during registration: $e';
      }
      print('Registration error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    print('Logging out - clearing auth and tokens');
    _auth = null;
    await ApiService.clearAuthToken();
    await ApiService.clearRefreshToken();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

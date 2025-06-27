import 'package:flutter/material.dart';

import 'package:kodipay/models/auth.dart';
import 'package:kodipay/services/api_service.dart';
import 'package:kodipay/services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  AuthModel? _auth;
  bool _isLoading = false;
  String? _error;
  String? _errorMessage;
  String? _intendedDestination;

  AuthModel? get auth => _auth;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _auth != null;
  AuthModel? get user => _auth;
  String? get intendedDestination => _intendedDestination;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _errorMessage = null;
    notifyListeners();
  }

  void updateAuth(AuthModel updatedAuth) {
    _auth = updatedAuth;
    notifyListeners();
  }

  void setIntendedDestination(String destination) {
    _intendedDestination = destination;
    notifyListeners();
  }

  void clearIntendedDestination() {
    _intendedDestination = null;
    notifyListeners();
  }

  Future<void> _setAuthState(AuthModel newAuth) async {
    _auth = newAuth;
    if (newAuth.token != null) {
      await StorageService.saveToken(newAuth.token!);
    }
    if (newAuth.refreshToken != null) {
      await StorageService.saveRefreshToken(newAuth.refreshToken!);
    }
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    _auth = null;
    await StorageService.deleteToken();
    await StorageService.deleteRefreshToken();
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token != null) {
        final response = await ApiService.get('/auth/me');
        _auth = AuthModel.fromJson(response['data']);
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
      _auth = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/auth/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );
      _auth = AuthModel.fromJson(response);
      if (_auth?.token != null) {
        await StorageService.saveToken(_auth!.token!);
        await ApiService.setAuthToken(_auth!.token!);
      }
      if (_auth?.refreshToken != null) {
        await StorageService.saveRefreshToken(_auth!.refreshToken!);
        await ApiService.setRefreshToken(_auth!.refreshToken!);
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password, String phone) async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );
      _auth = AuthModel.fromJson(response['data']);
      if (_auth?.token != null) {
        await StorageService.saveToken(_auth!.token!);
      }
      if (_auth?.refreshToken != null) {
        await StorageService.saveRefreshToken(_auth!.refreshToken!);
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.post(
        '/auth/logout',
        data: {},
      );
      await StorageService.deleteToken();
      await StorageService.deleteRefreshToken();
      _auth = null;
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, String email, String phone) async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.patch(
        '/users/${_auth!.id}',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
        },
      );
      _auth = AuthModel.fromJson(response['data']);
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token found');
      }

      final response = await ApiService.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      _auth = AuthModel.fromJson(response['data']);
      if (_auth?.token != null) {
        await StorageService.saveToken(_auth!.token!);
      }
      if (_auth?.refreshToken != null) {
        await StorageService.saveRefreshToken(_auth!.refreshToken!);
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
      await logout();
    }
  }

  void updateTokensFromRefresh(String newToken, String newRefreshToken) {
    if (_auth != null) {
      _auth = AuthModel(
        id: _auth!.id,
        name: _auth!.name,
        email: _auth!.email,
        phoneNumber: _auth!.phoneNumber,
        role: _auth!.role,
        createdAt: _auth!.createdAt,
        updatedAt: _auth!.updatedAt,
        token: newToken,
        refreshToken: newRefreshToken,
        phone: _auth!.phone,
      );
      notifyListeners();
    }
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.get('/auth/me');
      _auth = AuthModel.fromJson(response['data']);
    } catch (e) {
      _error = e.toString();
      _auth = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.post('/auth/request-password-reset', data: {
        'email': email,
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

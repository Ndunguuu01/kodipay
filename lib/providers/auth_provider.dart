import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';

import 'package:kodipay/models/auth.dart';
import 'package:kodipay/services/api.dart';
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
      await ApiService.setAuthToken(newAuth.token!);
    }
    if (newAuth.refreshToken != null) {
      await StorageService.saveRefreshToken(newAuth.refreshToken!);
      await ApiService.setRefreshToken(newAuth.refreshToken!);
    }
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    _auth = null;
    await StorageService.deleteToken();
    await StorageService.deleteRefreshToken();
    await ApiService.setAuthToken(null);
    await ApiService.setRefreshToken(null);
    notifyListeners();
  }

  Future<void> initialize() async {
    print('AuthProvider.initialize: Starting initialization'); // Debug log
    _isLoading = true;
    notifyListeners();

    try {
      // Get both tokens
      final token = await StorageService.getToken();
      final refreshToken = await StorageService.getRefreshToken();
      
      print('AuthProvider.initialize: Retrieved token: ${token != null ? "Token exists" : "No token"}'); // Debug log
      print('AuthProvider.initialize: Retrieved refresh token: ${refreshToken != null ? "Refresh token exists" : "No refresh token"}'); // Debug log
      
      // Clear auth state if no tokens are found
      if (token == null && refreshToken == null) {
        print('AuthProvider.initialize: No tokens found, clearing auth state'); // Debug log
        await _clearAuthState();
        return;
      }
      
      // Set tokens in API service
      if (token != null) {
        await ApiService.setAuthToken(token);
      }
      if (refreshToken != null) {
        await ApiService.setRefreshToken(refreshToken);
      }
      
      // Try to get current user with token
      if (token != null) {
        print('AuthProvider.initialize: Calling /auth/me'); // Debug log
        try {
          final response = await ApiService.get('/auth/me');
          print('AuthProvider.initialize: /auth/me response status: ${response.statusCode}'); // Debug log
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            _auth = AuthModel.fromJson(data['data']);
            print('AuthProvider.initialize: Auth user loaded: ${_auth?.name}, ID: ${_auth?.id}'); // Debug log
            return; // Successfully authenticated
          } else {
            print('AuthProvider.initialize: /auth/me failed with status: ${response.statusCode}'); // Debug log
            
            // If we have a refresh token, try to refresh the access token
            if (refreshToken != null) {
              print('AuthProvider.initialize: Attempting to refresh token'); // Debug log
              final refreshSuccess = await ApiService.refreshTokenIfNeeded(null);
              
              if (refreshSuccess) {
                // Try again with the new token
                print('AuthProvider.initialize: Token refreshed, retrying /auth/me'); // Debug log
                final retryResponse = await ApiService.get('/auth/me');
                
                if (retryResponse.statusCode == 200) {
                  final retryData = jsonDecode(retryResponse.body);
                  _auth = AuthModel.fromJson(retryData['data']);
                  print('AuthProvider.initialize: Auth user loaded after token refresh: ${_auth?.name}'); // Debug log
                  return; // Successfully authenticated after refresh
                }
              }
            }
            
            // If we get here, both token and refresh token failed
            print('AuthProvider.initialize: Authentication failed, clearing tokens'); // Debug log
            await _clearAuthState();
          }
        } catch (e) {
          print('AuthProvider.initialize: Error calling /auth/me: $e'); // Debug log
          // Clear tokens on error
          await _clearAuthState();
        }
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
      _auth = null;
      print('AuthProvider.initialize: Error loading auth user: $e'); // Debug log
      await _clearAuthState();
    } finally {
      _isLoading = false;
      print('AuthProvider.initialize: Completed initialization, isAuthenticated: ${_auth != null}'); // Debug log
      notifyListeners();
    }
  }

  /// Update tokens after a successful token refresh
  Future<void> updateTokensFromRefresh(String newToken, String newRefreshToken) async {
    print('AuthProvider.updateTokensFromRefresh: Updating tokens after refresh'); // Debug log
    
    // Update tokens in storage
    await StorageService.saveToken(newToken);
    await StorageService.saveRefreshToken(newRefreshToken);
    
    // Update API service tokens
    await ApiService.setAuthToken(newToken);
    await ApiService.setRefreshToken(newRefreshToken);
    
    // Update auth model if it exists
    if (_auth != null) {
      _auth = _auth!.copyWith(
        token: newToken,
        refreshToken: newRefreshToken,
      );
      print('AuthProvider.updateTokensFromRefresh: Updated auth model tokens'); // Debug log
    } else {
      print('AuthProvider.updateTokensFromRefresh: No auth model to update'); // Debug log
    }
    
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/login', {
        'phone': phone,
        'password': password,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _auth = AuthModel.fromJson(data);
        // Debug log for role and displayRole
        print('DEBUG: User role after login: ${_auth?.role}, displayRole: ${_auth?.displayRole}');
        if (_auth?.token != null) {
          await StorageService.saveToken(_auth!.token!);
          await ApiService.setAuthToken(_auth!.token!);
        }
        if (_auth?.refreshToken != null) {
          await StorageService.saveRefreshToken(_auth!.refreshToken!);
          await ApiService.setRefreshToken(_auth!.refreshToken!);
        }
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String firstName, String lastName, String password, String phone, String role, String nationalId) async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/register', {
        'name': '$firstName $lastName',
        'password': password,
        'phone': phone,
        'role': role,
        'nationalId': nationalId,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _auth = AuthModel.fromJson(data);
        if (_auth?.token != null) {
          await StorageService.saveToken(_auth!.token!);
        }
        if (_auth?.refreshToken != null) {
          await StorageService.saveRefreshToken(_auth!.refreshToken!);
        }
      } else {
        throw Exception('Registration failed with status: ${response.statusCode}');
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
    print('AuthProvider.logout: Starting logout process'); // Debug log
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      // Clear intended destination to prevent redirect loops
      _intendedDestination = null;
      
      // Try to call the logout endpoint, but don't wait for it to complete
      // This prevents hanging if the server is unreachable
      ApiService.post('/auth/logout', {}).timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('Logout request timed out'),
      ).then((response) {
        if (response.statusCode != 200) {
          print('AuthProvider.logout: Logout API call failed with status: ${response.statusCode}'); // Debug log
        } else {
          print('AuthProvider.logout: Logout API call successful'); // Debug log
        }
      }).catchError((e) {
        print('AuthProvider.logout: Error during logout API call: $e'); // Debug log
      });
      
      // Clear all tokens and auth state regardless of API call result
      print('AuthProvider.logout: Clearing tokens and auth state'); // Debug log
      await StorageService.deleteToken();
      await StorageService.deleteRefreshToken();
      await ApiService.setAuthToken(null);
      await ApiService.setRefreshToken(null);
      _auth = null;
      print('AuthProvider.logout: Tokens and auth state cleared'); // Debug log
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
      print('AuthProvider.logout: Error during logout: $e'); // Debug log
      
      // Still clear auth state even if there was an error
      await _clearAuthState();
    } finally {
      _isLoading = false;
      print('AuthProvider.logout: Logout process completed'); // Debug log
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, String email, String phone) async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.patch('/users/${_auth!.id}', {
        'name': name,
        'email': email,
        'phone': phone,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _auth = AuthModel.fromJson(data);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
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
      final response = await ApiService.post('/auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      if (response.statusCode != 200) {
        throw Exception('Failed to change password: ${response.statusCode}');
      }
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

      final response = await ApiService.post('/auth/refresh-token', {'refreshToken': refreshToken});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _auth = AuthModel.fromJson(data['data']);
        if (_auth?.token != null) {
          await StorageService.saveToken(_auth!.token!);
          await ApiService.setAuthToken(_auth!.token!);
        }
        if (_auth?.refreshToken != null) {
          await StorageService.saveRefreshToken(_auth!.refreshToken!);
          await ApiService.setRefreshToken(_auth!.refreshToken!);
        }
      } else {
        throw Exception('Failed to refresh token: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
      await logout();
    }
  }

  // The updateTokensFromRefresh method is already defined above

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
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _auth = AuthModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to check auth: ${response.statusCode}');
      }
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
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/request-password-reset', {
        'email': email,
      });
      if (response.statusCode != 200) {
        throw Exception('Failed to request password reset: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/reset-password', {
        'token': token,
        'newPassword': newPassword,
      });
      if (response.statusCode != 200) {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

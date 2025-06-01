import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:kodipay/utils/logger.dart';

class ApiService {
  // Configuration constants
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _lastConnectionCheckKey = 'last_connection_check';

  // Connection state
  static bool _isConnected = true;
  static DateTime? _lastConnectionCheck;
  static String? _token;
  static String? _refreshToken;

  // Getters
  static bool get isConnected => _isConnected;
  static DateTime? get lastConnectionCheck => _lastConnectionCheck;

  static String get baseUrl {
    if (kReleaseMode) {
      // Production URL
      return 'https://api.kodipay.com/api';
    } else if (kDebugMode) {
      // Development URL
      return 'http://192.168.100.71:5000/api';
    } else {
      // Staging URL
      return 'https://staging-api.kodipay.com/api';
    }
  }

  /// Initialize the service
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      _lastConnectionCheck = DateTime.tryParse(
        prefs.getString(_lastConnectionCheckKey) ?? '',
      );
      
      Logger.info('ApiService initialized with token: ${_token != null ? 'Token exists' : 'No token'}');
      
      // Test connection on initialization
      await ApiService.testConnection();
    } catch (e) {
      Logger.error('Error initializing ApiService: $e');
      _isConnected = false;
    }
  }

  /// Set the access token
  static Future<void> setAuthToken(String? token) async {
    try {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString(_tokenKey, token);
        Logger.info('Auth token set successfully');
      } else {
        await prefs.remove(_tokenKey);
        Logger.info('Auth token cleared');
      }
    } catch (e) {
      Logger.error('Error setting auth token: $e');
      rethrow;
    }
  }

  /// Set the refresh token
  static Future<void> setRefreshToken(String? token) async {
    try {
      _refreshToken = token;
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString(_refreshTokenKey, token);
        Logger.info('Refresh token set successfully');
      } else {
        await prefs.remove(_refreshTokenKey);
        Logger.info('Refresh token cleared');
      }
    } catch (e) {
      Logger.error('Error setting refresh token: $e');
      rethrow;
    }
  }

  /// Clear tokens on logout or failure
  static Future<void> clearAuthToken() async => await setAuthToken(null);
  static Future<void> clearRefreshToken() async => await setRefreshToken(null);

  /// Make HTTP request with retry logic and error handling
  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
    Duration timeout = _timeout,
  }) async {
    int retryCount = 0;
    while (true) {
      try {
        final response = await request().timeout(timeout);
        
        // Update connection status
        _isConnected = true;
        _lastConnectionCheck = DateTime.now();
        await _updateLastConnectionCheck();

        if (response.statusCode >= 500 && retryCount < maxRetries) {
          Logger.warning('Server error (${response.statusCode}), retrying... (${retryCount + 1}/$maxRetries)');
          await Future.delayed(retryDelay);
          retryCount++;
          continue;
        }
        return response;
      } catch (e) {
        if (e is http.ClientException || e is SocketException) {
          _isConnected = false;
          Logger.error('Network error: $e');
        }
        
        if (retryCount < maxRetries) {
          Logger.warning('Request failed, retrying... (${retryCount + 1}/$maxRetries)');
          await Future.delayed(retryDelay);
          retryCount++;
          continue;
        }
        rethrow;
      }
    }
  }

  /// Update last connection check timestamp
  static Future<void> _updateLastConnectionCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastConnectionCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      Logger.error('Error updating last connection check: $e');
    }
  }

  /// Get request with authentication
  static Future<http.Response> get(String endpoint, {
    BuildContext? context,
    Map<String, String>? headers,
    Duration timeout = _timeout,
  }) async {
    final authProvider = context != null 
        ? Provider.of<AuthProvider>(context, listen: false)
        : null;
    
    final token = authProvider?.auth?.token;
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return _makeRequest(
      () => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? defaultHeaders,
      ),
      timeout: timeout,
    );
  }

  /// Post request with authentication
  static Future<http.Response> post(String endpoint, dynamic data, {
    BuildContext? context,
    Map<String, String>? headers,
    Duration timeout = _timeout,
  }) async {
    final authProvider = context != null 
        ? Provider.of<AuthProvider>(context, listen: false)
        : null;
    
    final token = authProvider?.auth?.token;
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return _makeRequest(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? defaultHeaders,
        body: json.encode(data),
      ),
      timeout: timeout,
    );
  }

  /// Put request with authentication
  static Future<http.Response> put(String endpoint, dynamic data, {
    BuildContext? context,
    Map<String, String>? headers,
    Duration timeout = _timeout,
  }) async {
    final authProvider = context != null 
        ? Provider.of<AuthProvider>(context, listen: false)
        : null;
    
    final token = authProvider?.auth?.token;
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return _makeRequest(
      () => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? defaultHeaders,
        body: json.encode(data),
      ),
      timeout: timeout,
    );
  }

  /// Delete request with authentication
  static Future<http.Response> delete(String endpoint, {
    BuildContext? context,
    Map<String, String>? headers,
    Duration timeout = _timeout,
  }) async {
    final authProvider = context != null 
        ? Provider.of<AuthProvider>(context, listen: false)
        : null;
    
    final token = authProvider?.auth?.token;
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return _makeRequest(
      () => http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? defaultHeaders,
      ),
      timeout: timeout,
    );
  }

  /// Refresh token logic
  static Future<bool> _refreshTokenIfNeeded(BuildContext? context) async {
    if (_refreshToken == null) {
      Logger.warning('No refresh token available');
      return false;
    }

    try {
      Logger.info('Attempting to refresh token');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken'];

        if (newToken != null && newRefreshToken != null) {
          await setAuthToken(newToken);
          await setRefreshToken(newRefreshToken);
          Logger.info('Token refreshed successfully');
          return true;
        }
      }

      Logger.error('Token refresh failed with response: ${response.body}');
      return false;
    } catch (e) {
      Logger.error('Error during token refresh: $e');
      return false;
    }
  }

  /// Handle unauthorized access
  static Future<void> _handleUnauthorized(BuildContext? context) async {
    Logger.warning('Handling unauthorized access');
    await clearAuthToken();
    await clearRefreshToken();

    if (context != null && context.mounted) {
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
    }
  }

  /// Test the connection to the backend server
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      Logger.info('Testing connection to backend server...');
      final response = await _makeRequest(
        () => http.get(
          Uri.parse('$baseUrl/health'),
          headers: {'Content-Type': 'application/json'},
        ),
        timeout: const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isConnected = true;
        _lastConnectionCheck = DateTime.now();
        await _updateLastConnectionCheck();
        
        Logger.info('Backend connection successful: ${data['message']}');
        return {
          'success': true,
          'message': data['message'] ?? 'Connection successful',
          'version': data['version'],
          'environment': data['environment'],
          'latency': data['latency'],
        };
      } else {
        _isConnected = false;
        Logger.error('Backend connection failed: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Connection failed: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      _isConnected = false;
      Logger.error('Error testing backend connection: $e');
      return {
        'success': false,
        'message': 'Connection error',
        'error': e.toString(),
      };
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

import 'dart:convert';
import 'dart:io' show Platform, SocketException;
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

  // Flag to prevent multiple simultaneous refresh attempts
  static bool _refreshingToken = false;

  // Getters
  static bool get isConnected => _isConnected;
  static DateTime? get lastConnectionCheck => _lastConnectionCheck;

  static String get baseUrl {
    // Use local backend address
    return 'http://192.168.100.71:5000/api';
  }

  /// Initialize the service
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      Logger.info('ApiService initialized with refresh token: ${_refreshToken != null ? '_refreshToken exists' : 'No refresh token'}');
      _lastConnectionCheck = DateTime.tryParse(
        prefs.getString(_lastConnectionCheckKey) ?? '',
      );

      Logger.info('ApiService initialized with token: ${_token != null ? 'Token exists' : 'No token'}');
      
      // Test connection on initialization
      await testConnection();
    } catch (e) {
      Logger.error('Error initializing ApiService: $e');
      _isConnected = false;
    }
  }

  /// Get the current auth token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get the current refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Set the access token
  static Future<void> setAuthToken(String? token) async {
    try {
      Logger.info('ApiService: Setting auth token: ${token != null ? "SET" : "CLEARED"}');
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
  static Future<void> clearAuthToken() async {
    Logger.info('ApiService: Clearing auth token');
    await setAuthToken(null);
  }
  static Future<void> clearRefreshToken() async => await setRefreshToken(null);

  /// Make HTTP request with retry logic and error handling
  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
    Duration timeout = _timeout,
    BuildContext? context,
  }) async {
    int retryCount = 0;
    http.Response? response;

    while (true) {
      try {
        // Test connection before making request
        if (!_isConnected) {
          final connectionTest = await testConnection();
          if (!connectionTest['success']) {
            throw Exception('No connection to server: ${connectionTest['message']}');
          }
        }

        // Rebuild headers with the current token before each attempt
        final currentHeaders = {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        };
        
        // Log the request details
        Logger.info('Making request to: $baseUrl');
        Logger.info('Headers: $currentHeaders');

        response = await request().timeout(timeout);

        // Log the response
        Logger.info('Response status: ${response.statusCode}');
        Logger.info('Response body: ${response.body}');

        // Update connection status
        _isConnected = true;
        _lastConnectionCheck = DateTime.now();
        await _updateLastConnectionCheck();

        // Handle unauthorized access
        if (response.statusCode == 401) {
          Logger.warning('Received 401 response, attempting token refresh');

          // Prevent multiple simultaneous refresh attempts
          if (_refreshingToken) {
            Logger.warning('Token refresh already in progress, waiting...');
            await Future.delayed(const Duration(seconds: 1));
            if (retryCount < maxRetries) {
              retryCount++;
              continue;
            } else {
              Logger.error('Max retries reached while waiting for token refresh.');
              await _handleUnauthorized(context);
              return response;
            }
          }

          _refreshingToken = true;
          final refreshSuccess = await refreshTokenIfNeeded(context);
          _refreshingToken = false;

          if (refreshSuccess && retryCount < maxRetries) {
            Logger.info('Token refreshed, retrying request with new token (Attempt ${retryCount + 1})');
            retryCount++;
            await Future.delayed(retryDelay);
            continue;
          } else {
            Logger.error('Token refresh failed or max retries reached after refresh.');
            await _handleUnauthorized(context);
            return response;
          }
        }

        // Handle other server errors with retry
        if (response.statusCode >= 500 && retryCount < maxRetries) {
          Logger.warning('Server error (${response.statusCode}), retrying... (${retryCount + 1}/$maxRetries)');
          await Future.delayed(retryDelay);
          retryCount++;
          continue;
        }

        // Return successful response or client errors/non-retryable server errors
        return response;
      } catch (e) {
        if (e is http.ClientException || e is SocketException) {
          _isConnected = false;
          Logger.error('Network error: $e');
          Logger.error('Failed to connect to server at: $baseUrl');
        }

        if (retryCount < maxRetries) {
          Logger.warning('Request failed, retrying... (${retryCount + 1}/$maxRetries)');
          await Future.delayed(retryDelay);
          retryCount++;
          continue;
        }
        // Rethrow the exception if max retries are reached
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
    return _makeRequest(
      () { // Define defaultHeaders inside the lambda to capture latest _token
        final defaultHeaders = {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        };
        return http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers ?? defaultHeaders,
        );
      },
      timeout: timeout,
      context: context,
    );
  }

  /// Post request with authentication
  static Future<http.Response> post(String endpoint, dynamic data, {
    BuildContext? context,
    Map<String, String>? headers,
    Duration timeout = _timeout,
  }) async {
    return _makeRequest(
      () { // Define defaultHeaders inside the lambda to capture latest _token
        final defaultHeaders = {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        };
        return http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers ?? defaultHeaders,
          body: json.encode(data),
        );
      },
      timeout: timeout,
      context: context,
    );
  }

  /// Put request with authentication
  static Future<http.Response> put(String endpoint, dynamic data, {
    BuildContext? context,
    Map<String, String>? headers,
    Duration timeout = _timeout,
  }) async {
    return _makeRequest(
      () { // Define defaultHeaders inside the lambda to capture latest _token
        final defaultHeaders = {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        };
        return http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers ?? defaultHeaders,
          body: json.encode(data),
        );
      },
      timeout: timeout,
      context: context,
    );
  }

  /// Patch request with authentication
  static Future<http.Response> patch(String endpoint, dynamic data, {
    BuildContext? context,
    Map<String, String>? headers,
    Duration timeout = _timeout,
  }) async {
    return _makeRequest(
      () { // Define defaultHeaders inside the lambda to capture latest _token
        final defaultHeaders = {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        };
        return http.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers ?? defaultHeaders,
          body: json.encode(data),
        );
      },
      timeout: timeout,
      context: context,
    );
  }

  /// Delete request with authentication
  static Future<http.Response> delete(String endpoint, {
    BuildContext? context,
    Map<String, String>? headers,
    Duration timeout = _timeout,
  }) async {
    return _makeRequest(
      () { // Define defaultHeaders inside the lambda to capture latest _token
        final defaultHeaders = {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        };
        return http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers ?? defaultHeaders,
        );
      },
      timeout: timeout,
      context: context,
    );
  }

  /// Refresh token logic
  static Future<bool> refreshTokenIfNeeded(BuildContext? context) async {
    if (_refreshToken == null) {
      Logger.warning('No refresh token available');
      return false;
    }

    try {
      Logger.info('Attempting to refresh token');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
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

          // Update AuthProvider with new tokens
          if (context != null && context.mounted) {
            context.read<AuthProvider>().updateTokensFromRefresh(newToken, newRefreshToken);
          }
          return true;
        }
      }

      Logger.error('Token refresh failed with response: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      Logger.error('Error during token refresh: $e');
      return false;
    }
  }

  /// Handle unauthorized access
  static Future<void> _handleUnauthorized(BuildContext? context) async {
    Logger.warning('Handling unauthorized access');
    
    // Only clear tokens if refresh token is also invalid
    if (context != null && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.auth != null) {
        // Try to refresh token first
        final refreshSuccess = await refreshTokenIfNeeded(context);
        if (!refreshSuccess) {
          // Only logout if refresh failed
          await handleUnauthorized(context);
        }
      }
    }
  }

  /// Test the connection to the backend server
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      Logger.info('Testing connection to backend server at: $baseUrl');
      
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

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
        Logger.error('Backend connection failed: ${response.statusCode} - ${response.body}');
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

  static Future<void> handleUnauthorized(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (context.mounted) {
      context.go('/login');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

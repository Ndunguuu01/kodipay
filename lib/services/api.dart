import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:provider/provider.dart';
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

  // Flags to prevent multiple simultaneous refresh attempts
  static bool _refreshingToken = false;
  static bool _isRefreshing = false;

  // Getters
  static bool get isConnected => _isConnected;
  static DateTime? get lastConnectionCheck => _lastConnectionCheck;

  static String get baseUrl {
    // Use local backend address for local testing
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

  // Flag to track if we're currently refreshing the token
  // Using the existing _refreshingToken flag declared above
  
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
    bool tokenRefreshed = false;

    while (true) {
      try {
        // Test connection before making request if we haven't checked recently
        if (!_isConnected || DateTime.now().difference(_lastConnectionCheck ?? DateTime(2000)).inMinutes > 5) {
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
        
        // Log the request details (only in debug mode)
        Logger.info('Making request to: $baseUrl');
        Logger.info('Headers: ${currentHeaders.toString().replaceAll(_token ?? '', 'TOKEN_HIDDEN')}');

        // Make the request
        response = await request().timeout(timeout);

        // Log the response (only status code and truncated body for security)
        Logger.info('Response status: ${response.statusCode}');
        final bodyPreview = response.body.length > 100 
            ? '${response.body.substring(0, 100)}... (truncated)' 
            : response.body;
        Logger.info('Response body preview: $bodyPreview');

        // Update connection status
        // Update connection status
        _isConnected = true;
        _lastConnectionCheck = DateTime.now();
        try {
          await _updateLastConnectionCheck();
        } catch (e) {
          Logger.error('Error updating last connection check: $e');
        }

        // Handle unauthorized access (401)
        if (response.statusCode == 401) {
          Logger.warning('Received 401 response, attempting token refresh');

          // Only try to refresh token once per request chain
          if (tokenRefreshed) {
            Logger.error('Already refreshed token once during this request chain, giving up');
            await _handleUnauthorized(context);
            return response;
          }

          // Prevent multiple simultaneous refresh attempts
          if (_refreshingToken) {
            Logger.warning('Token refresh already in progress, waiting...');
            // Wait for the current refresh to complete
            for (int i = 0; i < 10; i++) { // Wait up to 5 seconds
              await Future.delayed(const Duration(milliseconds: 500));
              if (!_refreshingToken) break;
            }
            
            // If we have a token after waiting, retry the request
            if (_token != null && retryCount < maxRetries) {
              Logger.info('Token available after waiting, retrying request');
              retryCount++;
              tokenRefreshed = true;
              continue;
            } else {
              Logger.error('No token available after waiting or max retries reached');
              await _handleUnauthorized(context);
              return response;
            }
          }

          // Try to refresh the token
          _refreshingToken = true;
          try {
            final refreshSuccess = await refreshTokenIfNeeded(context);
            if (refreshSuccess && retryCount < maxRetries) {
              Logger.info('Token refreshed successfully, retrying request with new token');
              retryCount++;
              tokenRefreshed = true;
              await Future.delayed(retryDelay);
              continue;
            } else {
              Logger.error('Token refresh failed or max retries reached');
              await _handleUnauthorized(context);
              return response;
            }
          } finally {
            _refreshingToken = false;
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

    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      Logger.info('Token refresh already in progress, waiting...');
      // Wait for the current refresh to complete
      await Future.delayed(const Duration(milliseconds: 500));
      return _token != null; // Return true if we have a token after waiting
    }

    _isRefreshing = true;
    try {
      Logger.info('Attempting to refresh token');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> responseData = data['data'] ?? data;
        
        final newToken = responseData['token'];
        final newRefreshToken = responseData['refreshToken'];

        if (newToken != null && newRefreshToken != null) {
          await setAuthToken(newToken);
          await setRefreshToken(newRefreshToken);
          Logger.info('Token refreshed successfully');

          // Update AuthProvider with new tokens
          if (context != null && context.mounted) {
            try {
              context.read<AuthProvider>().updateTokensFromRefresh(newToken, newRefreshToken);
            } catch (e) {
              Logger.error('Error updating AuthProvider with new tokens: $e');
              // Continue even if this fails, as we've already updated the tokens in storage
            }
          }
          return true;
        } else {
          Logger.error('Token refresh response missing token or refreshToken: $responseData');
        }
      } else {
        Logger.error('Token refresh failed with response: ${response.statusCode} - ${response.body}');
      }
      return false;
    } catch (e) {
      Logger.error('Error during token refresh: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Handle unauthorized access
  static Future<void> _handleUnauthorized(BuildContext? context) async {
    Logger.warning('Handling unauthorized access');
    
    // If we don't have a context, we can't use the AuthProvider
    if (context == null || !context.mounted) {
      Logger.warning('No valid context provided to _handleUnauthorized, clearing tokens directly');
      await setAuthToken(null);
      await setRefreshToken(null);
      return;
    }
    
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.auth != null) {
        // We've already tried to refresh the token in the _makeRequest method,
        // so we can just log out the user here
        Logger.info('Logging out user due to authentication failure');
        await handleUnauthorized(context);
      } else {
        Logger.info('User already logged out');
      }
    } catch (e) {
      Logger.error('Error in _handleUnauthorized: $e');
      // Fallback to direct token clearing
      await setAuthToken(null);
      await setRefreshToken(null);
    }
  }

  /// Test the connection to the backend server
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final url = baseUrl;
      Logger.info('Testing connection to backend server at: $url');
      
      final response = await http.get(
        Uri.parse('$url/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Update connection status
        _isConnected = true;
        _lastConnectionCheck = DateTime.now();
        try {
          await _updateLastConnectionCheck();
        } catch (e) {
          Logger.error('Error updating last connection check: $e');
        }

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
    try {
      Logger.info('ApiService.handleUnauthorized: Logging out user');
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      
      // Navigate to login screen with a slight delay to allow logout to complete
      if (context.mounted) {
        // Add a small delay to prevent rapid redirects
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          Logger.info('ApiService.handleUnauthorized: Redirecting to login screen');
          context.go('/login');
        }
      }
    } catch (e) {
      Logger.error('Error in handleUnauthorized: $e');
      // Fallback to direct token clearing
      await setAuthToken(null);
      await setRefreshToken(null);
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

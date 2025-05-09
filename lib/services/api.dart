import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.102:5000/api';
  static String? _token;
  static String? _refreshToken;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Initialize the token and refresh token from storage
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    print('ApiService initialized with token: ${_token != null ? 'Token exists' : 'No token'}');
  }

  /// Set the access token
  static Future<void> setAuthToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
      print('Auth token set successfully');
    } else {
      await prefs.remove(_tokenKey);
      print('Auth token cleared');
    }
  }

  /// Set the refresh token
  static Future<void> setRefreshToken(String? token) async {
    _refreshToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_refreshTokenKey, token);
      print('Refresh token set successfully');
    } else {
      await prefs.remove(_refreshTokenKey);
      print('Refresh token cleared');
    }
  }

  /// Clear tokens on logout or failure
  static Future<void> clearAuthToken() async => await setAuthToken(null);
  static Future<void> clearRefreshToken() async => await setRefreshToken(null);

  static Future<http.Response> get(String endpoint, {BuildContext? context}) async {
    // Ensure token is initialized
    await initialize();

    if (_token == null) {
      print('No token found when making GET request to $endpoint');
      throw UnauthorizedException('No token found. Please login first.');
    }

    final url = Uri.parse('$baseUrl$endpoint');
    print('Making GET request to: $url');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    try {
      final response = await http.get(url, headers: headers);
      print('GET response status: ${response.statusCode}');
      print('GET response body: ${response.body}');

      if (response.statusCode == 401 && context != null) {
        print('GET Unauthorized - attempting refresh...');
        final refreshed = await _refreshTokenIfNeeded(context);
        if (refreshed) {
          return await get(endpoint, context: context); // Retry with new token
        } else {
          await _handleUnauthorized(context);
          throw UnauthorizedException('Session expired. Please log in again.');
        }
      }
      return response;
    } catch (e) {
      print('Error making GET request to $endpoint: $e');
      rethrow;
    }
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    BuildContext? context,
    Map<String, String> headers = const {
      'Content-Type': 'application/json',
    },
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('Making POST request to: $url');
    print('Request body: $body');

    final requestHeaders = Map<String, String>.from(headers);
    if (_token != null) {
      requestHeaders['Authorization'] = 'Bearer $_token';
    }

    try {
      final response = await http.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(body),
      );
      print('POST response status: ${response.statusCode}');
      print('POST response body: ${response.body}');
      return response;
    } catch (e) {
      print('Error making POST request to $endpoint: $e');
      rethrow;
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {BuildContext? context, required Map<String, String> headers}) async {
    return _request('PUT', endpoint, body: body, context: context);
  }

  static Future<http.Response> delete(String endpoint, {BuildContext? context}) async {
    return _request('DELETE', endpoint, context: context);
  }

  /// Unified request handler
  static Future<http.Response> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    BuildContext? context,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('Making $method request to: $url');
    if (body != null) {
      print('Request body: $body');
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    try {
      http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('$method response status: ${response.statusCode}');
      print('$method response body: ${response.body}');

      if (response.statusCode == 401) {
        print('Unauthorized - attempting refresh...');
        final refreshed = await _refreshTokenIfNeeded(context);
        if (refreshed) {
          return await _request(method, endpoint, body: body, context: context);
        } else {
          await _handleUnauthorized(context);
          throw UnauthorizedException('Session expired. Please log in again.');
        }
      }

      return response;
    } catch (e) {
      print('Error on $method $endpoint: $e');
      rethrow;
    }
  }

  /// Refresh token logic
  static Future<bool> _refreshTokenIfNeeded(BuildContext? context) async {
    if (_refreshToken == null) {
      print('No refresh token available');
      return false;
    }

    final url = Uri.parse('$baseUrl/auth/refresh');
    try {
      print('Attempting to refresh token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      print('Refresh token response status: ${response.statusCode}');
      print('Refresh token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken'];

        if (newToken != null && newRefreshToken != null) {
          await setAuthToken(newToken);
          await setRefreshToken(newRefreshToken);
          print('Token refreshed successfully');
          return true;
        }
      }

      print('Token refresh failed with response: ${response.body}');
      return false;
    } catch (e) {
      print('Error during token refresh: $e');
      return false;
    }
  }

  /// Handle logout on invalid/expired token
  static Future<void> _handleUnauthorized(BuildContext? context) async {
    print('Handling unauthorized access');
    await clearAuthToken();
    await clearRefreshToken();

    if (context != null && context.mounted) {
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

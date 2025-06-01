import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kodipay/models/property.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/services/api.dart';
import 'package:kodipay/utils/logger.dart';

/// Service class for handling all property-related operations
class PropertyService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  final String baseUrl = ApiService.baseUrl;

  /// Helper method to get authentication token
  /// Throws [AuthException] if token is not available
  Future<String> _getAuthToken(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;
      if (token == null) {
        throw AuthException('Token is missing, please log in again.');
      }
      return token;
    } catch (e) {
      Logger.error('Error getting auth token: $e');
      rethrow;
    }
  }

  /// Helper method to make HTTP requests with retry logic
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    int retryCount = 0,
  }) async {
    try {
      final response = await request();
      if (response.statusCode >= 500 && retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return _makeRequest(request, retryCount: retryCount + 1);
      }
      return response;
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return _makeRequest(request, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  /// Add a new property
  /// Throws [PropertyException] if operation fails
  Future<void> addProperty(BuildContext context, PropertyModel property) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Adding new property: ${property.name}');

      final response = await _makeRequest(() => http.post(
            Uri.parse('$baseUrl/properties'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(property.toJson()),
          ));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PropertyException('Failed to add property: ${response.statusCode}');
      }
      Logger.info('Property added successfully: ${property.name}');
    } catch (e) {
      Logger.error('Error adding property: $e');
      throw PropertyException('Failed to add property: $e');
    }
  }

  /// Get all properties for a landlord
  /// Returns empty list if no properties found
  Future<List<PropertyModel>> getProperties(BuildContext context) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Fetching properties for landlord');

      final response = await _makeRequest(() => http.get(
            Uri.parse('$baseUrl/properties/landlord'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final properties = data.map((json) => PropertyModel.fromJson(json)).toList();
        Logger.info('Successfully fetched ${properties.length} properties');
        return properties;
      } else {
        throw PropertyException('Failed to fetch properties: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error fetching properties: $e');
      throw PropertyException('Failed to fetch properties: $e');
    }
  }

  /// Get property details by ID
  /// Throws [PropertyException] if property not found
  Future<PropertyModel> getPropertyDetails(BuildContext context, String propertyId) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Fetching details for property: $propertyId');

      final response = await _makeRequest(() => http.get(
            Uri.parse('$baseUrl/properties/$propertyId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode == 200) {
        final property = PropertyModel.fromJson(json.decode(response.body));
        Logger.info('Successfully fetched property details: ${property.name}');
        return property;
      } else {
        throw PropertyException('Failed to fetch property details: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error fetching property details: $e');
      throw PropertyException('Failed to fetch property details: $e');
    }
  }

  /// Update property details
  /// Throws [PropertyException] if update fails
  Future<void> updateProperty(BuildContext context, PropertyModel property) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Updating property: ${property.name}');

      final response = await _makeRequest(() => http.put(
            Uri.parse('$baseUrl/properties/${property.id}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(property.toJson()),
          ));

      if (response.statusCode != 200) {
        throw PropertyException('Failed to update property: ${response.statusCode}');
      }
      Logger.info('Property updated successfully: ${property.name}');
    } catch (e) {
      Logger.error('Error updating property: $e');
      throw PropertyException('Failed to update property: $e');
    }
  }

  /// Delete property
  /// Throws [PropertyException] if deletion fails
  Future<void> deleteProperty(BuildContext context, String propertyId) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Deleting property: $propertyId');

      final response = await _makeRequest(() => http.delete(
            Uri.parse('$baseUrl/properties/$propertyId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode != 200) {
        throw PropertyException('Failed to delete property: ${response.statusCode}');
      }
      Logger.info('Property deleted successfully: $propertyId');
    } catch (e) {
      Logger.error('Error deleting property: $e');
      throw PropertyException('Failed to delete property: $e');
    }
  }

  /// Assign tenant to room
  /// Throws [PropertyException] if assignment fails
  Future<void> assignTenantToRoom(
    BuildContext context,
    String propertyId,
    String roomId,
    String tenantId,
  ) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Assigning tenant $tenantId to room $roomId in property $propertyId');

      final response = await _makeRequest(() => http.post(
            Uri.parse('$baseUrl/properties/$propertyId/rooms/$roomId/assign'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'tenantId': tenantId}),
          ));

      if (response.statusCode != 200) {
        throw PropertyException('Failed to assign tenant: ${response.statusCode}');
      }
      Logger.info('Tenant assigned successfully');
    } catch (e) {
      Logger.error('Error assigning tenant: $e');
      throw PropertyException('Failed to assign tenant: $e');
    }
  }

  /// Unassign tenant from room
  /// Throws [PropertyException] if unassignment fails
  Future<void> unassignTenantFromRoom(
    BuildContext context,
    String propertyId,
    String roomId,
  ) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Unassigning tenant from room $roomId in property $propertyId');

      final response = await _makeRequest(() => http.post(
            Uri.parse('$baseUrl/properties/$propertyId/rooms/$roomId/unassign'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode != 200) {
        throw PropertyException('Failed to unassign tenant: ${response.statusCode}');
      }
      Logger.info('Tenant unassigned successfully');
    } catch (e) {
      Logger.error('Error unassigning tenant: $e');
      throw PropertyException('Failed to unassign tenant: $e');
    }
  }

  /// Get room status including occupancy and payment information
  /// Returns null if room not found
  Future<Map<String, dynamic>?> getRoomStatus(
    BuildContext context,
    String propertyId,
    String roomId,
  ) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Getting status for room $roomId in property $propertyId');

      final response = await _makeRequest(() => http.get(
            Uri.parse('$baseUrl/properties/$propertyId/rooms/$roomId/status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Logger.info('Successfully fetched room status');
        return data;
      } else if (response.statusCode == 404) {
        Logger.warning('Room not found: $roomId');
        return null;
      } else {
        throw PropertyException('Failed to get room status: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error getting room status: $e');
      throw PropertyException('Failed to get room status: $e');
    }
  }

  /// Get property statistics including bill information
  /// Throws [PropertyException] if statistics cannot be fetched
  Future<Map<String, dynamic>> getPropertyStatistics(BuildContext context, String propertyId) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Getting statistics for property $propertyId');

      final response = await _makeRequest(() => http.get(
            Uri.parse('$baseUrl/properties/$propertyId/statistics'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Logger.info('Successfully fetched property statistics');
        return data;
      } else {
        throw PropertyException('Failed to fetch property statistics: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error fetching property statistics: $e');
      throw PropertyException('Failed to fetch property statistics: $e');
    }
  }

  /// Get property bills summary with optional date range
  /// Throws [PropertyException] if summary cannot be fetched
  Future<Map<String, dynamic>> getPropertyBillsSummary(
    BuildContext context,
    String propertyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Getting bills summary for property $propertyId');

      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _makeRequest(() => http.get(
            Uri.parse('$baseUrl/properties/$propertyId/bills/summary?$queryString'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Logger.info('Successfully fetched property bills summary');
        return data;
      } else {
        throw PropertyException('Failed to fetch property bills summary: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error fetching property bills summary: $e');
      throw PropertyException('Failed to fetch property bills summary: $e');
    }
  }

  /// Get property occupancy rate
  /// Returns 0.0 if property not found
  Future<double> getPropertyOccupancyRate(BuildContext context, String propertyId) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Getting occupancy rate for property $propertyId');

      final response = await _makeRequest(() => http.get(
            Uri.parse('$baseUrl/properties/$propertyId/occupancy-rate'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = data['occupancyRate'].toDouble();
        Logger.info('Successfully fetched occupancy rate: $rate');
        return rate;
      } else if (response.statusCode == 404) {
        Logger.warning('Property not found: $propertyId');
        return 0.0;
      } else {
        throw PropertyException('Failed to get property occupancy rate: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error getting property occupancy rate: $e');
      throw PropertyException('Failed to get property occupancy rate: $e');
    }
  }

  /// Get property payment collection rate with optional date range
  /// Returns 0.0 if no bills found
  Future<double> getPropertyPaymentCollectionRate(
    BuildContext context,
    String propertyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _getAuthToken(context);
      Logger.info('Getting payment collection rate for property $propertyId');

      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _makeRequest(() => http.get(
            Uri.parse('$baseUrl/properties/$propertyId/payment-collection-rate?$queryString'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = data['collectionRate'].toDouble();
        Logger.info('Successfully fetched payment collection rate: $rate');
        return rate;
      } else if (response.statusCode == 404) {
        Logger.warning('No bills found for property: $propertyId');
        return 0.0;
      } else {
        throw PropertyException('Failed to get property payment collection rate: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error getting property payment collection rate: $e');
      throw PropertyException('Failed to get property payment collection rate: $e');
    }
  }
}

/// Custom exception class for property-related errors
class PropertyException implements Exception {
  final String message;
  PropertyException(this.message);

  @override
  String toString() => 'PropertyException: $message';
}

/// Custom exception class for authentication-related errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}



import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kodipay/models/property.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PropertyService {
  final String baseUrl = 'http://192.168.0.102:5000/api';

  Future<void> addProperty(BuildContext context, PropertyModel property) async {
    try {
      // Get the auth token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;

      if (token == null) {
        throw Exception('Token is missing, please log in again.');
      }
      print('Token used for adding property: $token'); // Debugging statement

      final response = await http.post(
        Uri.parse('$baseUrl/properties'), 
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': property.name,
          'address': property.address,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle successful property addition
        print('Property added successfully!');
      } else {
        throw Exception('Failed to add property: ${response.statusCode}');
      }
    } catch (e) {
      // Log the error message
      print('Error adding property: $e');
      throw Exception('Failed to add property');
    }
  }
}

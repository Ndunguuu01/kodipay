import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/lease.dart';

class LeaseProvider with ChangeNotifier {
  Lease? _lease;
  bool _isLoading = false;
  String? _error;

  Lease? get lease => _lease;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches the lease for the authenticated user's tenant ID.
  Future<void> fetchLease(String tenantId) async {
    _setLoading(true);
    _error = null;

    try {
      final String endpoint = '/leases/tenant/$tenantId';
      print('Fetching lease from endpoint: $endpoint');
      
      final response = await ApiService.get(endpoint);
      print('Fetch lease response status: ${response.statusCode}');
      print('Fetch lease response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          _lease = Lease.fromJson(data);
          _error = null;
        } else {
          _setError('Invalid lease data format.');
        }
      } else if (response.statusCode == 404) {
        _setError('No lease found for this tenant.');
      } else if (response.statusCode == 401) {
        _setError('Authentication failed. Please log in again.');
      } else {
        _setError('Failed to fetch lease: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching lease: $e');
      _setError('Error fetching lease: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}
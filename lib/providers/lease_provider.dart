import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api.dart';
import 'package:kodipay/models/lease_model.dart';

class LeaseProvider with ChangeNotifier {
  List<LeaseModel> _leases = [];
  bool _isLoading = false;
  String? _error;

  List<LeaseModel> get leases => _leases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches the lease for the authenticated user's tenant ID.
  Future<void> fetchLease(String tenantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String endpoint = '/leases/tenant/$tenantId';
      print('Fetching lease from endpoint: $endpoint');
      
      final response = await ApiService.get(endpoint);
      print('Fetch lease response status: ${response.statusCode}');
      print('Fetch lease response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          _leases.add(LeaseModel.fromJson(data));
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeases(String userId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/leases/tenant/$userId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _leases = data.map((json) => LeaseModel.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch leases';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createLease(LeaseModel lease) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/leases', lease.toJson());

      if (response.statusCode == 201) {
        final newLease = LeaseModel.fromJson(json.decode(response.body));
        _leases.add(newLease);
      } else {
        _error = 'Failed to create lease';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLease(String id, LeaseModel lease) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put('/leases/$id', lease.toJson());

      if (response.statusCode == 200) {
        final updatedLease = LeaseModel.fromJson(json.decode(response.body));
        final index = _leases.indexWhere((l) => l.id == id);
        if (index != -1) {
          _leases[index] = updatedLease;
        }
      } else {
        _error = 'Failed to update lease';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLease(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('/leases/$id');

      if (response.statusCode == 200) {
        _leases.removeWhere((lease) => lease.id == id);
      } else {
        _error = 'Failed to delete lease';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}
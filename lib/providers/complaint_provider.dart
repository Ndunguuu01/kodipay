import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/services/api.dart';
import 'package:kodipay/models/complaint.dart';

class ComplaintProvider with ChangeNotifier {
  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Method to fetch tenant complaints
  Future<void> fetchComplaints(String userId, BuildContext context) async {
    _setLoadingState(true);
    try {
      final response = await ApiService.get('/complaints/tenant/$userId', context: context, headers: {});
      if (response.statusCode == 200) {
        _complaints = _parseComplaints(response.body);
      } else {
        _setError('Failed to fetch complaints');
      }
    } catch (e) {
      _setError('Error fetching complaints: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  // Method to fetch landlord complaints
  Future<void> fetchLandlordComplaints(String landlordId, BuildContext context) async {
    _setLoadingState(true);
    try {
      final response = await ApiService.get('/complaints/landlord/$landlordId', context: context, headers: {});
      if (response.statusCode == 200) {
        _complaints = _parseComplaints(response.body);
      } else {
        // Log response body for debugging
        print('Failed to fetch landlord complaints. Status: \${response.statusCode}, Body: \${response.body}');
        _setError('Failed to fetch landlord complaints');
      }
    } catch (e) {
      print('Exception fetching landlord complaints: \$e');
      _setError('Error fetching landlord complaints: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  // Method to submit a new complaint
  Future<void> submitComplaint(String title, String description, String tenantId, String propertyId, BuildContext context) async {
    _setLoadingState(true);
    try {
      final response = await ApiService.post(
        '/complaints',
         {
          'title': title,
          'description': description,
          'tenant': tenantId,
          'property': propertyId,
        },
        context: context,
      );
      if (response.statusCode == 201) {
        final newComplaint = ComplaintModel.fromJson(jsonDecode(response.body));
        _complaints.add(newComplaint);
      } else {
        _setError('Failed to submit complaint');
      }
    } catch (e) {
      _setError('Error submitting complaint: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  // Method to update complaint status
  Future<void> updateComplaintStatus(String complaintId, String status, BuildContext context) async {
    _setLoadingState(true);
    try {
      final response = await ApiService.put(
        '/complaints/$complaintId',
         {'status': status},
        context: context, headers: {},
      );
      if (response.statusCode == 200) {
        final updatedComplaint = ComplaintModel.fromJson(jsonDecode(response.body));
        _updateComplaintInList(complaintId, updatedComplaint);
      } else {
        _setError('Failed to update complaint status');
      }
    } catch (e) {
      _setError('Error updating complaint status: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  // Method to edit an existing complaint
  Future<void> editComplaint(String complaintId, String title, String description, BuildContext context) async {
    _setLoadingState(true);
    try {
      final response = await ApiService.put(
        '/complaints/$complaintId',
        {'title': title, 'description': description},
        context: context, headers: {},
      );
      if (response.statusCode == 200) {
        final updatedComplaint = ComplaintModel.fromJson(jsonDecode(response.body));
        _updateComplaintInList(complaintId, updatedComplaint);
      } else {
        _setError('Failed to edit complaint');
      }
    } catch (e) {
      _setError('Error editing complaint: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  // Method to delete a complaint
  Future<void> deleteComplaint(String complaintId, BuildContext context) async {
    _setLoadingState(true);
    try {
      final response = await ApiService.delete('/complaints/$complaintId', context: context);
      if (response.statusCode == 200) {
        _complaints.removeWhere((c) => c.id == complaintId);
      } else {
        _setError('Failed to delete complaint');
      }
    } catch (e) {
      _setError('Error deleting complaint: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  // Private helper methods for error handling and state updates

  // Set the loading state and notify listeners
  void _setLoadingState(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  // Set the error message and notify listeners
  void _setError(String errorMessage) {
    _errorMessage = errorMessage;
    notifyListeners();
  }

  // Helper method to parse complaints from response body
  List<ComplaintModel> _parseComplaints(String responseBody) {
    final List<dynamic> complaintsJson = jsonDecode(responseBody);
    return complaintsJson.map((json) => ComplaintModel.fromJson(json)).toList();
  }

  // Helper method to update a complaint in the list
  void _updateComplaintInList(String complaintId, ComplaintModel updatedComplaint) {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      _complaints[index] = updatedComplaint;
    }
  }

  // Clear the error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all complaints and reset the error message
  void clearComplaints() {
    _complaints = [];
    _errorMessage = null;
    notifyListeners();
  }
}

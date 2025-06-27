import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/models/complaint_model.dart';
import 'package:kodipay/services/api.dart';

class ComplaintProvider with ChangeNotifier {
  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;
  String? _error;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchComplaints() async {
    _setLoading(true);
    try {
      final response = await ApiService.get('/complaints');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _complaints = data.map((json) => ComplaintModel.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to fetch complaints: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _error = 'Error fetching complaints: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createComplaint({
    required String title,
    required String description,
    required String propertyId,
    String? roomId,
    String? priority,
    String? category,
  }) async {
    _setLoading(true);
    try {
      final payload = {
        'title': title,
        'description': description,
        'propertyId': propertyId,
        if (roomId != null) 'roomId': roomId,
        if (priority != null) 'priority': priority,
        if (category != null) 'category': category,
      };

      final response = await ApiService.post('/complaints', payload);
      if (response.statusCode == 201) {
        final complaintData = jsonDecode(response.body);
        final newComplaint = ComplaintModel.fromJson(complaintData['data'] ?? complaintData);
        _complaints.add(newComplaint);
        _error = null;
      } else {
        _error = 'Failed to create complaint: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _error = 'Error creating complaint: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateComplaintStatus(String complaintId, String newStatus) async {
    try {
      final payload = {'status': newStatus};
      final response = await ApiService.patch('/complaints/$complaintId', payload);
      
      if (response.statusCode == 200) {
        final complaintData = jsonDecode(response.body);
        final updatedComplaint = ComplaintModel.fromJson(complaintData['data'] ?? complaintData);
        
        final index = _complaints.indexWhere((c) => c.id == complaintId);
        if (index != -1) {
          _complaints[index] = updatedComplaint;
          notifyListeners();
        }
        _error = null;
      } else {
        _error = 'Failed to update complaint status: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _error = 'Error updating complaint status: $e';
    }
  }

  Future<void> deleteComplaint(String complaintId) async {
    try {
      final response = await ApiService.delete('/complaints/$complaintId');
      if (response.statusCode == 200) {
        _complaints.removeWhere((c) => c.id == complaintId);
        notifyListeners();
        _error = null;
      } else {
        _error = 'Failed to delete complaint: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _error = 'Error deleting complaint: $e';
    }
  }

  ComplaintModel? getComplaintById(String id) {
    try {
      return _complaints.firstWhere((complaint) => complaint.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ComplaintModel> getComplaintsByStatus(String status) {
    return _complaints.where((complaint) => complaint.status == status).toList();
  }

  List<ComplaintModel> getComplaintsByProperty(String propertyId) {
    return _complaints.where((complaint) => complaint.propertyId == propertyId).toList();
  }

  void clearComplaints() {
    _complaints = [];
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }
}

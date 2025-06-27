import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:kodipay/models/bill_model.dart';
import 'package:kodipay/services/api.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class Bill {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String status;
  final String tenantId;

  Bill({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.status,
    required this.tenantId,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      status: json['status'],
      tenantId: json['tenantId'],
    );
  }
}

class BillProvider with ChangeNotifier {
  String? _userId;
  List<BillModel> _bills = [];
  List<BillModel> _tenantBills = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BillModel> get bills => _bills;
  List<BillModel> get tenantBills => _tenantBills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set userId for landlord
  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  // Fetch tenant bills
  Future<List<BillModel>> fetchTenantBills(String tenantId, BuildContext? context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context!, listen: false);
      final token = authProvider.auth?.token;

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      await ApiService.setAuthToken(token);
      final response = await ApiService.get('/bills/tenant/$tenantId', context: context);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _tenantBills = data.map((json) => BillModel.fromJson(json)).toList();
        return _tenantBills;
      } else {
        final errorMessage = json.decode(response.body)['message'] ?? 'Unknown error';
        _error = 'Failed to fetch tenant bills: $errorMessage';
        return [];
      }
    } catch (e) {
      _error = 'Error fetching tenant bills: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add single bill
  Future<void> addBill(BillModel bill, BuildContext? context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/bills',
        bill.toJson(),
        context: context,
      );

      if (response.statusCode == 201) {
        final newBill = BillModel.fromJson(json.decode(response.body));
        _bills.add(newBill);
      } else {
        _error = 'Failed to create bill: ${response.statusCode}';
        throw Exception(_error);
      }
    } catch (e) {
      _error = 'Error creating bill: $e';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create property-wide bills
  Future<void> createPropertyBills({
    required String propertyId,
    required BillType type,
    required double amount,
    required DateTime dueDate,
    BuildContext? context,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/bills/property/$propertyId/bills/bulk',
        {
          'type': type.toString().split('.').last,
          'amount': amount,
          'dueDate': dueDate.toIso8601String(),
          'landlordId': _userId,
          'tenantId': '',
        },
        context: context,
      );

      if (response.statusCode != 201) {
        _error = 'Failed to create property bills: ${response.statusCode}';
        throw Exception(_error);
      }
    } catch (e) {
      _error = 'Error creating property bills: $e';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all bills for the landlord
  Future<List<BillModel>> fetchAllBills(BuildContext? context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context!, listen: false);
      final token = authProvider.auth?.token;

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      await ApiService.setAuthToken(token);
      final response = await ApiService.get('/bills', context: context);

      if (response.statusCode == 200) {
        final List<dynamic> billsJson = json.decode(response.body);
        _bills = billsJson.map((json) => BillModel.fromJson(json)).toList();
        return _bills;
      } else {
        final errorMessage = json.decode(response.body)['message'] ?? 'Unknown error';
        _error = 'Failed to fetch bills: $errorMessage';
        return [];
      }
    } catch (e) {
      _error = 'Error fetching bills: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<BillModel>> fetchFilteredBills({
    String? type,
    String? status,
    String? tenantId,
    DateTime? startDate,
    DateTime? endDate,
    BuildContext? context,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context!, listen: false);
      final token = authProvider.auth?.token;

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      if (tenantId != null) queryParams['tenantId'] = tenantId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      await ApiService.setAuthToken(token);
      final response = await ApiService.get('/bills/filter?$queryString', context: context);

      if (response.statusCode == 200) {
        final List<dynamic> billsJson = json.decode(response.body);
        _bills = billsJson.map((json) => BillModel.fromJson(json)).toList();
        return _bills;
      } else {
        final errorMessage = json.decode(response.body)['message'] ?? 'Unknown error';
        _error = 'Failed to fetch filtered bills: $errorMessage';
        return [];
      }
    } catch (e) {
      _error = 'Error fetching filtered bills: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get bill statistics
  Future<Map<String, dynamic>> getBillStatistics(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.auth?.token;

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      await ApiService.setAuthToken(token);
      final response = await ApiService.get('/bills/statistics', context: context);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorMessage = json.decode(response.body)['message'] ?? 'Unknown error';
        _error = 'Failed to fetch bill statistics: $errorMessage';
        return {};
      }
    } catch (e) {
      _error = 'Error fetching bill statistics: $e';
      return {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get bills by date range
  Future<List<BillModel>> getBillsByDateRange(
    DateTime startDate,
    DateTime endDate,
    BuildContext context,
  ) async {
    return fetchFilteredBills(
      startDate: startDate,
      endDate: endDate,
      context: context,
    );
  }

  // Get bills by status
  Future<List<BillModel>> getBillsByStatus(
    BillStatus status,
    BuildContext context,
  ) async {
    return fetchFilteredBills(
      status: status.name,
      context: context,
    );
  }

  // Get bills by type
  Future<List<BillModel>> getBillsByType(
    BillType type,
    BuildContext context,
  ) async {
    return fetchFilteredBills(
      type: type.toString().split('.').last,
      context: context,
    );
  }

  // Get bills by tenant
  Future<List<BillModel>> getBillsByTenant(
    String tenantId,
    BuildContext context,
  ) async {
    return fetchFilteredBills(
      tenantId: tenantId,
      context: context,
    );
  }

  // Alias for UI compatibility
  Future<List<BillModel>> fetchBills(BuildContext? context) => fetchAllBills(context);

  void clearBills() {
    _bills = [];
    _error = null;
    notifyListeners();
  }

  // Update bill
  Future<void> updateBill(BillModel bill, BuildContext? context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.put(
        '/bills/${bill.id}',
        bill.toJson(),
        context: context,
      );

      if (response.statusCode == 200) {
        final updatedBill = BillModel.fromJson(json.decode(response.body));
        final index = _bills.indexWhere((b) => b.id == bill.id);
        if (index != -1) {
          _bills[index] = updatedBill;
        }
      } else {
        _error = 'Failed to update bill: ${response.statusCode}';
        throw Exception(_error);
      }
    } catch (e) {
      _error = 'Error updating bill: $e';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new bill
  Future<bool> createNewBill({
    required String tenantId,
    required double amount,
    required String description,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.setAuthToken(token);
      final response = await ApiService.post(
        '/bills',
        {
          'tenantId': tenantId,
          'amount': amount,
          'description': description,
          'date': DateTime.now().toIso8601String(),
          'status': 'pending',
        },
      );

      if (response.statusCode == 201) {
        final bill = BillModel.fromJson(jsonDecode(response.body));
        _bills.add(bill);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create bill: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Error creating bill: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBillStatus({
    required String billId,
    required String status,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.setAuthToken(token);
      final response = await ApiService.put(
        '/bills/$billId/status',
        {
          'status': status,
        },
      );

      if (response.statusCode == 200) {
        final updatedBill = BillModel.fromJson(jsonDecode(response.body));
        final index = _bills.indexWhere((b) => b.id == billId);
        if (index != -1) {
          _bills[index] = updatedBill;
          notifyListeners();
        }
        return true;
      } else {
        _error = 'Failed to update bill status: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Error updating bill status: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:kodipay/models/bill_model.dart';
import 'package:kodipay/services/bill_service.dart';

class BillProvider with ChangeNotifier {
  final BillService _billService = BillService();
  List<BillModel> _bills = [];
  List<BillModel> get bills => _bills;
  List<BillModel> tenantBills = [];
  bool isLoading = false;
  String? errorMessage;
  

  Future<void> fetchBills({
    required String token,
    required String landlordId,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? tenantName,
  }) async {
    notifyListeners();

    try {
      _bills = await _billService.fetchBills(
        token: token,
        landlordId: landlordId,
        status: status,
        type: type,
        startDate: startDate,
        endDate: endDate,
        tenantName: tenantName,
      );
    } catch (e) {
      print('Error in BillProvider fetchBills: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> addBill(BillModel bill, String token) async {
    try {
      isLoading = true;
      notifyListeners();

      await _billService.addBill(bill, token);
      _bills.add(bill); // Optionally re-fetch instead
      notifyListeners();
    } catch (e) {
      print('Error adding bill: $e');
      rethrow;
    }
  }

  Future<void> markBillAsPaid(String billId, String token) async {
    try {
      isLoading = true;
      notifyListeners();

      await _billService.markBillAsPaid(billId, token);
      final index = _bills.indexWhere((bill) => bill.id == billId);
      if (index != -1) {
        _bills[index] = _bills[index].copyWith(status: 'Paid');
        notifyListeners();
      }
    } catch (e) {
      print('Error marking bill as paid: $e');
      rethrow;
    }
  }

  Future<void> fetchTenantBills(String tenantId, String token, BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      tenantBills = await _billService.fetchTenantBills(tenantId, token);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Add this public method for landlord bills screen
  Future<List<BillModel>> fetchTenantBillsFuture(String tenantId, String token) async {
    return await _billService.fetchTenantBills(tenantId, token);
  }

  void fetchFilteredBills(String tenantId, String token, {String? status, String? type, DateTime? startDate, DateTime? endDate, required String tenantName}) {}

  void fetchBillsForTenant(String id) {}

}

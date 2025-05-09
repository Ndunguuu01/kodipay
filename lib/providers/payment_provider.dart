import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kodipay/services/api.dart';
import 'package:kodipay/models/payment_model.dart';

class PaymentProvider with ChangeNotifier {
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPayments(String tenantId, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/payments/$tenantId', context: context);
      if (response.statusCode == 200) {
        final List<dynamic> paymentsJson = jsonDecode(response.body);
        _payments = paymentsJson.map((json) => PaymentModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to fetch payments';
      }
    } catch (e) {
      _errorMessage = 'Error fetching payments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> makePayment(Map<String, dynamic> paymentData, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/payments', paymentData, context: context);
      if (response.statusCode == 201) {
        final newPayment = PaymentModel.fromJson(jsonDecode(response.body));
        _payments.add(newPayment);
      } else {
        _errorMessage = 'Failed to make payment';
      }
    } catch (e) {
      _errorMessage = 'Error making payment: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPayments() {
    _payments = [];
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
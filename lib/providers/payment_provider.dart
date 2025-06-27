import 'package:kodipay/services/api.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class Payment {
  final String id;
  final double amount;
  final DateTime date;
  final String status;
  final String description;
  final String tenantId;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
    required this.status,
    required this.description,
    required this.tenantId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      status: json['status'],
      description: json['description'],
      tenantId: json['tenantId'],
    );
  }
}

class PaymentProvider with ChangeNotifier {
  final List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _error;
  bool _mpesaLoading = false;
  String? _mpesaStatus;
  String? _mpesaError;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get mpesaLoading => _mpesaLoading;
  String? get mpesaStatus => _mpesaStatus;
  String? get mpesaError => _mpesaError;

  Future<void> fetchTenantPayments(String tenantId, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.get('/payments/tenant/$tenantId', context: context);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _payments.clear();
        _payments.addAll(data.map((json) => PaymentModel.fromJson(json)));
      } else {
        _error = 'Failed to fetch payments';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPayment(PaymentModel payment, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.post(
        '/payments',
        payment.toJson(),
        context: context,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _payments.add(PaymentModel.fromJson(data));
      } else {
        _error = 'Failed to create payment';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPayments() {
    _payments.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> initiateMpesaPayment({
    required String phone,
    required double amount,
    String accountReference = 'KodiPay',
    String description = 'App Payment',
    required BuildContext context,
  }) async {
    _mpesaLoading = true;
    _mpesaStatus = null;
    _mpesaError = null;
    notifyListeners();
    try {
      final response = await ApiService.post(
        '/payments/mpesa/stkpush',
        {
          'phone': phone,
          'amount': amount,
          'accountReference': accountReference,
          'description': description,
        },
        context: context,
      );
      if (response.statusCode == 200) {
        _mpesaStatus = 'STK Push sent. Check your phone to complete the payment.';
      } else {
        _mpesaError = 'Failed to initiate M-Pesa payment.';
      }
    } catch (e) {
      _mpesaError = e.toString();
    } finally {
      _mpesaLoading = false;
      notifyListeners();
    }
  }
}
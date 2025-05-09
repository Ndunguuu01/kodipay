import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kodipay/models/bill_model.dart';

class BillService {
  final String baseUrl = 'http://192.168.0.102:5000/api/bills';

  Future<List<BillModel>> fetchBills({
    required String token,
    required String landlordId,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? tenantName,
  }) async {
    try {
      final queryParams = {
        'landlordId': landlordId,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (tenantName != null) 'tenantName': tenantName,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((e) => BillModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load bills');
      }
    } catch (e) {
      print('Error fetching bills: $e');
      rethrow;
    }
  }

  Future<void> addBill(BillModel bill, String token) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(bill.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add bill');
      }
    } catch (e) {
      print('Error adding bill: $e');
      rethrow;
    }
  }

  Future<void> markBillAsPaid(String billId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$billId/pay'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark bill as paid');
      }
    } catch (e) {
      print('Error paying bill: $e');
      rethrow;
    }
  }

  Future<List<BillModel>> fetchTenantBills(String tenantId, String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/bills/tenant/$tenantId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final List jsonList = json.decode(response.body);
    return jsonList.map((json) => BillModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to fetch bills');
  }
}

}

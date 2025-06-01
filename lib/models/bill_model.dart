import 'package:intl/intl.dart';

// Enums
enum BillType {
  rent,
  water,
  electricity,
  maintenance,
  utility,
  other,
}

extension BillTypeExtension on BillType {
  String get displayName {
    switch (this) {
      case BillType.rent:
        return 'Rent';
      case BillType.water:
        return 'Water';
      case BillType.electricity:
        return 'Electricity';
      case BillType.maintenance:
        return 'Maintenance';
      case BillType.utility:
        return 'Utility';
      case BillType.other:
        return 'Other';
    }
  }
}

enum BillStatus {
  pending,
  paid,
  overdue;

  String get displayName => name.toUpperCase();
}

// Model
class BillModel {
  final String id;
  final String tenantId;
  final String propertyId;
  final String? roomId;
  final double amount;
  final BillStatus status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? description;
  final String? receiptNumber;

  BillModel({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    this.roomId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.dueDate,
    this.paidAt,
    this.description,
    this.receiptNumber,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['_id'] ?? json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      propertyId: json['propertyId'] ?? '',
      roomId: json['roomId'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status']),
      paymentMethod: json['paymentMethod'] ?? 'unknown',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      dueDate: DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      description: json['description'],
      receiptNumber: json['receiptNumber'],
    );
  }

  static BillStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'paid':
          return BillStatus.paid;
        case 'overdue':
          return BillStatus.overdue;
        default:
          return BillStatus.pending;
      }
    }
    return BillStatus.pending;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'roomId': roomId,
      'amount': amount,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'description': description,
      'receiptNumber': receiptNumber,
    };
  }

  BillModel copyWith({
    BillStatus? status,
    double? amount,
    DateTime? paidAt,
    DateTime? dueDate,
    String? tenantId,
    String? propertyId,
    String? roomId,
    String? paymentMethod,
    String? description,
    String? receiptNumber,
  }) {
    return BillModel(
      id: id,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      roomId: roomId ?? this.roomId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      description: description ?? this.description,
      receiptNumber: receiptNumber ?? this.receiptNumber,
    );
  }

  // Formatted fields
  String get formattedAmount => NumberFormat.currency(
        symbol: 'KES ',
        decimalDigits: 2,
      ).format(amount);

  String get formattedCreatedDate => DateFormat('MMM dd, yyyy').format(createdAt);
  String get formattedDueDate => DateFormat('MMM dd, yyyy').format(dueDate);

  // Display helpers
  String get statusDisplay => status.displayName;

  String get displayDescription {
    if (description == null) return 'No description';
    final typeName = BillType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() ==
          description!.split(' ').first.toLowerCase(),
      orElse: () => BillType.other,
    ).displayName;
    return '$typeName bill';
  }

  BillType get type {
    if (description == null) return BillType.other;
    return BillType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() ==
          description!.split(' ').first.toLowerCase(),
      orElse: () => BillType.other,
    );
  }
}

class LeaseModel {
  final String id;
  final String tenantId;
  final String propertyId;
  final String roomId;
  final String leaseType;
  final double amount;
  final double balance;
  final double payableAmount;
  final String startDate;
  final String dueDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaseModel({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.roomId,
    required this.leaseType,
    required this.amount,
    required this.balance,
    required this.payableAmount,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaseModel.fromJson(Map<String, dynamic> json) {
    return LeaseModel(
      id: json['_id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      propertyId: json['propertyId'] ?? '',
      roomId: json['roomId'] ?? '',
      leaseType: json['leaseType'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'propertyId': propertyId,
      'roomId': roomId,
      'leaseType': leaseType,
      'amount': amount,
      'balance': balance,
      'payableAmount': payableAmount,
      'startDate': startDate,
      'dueDate': dueDate,
      'status': status,
    };
  }
} 
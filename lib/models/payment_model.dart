class PaymentModel {
  final String id;
  final String tenantId;
  final String leaseId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? transactionId;

  PaymentModel({
    required this.id,
    required this.tenantId,
    required this.leaseId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.transactionId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'],
      tenantId: json['tenantId'],
      leaseId: json['leaseId'],
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentDate: DateTime.parse(json['paymentDate']),
      transactionId: json['transactionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'leaseId': leaseId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate.toIso8601String(),
      if (transactionId != null) 'transactionId': transactionId,
    };
  }
}
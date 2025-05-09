class Lease {
  final String id;
  final String leaseType;
  final double amount;
  final String startDate;
  final String dueDate;
  final double balance;
  final double payableAmount;
  final String propertyId; 

  Lease({
    required this.id,
    required this.leaseType,
    required this.amount,
    required this.startDate,
    required this.dueDate,
    required this.balance,
    required this.payableAmount,
    required this.propertyId, 
  });

  factory Lease.fromJson(Map<String, dynamic> json) {
    return Lease(
      id: json['id'] ?? '',
      leaseType: json['leaseType'] ?? 'Fixed',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0.0,
      propertyId: json['propertyId'] ?? '',
    );
  }
}

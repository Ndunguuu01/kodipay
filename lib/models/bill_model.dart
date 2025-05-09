class BillModel {
  final String id;
  final String type;
  final double amount;
  final String status; 
  final DateTime dueDate;
  final String propertyId;
  final String tenantId;
  final String? propertyName;
  final String? tenantName;

  BillModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.propertyId,
    required this.tenantId,
    this.propertyName,
    this.tenantName,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      dueDate: DateTime.parse(json['dueDate']),
      propertyId: json['property'] is String ? json['property'] : json['property']['_id'],
      tenantId: json['tenant'] is String ? json['tenant'] : json['tenant']['_id'],
      propertyName: json['property'] is Map ? json['property']['name'] : null,
      tenantName: json['tenant'] is Map
          ? '${json['tenant']['firstName']} ${json['tenant']['lastName']}'
          : null,
    );
  }

  get dueDateFormatted => null;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'status': status,
      'dueDate': dueDate.toIso8601String(),
      'property': propertyId,
      'tenant': tenantId,
    };
  }


  BillModel copyWith({
    String? status,
    double? amount,
    DateTime? dueDate,
    String? tenantId,
    String? propertyId,
    String? tenantName,
    String? propertyName,
  }) {
    return BillModel(
      id: this.id,
      type: this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      propertyName: propertyName ?? this.propertyName,
    );
  }
}

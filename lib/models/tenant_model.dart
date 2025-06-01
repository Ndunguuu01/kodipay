class TenantModel {
  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? status;
  final String? paymentStatus;
  final String? propertyId;

  TenantModel({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.status,
    this.paymentStatus, 
    this.propertyId,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'];
    final phoneNumber = json['phoneNumber'];

    if (id == null || phoneNumber == null) {
      // Log error for missing required fields
      print('TenantModel.fromJson error: Missing required fields _id or phoneNumber in JSON: \$json');
    }

    return TenantModel(
      id: id?.toString() ?? 'unknown_id',
      phoneNumber: phoneNumber?.toString() ?? 'unknown_phone',
      firstName: json['firstName'],
      lastName: json['lastName'],
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      propertyId: json['propertyId'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'phoneNumber': phoneNumber,
        'firstName': firstName,
        'lastName': lastName,
        'status': status,
        'paymentStatus': paymentStatus,
      };

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  get nationalId => null;
}

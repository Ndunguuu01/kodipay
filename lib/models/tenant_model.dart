class TenantModel {
  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? status;
  final String? paymentStatus;
  final String? propertyId;

  TenantModel({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    this.status,
    this.paymentStatus, 
    this.propertyId,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['_id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
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
        'email': email,
        'status': status,
        'paymentStatus': paymentStatus,
      };

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  get nationalId => null;
}

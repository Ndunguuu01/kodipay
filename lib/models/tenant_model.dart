class TenantModel {
  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? status;
  final String? paymentStatus;
  final dynamic property;
  final String? nationalId;
  final String? email;
  final String? unit;

  TenantModel({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.status,
    this.paymentStatus, 
    this.property,
    this.nationalId,
    this.email,
    this.unit,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    // Support both 'phoneNumber' and 'phone'
    final phoneNumber = json['phoneNumber'] ?? json['phone'];
    // Support both 'firstName'/'lastName' and 'name'
    String? firstName = json['firstName'];
    String? lastName = json['lastName'];
    if ((firstName == null || firstName.isEmpty) && json['name'] != null) {
      final nameParts = (json['name'] as String).split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    return TenantModel(
      id: id?.toString() ?? 'unknown_id',
      phoneNumber: phoneNumber?.toString() ?? 'unknown_phone',
      firstName: firstName,
      lastName: lastName,
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      property: json['property'],
      nationalId: json['nationalId'],
      email: json['email'],
      unit: json['unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'phoneNumber': phoneNumber,
        'firstName': firstName,
        'lastName': lastName,
        'status': status,
        'paymentStatus': paymentStatus,
        'property': property,
        'nationalId': nationalId,
        'email': email,
        'unit': unit,
      };

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

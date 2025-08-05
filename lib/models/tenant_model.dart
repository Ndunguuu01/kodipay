import 'package:kodipay/models/property.dart';

class TenantModel {
  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? status;
  final String? paymentStatus;
  final PropertyModel? property;
  final String? nationalId;
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
    this.unit,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    if (id == null) throw Exception('Tenant id is required');
    final phoneNumber = json['phoneNumber'] ?? json['phone'];
    if (phoneNumber == null) throw Exception('Tenant phoneNumber is required');
    String? firstName = json['firstName'];
    String? lastName = json['lastName'];
    if ((firstName == null || firstName.isEmpty) && json['name'] != null) {
      final nameParts = (json['name'] as String).split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }
    
    // Parse property field - handle both PropertyModel and JSON map
    PropertyModel? propertyModel;
    if (json['property'] != null) {
      if (json['property'] is Map<String, dynamic>) {
        propertyModel = PropertyModel.fromJson(json['property'] as Map<String, dynamic>);
      } else if (json['property'] is String) {
        // If property is just an ID string, we can't create a full PropertyModel
        // In this case, we'll leave it as null and let the UI handle it
        propertyModel = null;
      }
    }
    
    return TenantModel(
      id: id.toString(),
      phoneNumber: phoneNumber.toString(),
      firstName: firstName,
      lastName: lastName,
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      property: propertyModel,
      nationalId: json['nationalId'],
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
        'property': property?.toJson(),
        'nationalId': nationalId,
        'unit': unit,
      };

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  
  // Helper method to get property ID even if property is not fully loaded
  String get propertyId {
    if (property != null) {
      return property!.id;
    }
    // If property is null but we have raw data, try to extract ID
    return '';
  }
}

class AuthModel {
  final String id;
  final String email;
  final String phoneNumber;
  final String role;
  final String name;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? token;
  final String? refreshToken;
  final String? firstName;
  final String? lastName;
  final String phone;

  AuthModel({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.name,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
    this.token,
    this.refreshToken,
    this.firstName,
    this.lastName,
    required this.phone,
  });

  // Get the display role (maps 'owner' to 'landlord' for UI)
  String get displayRole => role == 'owner' ? 'landlord' : role;

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final String? fullName = json['name'] as String?;
    String? parsedFirstName;
    String? parsedLastName;

    if (fullName != null && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      parsedFirstName = parts.isNotEmpty ? parts.first : null;
      parsedLastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    }

    return AuthModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      role: json['role'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profilePicture: json['profilePicture'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      firstName: parsedFirstName,
      lastName: parsedLastName,
      phone: json['phone'] as String? ?? '',
    );
  }

  get user => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'name': name,
      'profilePicture': profilePicture,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'token': token,
      'refreshToken': refreshToken,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
    };
  }

  AuthModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? role,
    String? name,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? token,
    String? refreshToken,
    String? firstName,
    String? lastName,
    String? phone,
  }) {
    return AuthModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
    );
  }
}
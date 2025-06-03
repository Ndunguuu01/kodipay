class AuthModel {
  final String token;
  final String? refreshToken;
  final String id;
  final String role;
  final String phone;
  final String name;
  final String email;

  AuthModel({
    required this.token,
    this.refreshToken,
    required this.id,
    required this.role,
    required this.phone,
    required this.name,
    required this.email,
  });

  // Get the display role (maps 'owner' to 'landlord' for UI)
  String get displayRole => role == 'owner' ? 'landlord' : role;

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      id: json['_id'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  get user => null;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
      '_id': id,
      'phone': phone,
      'role': role,
      'name': name,
      'email': email,
    };
  }
}
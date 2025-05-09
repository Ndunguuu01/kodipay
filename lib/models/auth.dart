class AuthModel {
  final String token;
  final String? refreshToken;
  final String id;
  final String role;
  final String phoneNumber;
  final String name;

  AuthModel({
    required this.token,
    this.refreshToken,
    required this.id,
    required this.phoneNumber,
    required this.role,
    required this.name,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final fullName = user['name'] as String? ?? '$firstName $lastName'.trim();

    return AuthModel(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      id: user['id'] as String,
      phoneNumber: user['phoneNumber'] as String,
      role: user['role'] as String,
      name: fullName.isNotEmpty ? fullName : 'User',
    );
  }

  get user => null;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
      'user': {
        'id': id,
        'role': role,
        'name': name,
        'phoneNumber': phoneNumber,
      },
    };
  }
}
class ComplaintModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String tenantId;
  final String propertyId;
  final String? roomId;
  final String? tenantName;
  final String? propertyName;
  final String? roomNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? priority;
  final String? category;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.tenantId,
    required this.propertyId,
    this.roomId,
    this.tenantName,
    this.propertyName,
    this.roomNumber,
    required this.createdAt,
    required this.updatedAt,
    this.priority,
    this.category,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      tenantId: json['tenantId'] ?? '',
      propertyId: json['propertyId'] ?? '',
      roomId: json['roomId'],
      tenantName: json['tenantName'],
      propertyName: json['propertyName'],
      roomNumber: json['roomNumber'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      priority: json['priority'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'roomId': roomId,
      'tenantName': tenantName,
      'propertyName': propertyName,
      'roomNumber': roomNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'priority': priority,
      'category': category,
    };
  }

  ComplaintModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? tenantId,
    String? propertyId,
    String? roomId,
    String? tenantName,
    String? propertyName,
    String? roomNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? priority,
    String? category,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      roomId: roomId ?? this.roomId,
      tenantName: tenantName ?? this.tenantName,
      propertyName: propertyName ?? this.propertyName,
      roomNumber: roomNumber ?? this.roomNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      category: category ?? this.category,
    );
  }
} 
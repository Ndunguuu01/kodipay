class ComplaintModel {
  final String id;
  final String tenantId;
  final String propertyId;
  final String title;
  final String description;
  final String status;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  ComplaintModel({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.title,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['_id'],
      tenantId: json['tenant'],
      propertyId: json['property'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      submittedAt: DateTime.parse(json['submittedAt']),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolutionNotes: json['resolutionNotes'],
    );
  }
}
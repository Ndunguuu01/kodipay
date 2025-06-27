class RoomModel {
  final String id;
  final String roomNumber;
  final bool isOccupied;
  final String? tenantId;
  final double rentAmount;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.isOccupied,
    this.tenantId,
    required this.rentAmount,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['_id'],
      roomNumber: json['roomNumber'],
      isOccupied: json['isOccupied'] ?? false,
      tenantId: json['tenantId'],
      rentAmount: (json['rentAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomNumber': roomNumber,
      'isOccupied': isOccupied,
      'tenantId': tenantId,
      'rentAmount': rentAmount,
    };
  }
}

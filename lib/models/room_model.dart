class RoomModel {
  final String id;
  final String roomNumber;
  final String? tenantId;
  final bool isOccupied;

  RoomModel({
    required this.id,
    required this.roomNumber,
    this.tenantId,
    required this.isOccupied,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['_id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      tenantId: json['tenantId']?.toString(),
      isOccupied: json['isOccupied'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomNumber': roomNumber,
      'tenantId': tenantId,
      'isOccupied': isOccupied,
    };
  }
}
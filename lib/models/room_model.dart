class RoomModel {
  final String id;
  final String roomNumber;
  final String? tenantId;
  final bool isOccupied;
  final int? floorNumber;

  RoomModel({
    required this.id,
    required this.roomNumber,
    this.tenantId,
    required this.isOccupied,
    this.floorNumber,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['_id'] ?? json['id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      tenantId: json['tenantId'],
      isOccupied: json['isOccupied'] ?? false,
      floorNumber: json['floorNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomNumber': roomNumber,
      'tenantId': tenantId,
      'isOccupied': isOccupied,
      'floorNumber': floorNumber,
    };
  }
}

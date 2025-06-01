import 'package:kodipay/models/room_model.dart';

class FloorModel {
  final int floorNumber;
  final List<RoomModel> rooms;

  FloorModel({
    required this.floorNumber,
    required this.rooms,
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      floorNumber: json['floorNumber'] ?? 0,
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((room) => RoomModel.fromJson(room))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floorNumber': floorNumber,
      'rooms': rooms.map((room) => room.toJson()).toList(),
    };
  }
}

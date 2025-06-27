import 'package:kodipay/models/room_model.dart';

class FloorModel {
  final String id;
  final int floorNumber;
  final List<RoomModel> rooms;

  FloorModel({
    required this.id,
    required this.floorNumber,
    required this.rooms,
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['_id'],
      floorNumber: json['floorNumber'],
      rooms: (json['rooms'] as List)
          .map((room) => RoomModel.fromJson(room))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'floorNumber': floorNumber,
      'rooms': rooms.map((room) => room.toJson()).toList(),
    };
  }
}

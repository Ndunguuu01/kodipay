import 'package:kodipay/models/room_model.dart';

class FloorModel {
  final int floorNumber;
  final List<RoomModel> rooms;

  FloorModel({required this.floorNumber, required this.rooms});

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

class PropertyModel {
  final String id;
  final String landlordId;
  final String name;
  final String address;
  final double rentAmount;
  final String? description;
  final List<FloorModel> floors;
  final int? occupiedRooms;
   final String? tenantName;

  PropertyModel({
    required this.id,
    required this.landlordId,
    required this.name,
    required this.address,
    required this.rentAmount,
    this.description,
    required this.floors,
    this.occupiedRooms,
    this.tenantName,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['_id'] ?? '',
      landlordId: json['landlordId'] ?? json['landlord'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      rentAmount: (json['rentAmount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      floors: (json['floors'] as List<dynamic>?)
              ?.map((floor) => FloorModel.fromJson(floor))
              .toList() ?? 
          [],
      occupiedRooms: json['occupiedRooms'] ?? 0,
      tenantName: json['tenantName'],
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'landlordId': landlordId,
      'name': name,
      'address': address,
      'rentAmount': rentAmount,
      'description': description,
      'floors': floors.map((floor) => floor.toJson()).toList(),
    };
  }

  static PropertyModel empty = PropertyModel(
    id: '',
    landlordId: '',
    name: '',
    address: '',
    rentAmount: 0.0,
    floors: [],
  );

  int get totalRooms {
    return floors.fold(0, (sum, floor) => sum + floor.rooms.length);
  }
}
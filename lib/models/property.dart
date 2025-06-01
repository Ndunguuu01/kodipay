import 'package:kodipay/models/floor_model.dart';

class PropertyModel {
  final String id;
  final String name;
  final String address;
  final double rentAmount;
  final int totalRooms;
  final int? occupiedRooms;
  final List<FloorModel> floors;
  final String? description;
  final String? landlordId;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.rentAmount,
    required this.totalRooms,
    this.occupiedRooms,
    required this.floors,
    this.description,
    this.landlordId,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      rentAmount: (json['rentAmount'] as num?)?.toDouble() ?? 0.0,
      totalRooms: json['totalRooms'] ?? 0,
      occupiedRooms: json['occupiedRooms'],
      floors: (json['floors'] as List<dynamic>?)?.map((f) => FloorModel.fromJson(f)).toList() ?? [],
      description: json['description'],
      landlordId: json['landlordId'],
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'address': address,
      'rentAmount': rentAmount,
      'totalRooms': totalRooms,
      'occupiedRooms': occupiedRooms,
      'floors': floors.map((floor) => floor.toJson()).toList(),
      'description': description,
      'landlordId': landlordId,
      'imageUrl': imageUrl,
    };
  }

  static final PropertyModel empty = PropertyModel(
    id: '',
    name: '',
    address: '',
    rentAmount: 0,
    totalRooms: 0,
    occupiedRooms: 0,
    floors: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
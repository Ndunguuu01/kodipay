import 'package:kodipay/models/floor_model.dart';

class PropertyModel {
  final String id;
  final String name;
  final String address;
  final double rentAmount;
  final int totalRooms;
  final int? occupiedRooms;
  final List<FloorModel> floors;
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['_id'],
      name: json['name'],
      address: json['address'] ?? '',
      rentAmount: (json['rentAmount'] ?? 0).toDouble(),
      totalRooms: json['totalRooms'] ?? 0,
      occupiedRooms: json['occupiedRooms'],
      floors: (json['floors'] as List)
          .map((floor) => FloorModel.fromJson(floor))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusModel {
  final String id;
  final String busNumber;
  final String driverId;
  final String startPoint;
  final String endPoint;
  final List<String> stopPoints;
  final String collegeId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.driverId,
    required this.startPoint,
    required this.endPoint,
    required this.stopPoints,
    required this.collegeId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory BusModel.fromMap(Map<String, dynamic> map, String id) {
    return BusModel(
      id: id,
      busNumber: map['busNumber'] ?? '',
      driverId: map['driverId'] ?? '',
      startPoint: map['startPoint'] ?? '',
      endPoint: map['endPoint'] ?? '',
      stopPoints: List<String>.from(map['stopPoints'] ?? []),
      collegeId: map['collegeId'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'driverId': driverId,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'stopPoints': stopPoints,
      'collegeId': collegeId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class BusLocationModel {
  final String busId;
  final LatLng currentLocation;
  final DateTime timestamp;
  final double? speed;
  final double? heading;

  BusLocationModel({
    required this.busId,
    required this.currentLocation,
    required this.timestamp,
    this.speed,
    this.heading,
  });

  factory BusLocationModel.fromMap(Map<String, dynamic> map, String busId) {
    return BusLocationModel(
      busId: busId,
      currentLocation: LatLng(
        map['currentLocation']['lat']?.toDouble() ?? 0.0,
        map['currentLocation']['lng']?.toDouble() ?? 0.0,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLocation': {
        'lat': currentLocation.latitude,
        'lng': currentLocation.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heading': heading,
    };
  }
}
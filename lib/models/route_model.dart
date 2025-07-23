class RouteModel {
  final String id;
  final String routeName;
  final String routeType; // 'pickup' or 'drop'
  final String startPoint;
  final String endPoint;
  final List<String> stopPoints;
  final String collegeId;
  final String createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RouteModel({
    required this.id,
    required this.routeName,
    required this.routeType,
    required this.startPoint,
    required this.endPoint,
    required this.stopPoints,
    required this.collegeId,
    required this.createdBy,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    return RouteModel(
      id: id,
      routeName: map['routeName'] ?? '',
      routeType: map['routeType'] ?? 'pickup',
      startPoint: map['startPoint'] ?? '',
      endPoint: map['endPoint'] ?? '',
      stopPoints: List<String>.from(map['stopPoints'] ?? []),
      collegeId: map['collegeId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeName': routeName,
      'routeType': routeType,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'stopPoints': stopPoints,
      'collegeId': collegeId,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  RouteModel copyWith({
    String? id,
    String? routeName,
    String? routeType,
    String? startPoint,
    String? endPoint,
    List<String>? stopPoints,
    String? collegeId,
    String? createdBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      routeName: routeName ?? this.routeName,
      routeType: routeType ?? this.routeType,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      stopPoints: stopPoints ?? this.stopPoints,
      collegeId: collegeId ?? this.collegeId,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => '$routeName (${routeType.toUpperCase()})';
}
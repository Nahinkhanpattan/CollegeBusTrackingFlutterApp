class ScheduleModel {
  final String id;
  final String routeId;
  final String busId;
  final String shift; // '1st' or '2nd'
  final List<StopSchedule> stopSchedules;
  final String collegeId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  ScheduleModel({
    required this.id,
    required this.routeId,
    required this.busId,
    required this.shift,
    required this.stopSchedules,
    required this.collegeId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    return ScheduleModel(
      id: id,
      routeId: map['routeId'] ?? '',
      busId: map['busId'] ?? '',
      shift: map['shift'] ?? '1st',
      stopSchedules: (map['stopSchedules'] as List<dynamic>?)
          ?.map((item) => StopSchedule.fromMap(item))
          .toList() ?? [],
      collegeId: map['collegeId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'busId': busId,
      'shift': shift,
      'stopSchedules': stopSchedules.map((schedule) => schedule.toMap()).toList(),
      'collegeId': collegeId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  ScheduleModel copyWith({
    String? id,
    String? routeId,
    String? busId,
    String? shift,
    List<StopSchedule>? stopSchedules,
    String? collegeId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      shift: shift ?? this.shift,
      stopSchedules: stopSchedules ?? this.stopSchedules,
      collegeId: collegeId ?? this.collegeId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class StopSchedule {
  final String stopName;
  final String arrivalTime; // Format: "HH:mm"
  final String departureTime; // Format: "HH:mm"

  StopSchedule({
    required this.stopName,
    required this.arrivalTime,
    required this.departureTime,
  });

  factory StopSchedule.fromMap(Map<String, dynamic> map) {
    return StopSchedule(
      stopName: map['stopName'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      departureTime: map['departureTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopName': stopName,
      'arrivalTime': arrivalTime,
      'departureTime': departureTime,
    };
  }

  StopSchedule copyWith({
    String? stopName,
    String? arrivalTime,
    String? departureTime,
  }) {
    return StopSchedule(
      stopName: stopName ?? this.stopName,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
    );
  }
}
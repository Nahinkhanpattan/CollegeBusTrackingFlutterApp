import 'package:college_bus_tracker/utils/constants.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String collegeId;
  final bool approved;
  final bool emailVerified;
  final bool needsManualApproval;
  final String? approverId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.collegeId,
    this.approved = false,
    this.emailVerified = false,
    this.needsManualApproval = false,
    this.approverId,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.value == map['role'],
        orElse: () => UserRole.student,
      ),
      collegeId: map['collegeId'] ?? '',
      approved: map['approved'] ?? false,
      emailVerified: map['emailVerified'] ?? false,
      needsManualApproval: map['needsManualApproval'] ?? false,
      approverId: map['approverId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role.value,
      'collegeId': collegeId,
      'approved': approved,
      'emailVerified': emailVerified,
      'needsManualApproval': needsManualApproval,
      'approverId': approverId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    UserRole? role,
    String? collegeId,
    bool? approved,
    bool? emailVerified,
    bool? needsManualApproval,
    String? approverId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      collegeId: collegeId ?? this.collegeId,
      approved: approved ?? this.approved,
      emailVerified: emailVerified ?? this.emailVerified,
      needsManualApproval: needsManualApproval ?? this.needsManualApproval,
      approverId: approverId ?? this.approverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
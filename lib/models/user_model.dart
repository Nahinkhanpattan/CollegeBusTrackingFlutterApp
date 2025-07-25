import 'package:collegebus/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? phoneNumber;
  final String? rollNumber;

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
    this.phoneNumber,
    this.rollNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now();
      }
    }

    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: fromUserRoleValue(map['role']),
      collegeId: map['collegeId'] ?? '',
      approved: map['approved'] ?? false,
      emailVerified: map['emailVerified'] ?? false,
      needsManualApproval: map['needsManualApproval'] ?? false,
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      phoneNumber: map['phoneNumber'],
      rollNumber: map['rollNumber'],
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
      'phoneNumber': phoneNumber,
      'rollNumber': rollNumber,
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
    String? phoneNumber,
    String? rollNumber,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rollNumber: rollNumber ?? this.rollNumber,
    );
  }
}

UserRole fromUserRoleValue(dynamic value) {
  if (value is UserRole) return value;
  if (value is String) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.student,
    );
  }
  return UserRole.student;
}

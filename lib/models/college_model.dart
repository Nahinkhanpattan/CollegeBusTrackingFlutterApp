class CollegeModel {
  final String id;
  final String name;
  final List<String> allowedDomains;
  final bool verified;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CollegeModel({
    required this.id,
    required this.name,
    required this.allowedDomains,
    this.verified = false,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory CollegeModel.fromMap(Map<String, dynamic> map, String id) {
    return CollegeModel(
      id: id,
      name: map['name'] ?? '',
      allowedDomains: List<String>.from(map['allowedDomains'] ?? []),
      verified: map['verified'] ?? false,
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'allowedDomains': allowedDomains,
      'verified': verified,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CollegeModel copyWith({
    String? id,
    String? name,
    List<String>? allowedDomains,
    bool? verified,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollegeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      allowedDomains: allowedDomains ?? this.allowedDomains,
      verified: verified ?? this.verified,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
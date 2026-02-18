import 'models.dart';

class Company {
  final String id;
  final String companyName;
  final ContactInfo contactInfo;
  final DateTime createdAt;
  final List<String> createdEventIds;
  final String description;
  final double profileImageOffsetX;
  final double profileImageOffsetY;
  final String profileImageUrl;
  final bool verified;

  Company({
    this.id = '',
    required this.companyName,
    required this.contactInfo,
    required this.createdAt,
    required this.createdEventIds,
    required this.description,
    required this.profileImageOffsetX,
    required this.profileImageOffsetY,
    required this.profileImageUrl,
    required this.verified,
  });

  factory Company.fromJson(Map<String, dynamic> json, {String id = ''}) {
    return Company(
      id: id,
      companyName: json['companyName'] ?? '',
      contactInfo: ContactInfo.fromJson(
        (json['contactInfo'] ?? {}) as Map<String, dynamic>,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      createdEventIds: _parseStringList(json['createdEventIds']),
      description: json['description'] ?? '',
      profileImageOffsetX: _parseDouble(json['profileImageOffsetX']),
      profileImageOffsetY: _parseDouble(json['profileImageOffsetY']),
      profileImageUrl: json['profileImageUrl'] ?? '',
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'contactInfo': contactInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'createdEventIds': createdEventIds,
      'description': description,
      'profileImageOffsetX': profileImageOffsetX,
      'profileImageOffsetY': profileImageOffsetY,
      'profileImageUrl': profileImageUrl,
      'verified': verified,
    };
  }

  Company copyWith({
    String? id,
    String? companyName,
    ContactInfo? contactInfo,
    DateTime? createdAt,
    List<String>? createdEventIds,
    String? description,
    double? profileImageOffsetX,
    double? profileImageOffsetY,
    String? profileImageUrl,
    bool? verified,
  }) {
    return Company(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
      createdEventIds: createdEventIds ?? this.createdEventIds,
      description: description ?? this.description,
      profileImageOffsetX: profileImageOffsetX ?? this.profileImageOffsetX,
      profileImageOffsetY: profileImageOffsetY ?? this.profileImageOffsetY,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      verified: verified ?? this.verified,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .where((e) => e != null)
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

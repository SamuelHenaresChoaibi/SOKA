import 'models.dart';

class Company {
  final String companyName;
  final ContactInfo contactInfo;
  final DateTime createdAt;
  final List<String> createdEventIds;
  final String description;
  final bool verified;

  Company({
    required this.companyName,
    required this.contactInfo,
    required this.createdAt,
    required this.createdEventIds,
    required this.description,
    required this.verified,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      companyName: json['companyName'] ?? '',
      contactInfo: ContactInfo.fromJson(
        (json['contactInfo'] ?? {}) as Map<String, dynamic>,
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      createdEventIds: _parseStringList(json['createdEventIds']),
      description: json['description'] ?? '',
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
      'verified': verified,
    };
  }

  Company copyWith({
    String? companyName,
    ContactInfo? contactInfo,
    DateTime? createdAt,
    List<String>? createdEventIds,
    String? description,
    bool? verified,
  }) {
    return Company(
      companyName: companyName ?? this.companyName,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
      createdEventIds: createdEventIds ?? this.createdEventIds,
      description: description ?? this.description,
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
}

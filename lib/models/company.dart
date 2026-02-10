import 'models.dart';

class Company {
  final String companyName;
  final ContactInfo contactInfo;
  final DateTime createdAt;
  final String description;
  final String photoUrl;
  final bool verified;

  Company({
    required this.companyName,
    required this.contactInfo,
    required this.createdAt,
    required this.description,
    required this.photoUrl,
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
      description: json['description'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'contactInfo': contactInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'photoUrl': photoUrl,
      'verified': verified,
    };
  }
}

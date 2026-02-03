import 'models.dart';

class Company {
  final String companyName;
  final ContactInfo contactInfo;
  final DateTime createdAt;
  final String description;
  final bool verified;

  Company({
    required this.companyName,
    required this.contactInfo,
    required this.createdAt,
    required this.description,
    required this.verified,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      companyName: json['companyName'],
      contactInfo: ContactInfo.fromJson(json['contactInfo']),
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
      verified: json['verified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'contactInfo': contactInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'verified': verified,
    };
  }
}

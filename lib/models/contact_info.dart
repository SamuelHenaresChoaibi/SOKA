class ContactInfo {
  final String adress;
  final String email;
  final String instagram;
  final String phoneNumber;
  final String website;

  ContactInfo({
    required this.adress,
    required this.email,
    required this.instagram,
    required this.phoneNumber,
    required this.website,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      adress: json['adress'] ?? '',
      email: json['email'] ?? '',
      instagram: json['instagram'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      website: json['website'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adress': adress,
      'email': email,
      'instagram': instagram,
      'phoneNumber': phoneNumber,
      'website': website,
    };
  }
}

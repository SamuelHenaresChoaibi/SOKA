class TicketHolder {
  final String fullName;
  final String dni;
  final DateTime birthDate;
  final String phoneNumber;

  TicketHolder({
    required this.fullName,
    required this.dni,
    required this.birthDate,
    required this.phoneNumber, 
  });

  factory TicketHolder.fromJson(Map<String, dynamic> json) {
    return TicketHolder(
      fullName: json['fullName']?.toString() ?? '',
      dni: json['dni']?.toString() ?? '',
      birthDate: _parseDate(json['birthDate']),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dni': dni,
      'birthDate': birthDate.toIso8601String(),
      'phoneNumber': phoneNumber,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  bool get isValid {
    return fullName.isNotEmpty &&
        dni.isNotEmpty &&
        phoneNumber.isNotEmpty;
  }
}

class SoldTicket {
  final String eventId;
  final String holderName;
  final int idTicket;
  final DateTime purchaseDate;
  final String qrCode;
  final bool scanned;
  final String ticketType;
  final String userId;

  SoldTicket({
    required this.eventId,
    required this.holderName,
    required this.idTicket,
    required this.purchaseDate,
    required this.qrCode,
    required this.scanned,
    required this.ticketType,
    required this.userId,
  });

  factory SoldTicket.fromJson(Map<String, dynamic> json) {
    return SoldTicket(
      eventId: json['eventId']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? '',
      idTicket: _parseInt(json['idTicket']),
      purchaseDate: _parseDate(json['purchaseDate']),
      qrCode: json['qrCode']?.toString() ?? '',
      scanned: json['scanned'] == true,
      ticketType: json['ticketType']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'holderName': holderName,
      'idTicket': idTicket,
      'purchaseDate': purchaseDate.toIso8601String(),
      'qrCode': qrCode,
      'scanned': scanned,
      'ticketType': ticketType,
      'userId': userId,
    };
  }

  /// Helpers seguros
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

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
      eventId: json['eventId'],
      holderName: json['holderName'],
      idTicket: json['idTicket'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      qrCode: json['qrCode'],
      scanned: json['scanned'],
      ticketType: json['ticketType'],
      userId: json['userId'],
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
}

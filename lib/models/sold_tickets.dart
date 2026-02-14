import 'models.dart';

class SoldTicket {
  final String eventId;
  final String buyerUserId;
  final int idTicket;
  final DateTime purchaseDate;
  final String qrCode;
  final bool scanned;
  final String ticketType;
  final TicketHolder holder;

  SoldTicket({
    required this.eventId,
    required this.buyerUserId,
    required this.idTicket,
    required this.purchaseDate,
    required this.qrCode,
    required this.scanned,
    required this.ticketType,
    required this.holder,
  });

  factory SoldTicket.fromJson(Map<String, dynamic> json) {
    return SoldTicket(
      eventId: json['eventId']?.toString() ?? '',
      buyerUserId:
          json['buyerUserId']?.toString() ?? json['userId']?.toString() ?? '',
      idTicket: _parseInt(json['idTicket']),
      purchaseDate: _parseDate(json['purchaseDate']),
      qrCode: json['qrCode']?.toString() ?? '',
      scanned: json['scanned'] == true,
      ticketType: json['ticketType']?.toString() ?? '',
      holder: _parseHolder(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'buyerUserId': buyerUserId,
      'idTicket': idTicket,
      'purchaseDate': purchaseDate.toIso8601String(),
      'qrCode': qrCode,
      'scanned': scanned,
      'ticketType': ticketType,
      'holder': holder.toJson(),
    };
  }

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

  static TicketHolder _parseHolder(Map<String, dynamic> json) {
    final rawHolder = json['holder'];
    if (rawHolder is Map<String, dynamic>) {
      return TicketHolder.fromJson(rawHolder);
    }
    if (rawHolder is String) {
      return TicketHolder(fullName: rawHolder, phoneNumber: '', dni: '', birthDate: DateTime.now());
    }

    final legacyHolderName =
        json['holderName'] ??
        json['holder_full_name'] ??
        json['holderFullName'] ??
        json['fullName'];
    if (legacyHolderName != null) {
      if (legacyHolderName is String) {
        return TicketHolder(fullName: legacyHolderName, phoneNumber: '', dni: '', birthDate: DateTime.now());
      }
    }

    return TicketHolder(fullName: '', phoneNumber: '', dni: '', birthDate: DateTime.now());
  }

  bool get isValid => holder.isValid;
}

import 'dart:math';

import 'models.dart';

class Event {
  final String id;
  final String category;
  final DateTime createdAt;
  final DateTime date;
  final String description;
  final String imageUrl;
  final String location;
  final String? locationFormatted;
  final double? locationLat;
  final double? locationLng;
  final String? locationCity;
  final String? locationState;
  final String? locationPostcode;
  final String? locationCountry;
  /// Máximo de entradas que puede comprar un usuario para este evento.
  ///
  /// Si es `0` (o menor), se interpreta como "sin límite".
  final int maxTicketsPerUser;
  final String organizerId;
  final List<TicketType> ticketTypes;
  final String title;
  final bool validated;

  Event({
    required this.id,
    required this.category,
    required this.createdAt,
    required this.date,
    required this.description,
    required this.imageUrl,
    required this.location,
    this.locationFormatted,
    this.locationLat,
    this.locationLng,
    this.locationCity,
    this.locationState,
    this.locationPostcode,
    this.locationCountry,
    required this.maxTicketsPerUser,
    required this.organizerId,
    required this.ticketTypes,
    required this.title,
    required this.validated,
  });

  factory Event.fromJson(Map<String, dynamic> json, {required String id}) {
    final ticketTypes = TicketType.listFromJson(json['ticketTypes']);

    return Event(
      id: id,
      category: json['category']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      date: _parseDate(json['date']),
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      locationFormatted: json['locationFormatted']?.toString(),
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      locationCity: json['locationCity']?.toString(),
      locationState: json['locationState']?.toString(),
      locationPostcode: json['locationPostcode']?.toString(),
      locationCountry: json['locationCountry']?.toString(),
      organizerId: json['organizerId']?.toString() ?? '',
      ticketTypes: ticketTypes,
      title: json['title']?.toString() ?? '',
      validated: json['validated'] == true,
      maxTicketsPerUser: _parseInt(
        json['maxTicketsPerUser'] ??
            json['ticketPurchaseLimit'] ??
            json['purchaseLimit'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'date': date.toIso8601String(),
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'locationFormatted': locationFormatted,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'locationCity': locationCity,
      'locationState': locationState,
      'locationPostcode': locationPostcode,
      'locationCountry': locationCountry,
      'maxTicketsPerUser': maxTicketsPerUser,
      'organizerId': organizerId,
      'ticketTypes': ticketTypes.map((e) => e.toJson()).toList(),
      'title': title,
      'validated': validated,
    };
  }

  String get locationLabel {
    final formatted = locationFormatted?.trim() ?? '';
    return formatted.isNotEmpty ? formatted : location;
  }

  bool get hasTicketTypes => ticketTypes.isNotEmpty;

  int get minTicketPrice {
    if (!hasTicketTypes) return 0;
    return ticketTypes.map((e) => e.price).reduce(min);
  }

  int get maxTicketPrice {
    if (!hasTicketTypes) return 0;
    return ticketTypes.map((e) => e.price).reduce(max);
  }

  int get totalRemaining {
    if (!hasTicketTypes) return 0;
    return ticketTypes.fold(0, (sum, e) => sum + e.remaining);
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

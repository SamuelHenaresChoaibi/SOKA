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
  final String organizerId;
  final TicketType ticketTypes;
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
    required this.organizerId,
    required this.ticketTypes,
    required this.title,
    required this.validated,
  });

  factory Event.fromJson(Map<String, dynamic> json, {required String id}) {
    final rawTicketTypes = json['ticketTypes'];
    Map<String, dynamic> ticketMap;
    if (rawTicketTypes is Map<String, dynamic>) {
      ticketMap = rawTicketTypes;
    } else if (rawTicketTypes is Map) {
      ticketMap = rawTicketTypes.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else if (rawTicketTypes is List && rawTicketTypes.isNotEmpty) {
      final first = rawTicketTypes.first;
      if (first is Map<String, dynamic>) {
        ticketMap = first;
      } else if (first is Map) {
        ticketMap = first.map((key, value) => MapEntry(key.toString(), value));
      } else {
        ticketMap = const {};
      }
    } else {
      ticketMap = const {};
    }

    TicketType ticketTypes;
    try {
      ticketTypes = TicketType.fromJson(ticketMap);
    } catch (_) {
      ticketTypes = TicketType(
        capacity: 0,
        description: '',
        price: 0,
        remaining: 0,
        type: 'General',
      );
    }

    return Event(
      id: id,
      category: json['category']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? ''),
      date: DateTime.parse(json['date']?.toString() ?? ''),
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
      'organizerId': organizerId,
      'ticketTypes': ticketTypes.toJson(),
      'title': title,
      'validated': validated,
    };
  }

  String get locationLabel {
    final formatted = locationFormatted?.trim() ?? '';
    return formatted.isNotEmpty ? formatted : location;
  }
}

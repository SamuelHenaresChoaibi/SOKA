import 'models.dart';

class Event {
  final String id;
  final String category;
  final DateTime createdAt;
  final DateTime date;
  final String description;
  final String imageUrl;
  final String location;
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
    required this.maxTicketsPerUser,
    required this.organizerId,
    required this.ticketTypes,
    required this.title,
    required this.validated,
  });

  factory Event.fromJson(Map<String, dynamic> json, {required String id}) {
    final rawTicketTypes =
        json['ticketTypes'] ?? json['ticketsType'] ?? json['ticketsTypes'];

    return Event(
      id: id,
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      date: DateTime.parse(json['date']),
      description: json['description'],
      imageUrl: json['imageUrl']?.toString() ?? '',
      location: json['location'],
      maxTicketsPerUser: _parseInt(
        json['maxTicketsPerUser'] ??
            json['ticketPurchaseLimit'] ??
            json['purchaseLimit'],
      ),
      organizerId: json['organizerId'],
      ticketTypes: TicketType.listFromJson(rawTicketTypes),
      title: json['title'],
      validated: json['validated'],
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
      'maxTicketsPerUser': maxTicketsPerUser,
      'organizerId': organizerId,
      'ticketTypes': ticketTypes.map((e) => e.toJson()).toList(),
      'title': title,
      'validated': validated,
    };
  }

  bool get hasTicketTypes => ticketTypes.isNotEmpty;

  int get totalRemaining =>
      ticketTypes.fold<int>(0, (sum, t) => sum + t.remaining);

  int get minTicketPrice {
    if (ticketTypes.isEmpty) return 0;
    var minPrice = ticketTypes.first.price;
    for (final t in ticketTypes.skip(1)) {
      if (t.price < minPrice) minPrice = t.price;
    }
    return minPrice;
  }

  int get maxTicketPrice {
    if (ticketTypes.isEmpty) return 0;
    var maxPrice = ticketTypes.first.price;
    for (final t in ticketTypes.skip(1)) {
      if (t.price > maxPrice) maxPrice = t.price;
    }
    return maxPrice;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

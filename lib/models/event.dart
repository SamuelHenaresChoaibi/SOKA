import 'models.dart';

class Event {
  final String id;
  final String category;
  final DateTime createdAt;
  final DateTime date;
  final String description;
  final String location;
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
    required this.location,
    required this.organizerId,
    required this.ticketTypes,
    required this.title,
    required this.validated,
  });

  factory Event.fromJson(Map<String, dynamic> json, {required String id}) {
    return Event(
      id: id,
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      date: DateTime.parse(json['date']),
      description: json['description'],
      location: json['location'],
      organizerId: json['organizerId'],
      ticketTypes: TicketType.fromJson(json['ticketTypes']),
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
      'location': location,
      'organizerId': organizerId,
      'ticketTypes': ticketTypes.toJson(),
      'title': title,
      'validated': validated,
    };
  }
}

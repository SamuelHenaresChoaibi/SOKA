class TicketType {
  final int capacity;
  final String description;
  final int price;
  final int remaining;
  final String type;

  TicketType({
    required this.capacity,
    required this.description,
    required this.price,
    required this.remaining,
    required this.type,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      capacity: _parseInt(json['capacity']),
      description: json['description']?.toString() ?? '',
      price: _parseInt(json['price']),
      remaining: _parseInt(json['remaining']),
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'capacity': capacity,
      'description': description,
      'price': price,
      'remaining': remaining,
      'type': type,
    };
  }

  static List<TicketType> listFromJson(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .map(_maybeFromJson)
          .whereType<TicketType>()
          .toList(growable: false);
    }

    if (value is Map) {
      if (_looksLikeTicketTypeMap(value)) {
        final parsed = _maybeFromJson(value);
        return parsed == null ? const [] : [parsed];
      }

      return value.values
          .map(_maybeFromJson)
          .whereType<TicketType>()
          .toList(growable: false);
    }

    return const [];
  }

  static TicketType? _maybeFromJson(dynamic value) {
    if (value is Map<String, dynamic>) return TicketType.fromJson(value);
    if (value is Map) {
      return TicketType.fromJson(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
    }
    return null;
  }

  static bool _looksLikeTicketTypeMap(Map value) {
    return value.containsKey('type') ||
        value.containsKey('price') ||
        value.containsKey('capacity') ||
        value.containsKey('remaining');
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

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
      capacity: json['capacity'],
      description: json['description'],
      price: json['price'],
      remaining: json['remaining'],
      type: json['type'],
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
}

class Client {
  final int age;
  final DateTime createdAt;
  final String email;
  final List<String> favoriteEventIds;
  final List<String> historyEventIds;
  final List<String?> interests;
  final String name;
  final String phoneNumber;
  final String surname;
  final String userName;

  Client({
    required this.age,
    required this.createdAt,
    required this.email,
    required this.favoriteEventIds,
    required this.historyEventIds,
    required this.interests,
    required this.name,
    required this.phoneNumber,
    required this.surname,
    required this.userName,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      age: (json['age'] ?? 0) as int,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      email: json['email'] ?? '',
      favoriteEventIds: _parseStringList(json['favoriteEventIds']),
      historyEventIds: _parseStringList(json['historyEventIds']),
      interests:
          List<String?>.from((json['interests'] ?? const <String?>[])),
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      surname: json['surname'] ?? '',
      userName: json['userName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'createdAt': createdAt.toIso8601String(),
      'email': email,
      'favoriteEventIds': favoriteEventIds,
      'historyEventIds': historyEventIds,
      'interests': interests,
      'name': name,
      'phoneNumber': phoneNumber,
      'surname': surname,
      'userName': userName,
    };
  }

  Client copyWith({
    int? age,
    DateTime? createdAt,
    String? email,
    List<String>? favoriteEventIds,
    List<String>? historyEventIds,
    List<String?>? interests,
    String? name,
    String? phoneNumber,
    String? surname,
    String? userName,
  }) {
    return Client(
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      favoriteEventIds: favoriteEventIds ?? this.favoriteEventIds,
      historyEventIds: historyEventIds ?? this.historyEventIds,
      interests: interests ?? this.interests,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      surname: surname ?? this.surname,
      userName: userName ?? this.userName,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .where((e) => e != null)
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

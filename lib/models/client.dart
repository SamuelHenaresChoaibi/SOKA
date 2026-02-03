class Client {
  final int age;
  final DateTime createdAt;
  final String email;
  final List<String> interests;
  final String name;
  final String phoneNumber;
  final String surname;
  final String userName;

  Client({
    required this.age,
    required this.createdAt,
    required this.email,
    required this.interests,
    required this.name,
    required this.phoneNumber,
    required this.surname,
    required this.userName,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      age: json['age'],
      createdAt: DateTime.parse(json['createdAt']),
      email: json['email'],
      interests: List<String>.from(json['interests']),
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      surname: json['surname'],
      userName: json['userName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'createdAt': createdAt.toIso8601String(),
      'email': email,
      'interests': interests,
      'name': name,
      'phoneNumber': phoneNumber,
      'surname': surname,
      'userName': userName,
    };
  }
}

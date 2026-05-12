class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final String profilePicture;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.profilePicture,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'profilePicture': profilePicture,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      businessName: map['businessName'],
      profilePicture: map['profilePicture'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

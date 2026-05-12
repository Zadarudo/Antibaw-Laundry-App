class Service {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
      color: map['color'],
    );
  }
}

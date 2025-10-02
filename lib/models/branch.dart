class Branch {
  final int? id;
  final String name;
  final String location;

  Branch({
    this.id,
    required this.name,
    required this.location,
  });

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      name: map['name'],
      location: map['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
    };
  }
}
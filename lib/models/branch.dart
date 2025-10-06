class Branch {
  final int? id;
  final String name;
  final String location;
  final String? code;

  Branch({
    this.id,
    required this.name,
    required this.location,
    this.code,
  });

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      code: map['code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'code': code,
    };
  }
}
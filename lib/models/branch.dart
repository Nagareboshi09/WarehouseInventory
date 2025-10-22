class Branch {
  final int? id;
  final String name;
  final String location;
  final String? code;
  final String? weeklyOrderOfftake;
  final String? weeklyReorderPoint;
  final String? maintainingInventory;

  Branch({
    this.id,
    required this.name,
    required this.location,
    this.code,
    this.weeklyOrderOfftake,
    this.weeklyReorderPoint,
    this.maintainingInventory,
  });

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      code: map['code'],
      weeklyOrderOfftake: map['weeklyOrderOfftake'],
      weeklyReorderPoint: map['weeklyReorderPoint'],
      maintainingInventory: map['maintainingInventory'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'code': code,
      'weeklyOrderOfftake': weeklyOrderOfftake,
      'weeklyReorderPoint': weeklyReorderPoint,
      'maintainingInventory': maintainingInventory,
    };
  }
}
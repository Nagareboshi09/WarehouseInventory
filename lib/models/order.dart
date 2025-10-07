class Order {
  int? id;
  int branchId;
  String location;
  String brand;
  int itemId;
  int quantity;
  DateTime dateOrdered;
  String status;

  Order({
    this.id,
    required this.branchId,
    required this.location,
    required this.brand,
    required this.itemId,
    required this.quantity,
    required this.dateOrdered,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branchId': branchId,
      'location': location,
      'brand': brand,
      'itemId': itemId,
      'quantity': quantity,
      'dateOrdered': dateOrdered.toIso8601String(),
      'status': status,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      branchId: map['branchId'],
      location: map['location'],
      brand: map['brand'],
      itemId: map['itemId'],
      quantity: map['quantity'],
      dateOrdered: DateTime.parse(map['dateOrdered']),
      status: map['status'],
    );
  }
}
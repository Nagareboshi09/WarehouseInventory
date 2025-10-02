class InventoryItem {
  final int? id;
  final String sku;
  final String itemClass;
  final String description;
  final int quantity;
  final String location;
  final DateTime dateAdded;
  final int branchId;

  InventoryItem({
    this.id,
    required this.sku,
    required this.itemClass,
    required this.description,
    required this.quantity,
    required this.location,
    required this.dateAdded,
    required this.branchId,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      sku: map['sku'],
      itemClass: map['itemClass'],
      description: map['description'],
      quantity: map['quantity'],
      location: map['location'],
      dateAdded: DateTime.parse(map['dateAdded']),
      branchId: map['branchId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'itemClass': itemClass,
      'description': description,
      'quantity': quantity,
      'location': location,
      'dateAdded': dateAdded.toIso8601String(),
      'branchId': branchId,
    };
  }
}
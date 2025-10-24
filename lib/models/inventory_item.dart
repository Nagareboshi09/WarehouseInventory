class InventoryItem {
  final int? id;
  final String sku;
  final String description;
  final int end;
  final String location;
  final String? brand;
  final DateTime dateAdded;
  final DateTime? dateUpdated;
  final int branchId;

  InventoryItem({
    this.id,
    required this.sku,
    required this.description,
    required this.end,
    required this.location,
    this.brand,
    required this.dateAdded,
    this.dateUpdated,
    required this.branchId,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      sku: map['sku'],
      description: map['description'],
      end: map['end'],
      location: map['location'],
      brand: map['brand'],
      dateAdded: DateTime.parse(map['dateAdded']),
      dateUpdated: map['dateUpdated'] != null ? DateTime.parse(map['dateUpdated']) : null,
      branchId: map['branchId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'description': description,
      'end': end,
      'location': location,
      'brand': brand,
      'dateAdded': dateAdded.toIso8601String(),
      'dateUpdated': dateUpdated?.toIso8601String(),
      'branchId': branchId,
    };
  }
}
class InventoryItem {
  final int? id;
  final String sku;
  final String description;
  final int end;
  final String location;
  final String? brand;
  final DateTime dateAdded;
  final DateTime? lastUpdated;
  final int branchId;
  final int? beg;
  final int? prev;
  final int? sales;

  InventoryItem({
    this.id,
    required this.sku,
    required this.description,
    required this.end,
    required this.location,
    this.brand,
    required this.dateAdded,
    this.lastUpdated,
    required this.branchId,
    this.beg,
    this.prev,
    this.sales,
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
      lastUpdated: map['lastUpdated'] != null ? DateTime.parse(map['lastUpdated']) : null,
      branchId: map['branchId'],
      beg: map['beg'],
      prev: map['prev'],
      sales: map['sales'],
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
      'lastUpdated': lastUpdated?.toIso8601String(),
      'branchId': branchId,
      'beg': beg,
      'prev': prev,
      'sales': sales,
    };
  }

  InventoryItem copyWith({
    int? id,
    String? sku,
    String? description,
    int? end,
    String? location,
    String? brand,
    DateTime? dateAdded,
    DateTime? lastUpdated,
    int? branchId,
    int? beg,
    int? prev,
    int? sales,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      end: end ?? this.end,
      location: location ?? this.location,
      brand: brand ?? this.brand,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      branchId: branchId ?? this.branchId,
      beg: beg ?? this.beg,
      prev: prev ?? this.prev,
      sales: sales ?? this.sales,
    );
  }
}
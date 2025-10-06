class MasterItem {
  final int? id;
  final String sku;
  final String itemClass;
  final String description;
  final String location;
  final String? brand;
  final int branchId;

  MasterItem({
    this.id,
    required this.sku,
    required this.itemClass,
    required this.description,
    required this.location,
    this.brand,
    required this.branchId,
  });

  factory MasterItem.fromMap(Map<String, dynamic> map) {
    return MasterItem(
      id: map['id'],
      sku: map['sku'],
      itemClass: map['itemClass'],
      description: map['description'],
      location: map['location'],
      brand: map['brand'],
      branchId: map['branchId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'itemClass': itemClass,
      'description': description,
      'location': location,
      'brand': brand,
      'branchId': branchId,
    };
  }
}
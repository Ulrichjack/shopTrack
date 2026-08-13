
class ProductEntity {
  final String id;
  final String shopId;
  final String name;
  final double buyPrice;
  final double sellPrice;
  final int quantity;
  final int minQuantity;
  final String? barcode;
  final String? photoUrl;
  /// Étiquette d'affichage en mode inventaire (sac, bouteille, casier…).
  final String? unit;

  ProductEntity({
    required this.id,
    required this.shopId,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.minQuantity,
    this.barcode,
    this.photoUrl,
    this.unit,
  });

  ProductEntity copyWith({
    String? id,
    String? shopId,
    String? name,
    double? buyPrice,
    double? sellPrice,
    int? quantity,
    int? minQuantity,
    String? barcode,
    String? photoUrl,
    String? unit,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      barcode: barcode ?? this.barcode,
      photoUrl: photoUrl ?? this.photoUrl,
      unit: unit ?? this.unit,
    );
  }
}
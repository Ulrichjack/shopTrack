import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.shopId,
    required super.name,
    required super.buyPrice,
    required super.sellPrice,
    required super.quantity,
    required super.minQuantity,
    super.barcode,
    super.photoUrl,
  });

  // Transforme le JSON de Supabase en ProductModel (Dart)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      shopId: json['shop_id'], // On lit le snake_case de la DB
      name: json['name'],
      buyPrice: (json['buy_price'] as num).toDouble(),
      sellPrice: (json['sell_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      minQuantity: json['min_quantity'] as int,
      barcode: json['barcode'],
      photoUrl: json['photo_url']
    );
  }

  // Transforme le ProductModel (Dart) en JSON pour l'envoyer à Supabase
  Map<String, dynamic> toJson() {
    return {
      // Pas besoin d'envoyer l'ID si on crée un nouveau produit, Supabase le génère
      'shop_id': shopId, // On envoie en snake_case pour la DB
      'name': name,
      'buy_price':buyPrice,
      'sell_price':sellPrice,
      'quantity':quantity,
      'min_quantity':minQuantity,
      'barcode':barcode,
      'photo_url':photoUrl
    };
  }
}
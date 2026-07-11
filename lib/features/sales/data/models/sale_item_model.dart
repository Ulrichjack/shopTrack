// lib/features/sales/data/models/sale_item_model.dart

import '../../domain/entities/sale_item_entity.dart';

class SaleItemModel extends SaleItemEntity {
  SaleItemModel({
    required super.id,
    required super.saleId,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.sellPrice,
    required super.buyPrice,
    required super.profit,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'].toString(),
      saleId: json['sale_id'].toString(),
      productId: json['product_id'].toString(),
      productName: json['product_name'].toString(),
      quantity: int.parse(json['quantity'].toString()),
      sellPrice: double.parse(json['sell_price'].toString()),
      buyPrice: double.parse(json['buy_price'].toString()),
      profit: double.parse(json['profit'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Pas d'ID, Supabase le génère
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'sell_price': sellPrice,
      'buy_price': buyPrice,
      'profit': profit,
    };
  }
}
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
      id: json['id'],
      saleId: json['sale_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'] as int,
      sellPrice: (json['sell_price'] as num).toDouble(),
      buyPrice: (json['buy_price'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
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
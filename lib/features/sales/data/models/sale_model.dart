

import 'package:shoptrack/features/sales/data/models/sale_item_model.dart';
import 'package:shoptrack/features/sales/domain/entities/sale_entity.dart';

class SaleModel extends SaleEntity {

  SaleModel({
    required super.id,
    required super.shopId,
    required super.userId,
    required super.totalAmount,
    required super.totalProfit,
    required super.createdAt,
    required super.items
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
        id:json['id'],
        shopId:json ['shop_id'],
        userId:json ['user_id'],
        totalAmount:(json['total_amount'] as num).toDouble(),
        totalProfit: (json['total_profit'] as num).toDouble(),
        createdAt: DateTime(json['created_at']),
        items: (json['sale_items'] as List<dynamic>?)
          ?.map((itemJson) => SaleItemModel.fromJson(itemJson))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'shop_id': shopId,
      'user_id': userId,
      'total_amount': totalAmount,
      'total_profit': totalProfit,
    };
  }

}
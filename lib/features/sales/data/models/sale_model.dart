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
    required super.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    // On gère la liste des items de manière sécurisée
    List<SaleItemModel> parsedItems = [];
    if (json['sale_items'] != null) {
      final List<dynamic> itemsList = json['sale_items'] as List<dynamic>;
      parsedItems = itemsList
          .map(
            (itemJson) =>
                SaleItemModel.fromJson(itemJson as Map<String, dynamic>),
          )
          .toList();
    }

    return SaleModel(
      id: json['id'].toString(),
      shopId: json['shop_id'].toString(),
      userId: json['user_id'].toString(),
      // On force la conversion en double
      totalAmount: double.parse(json['total_amount'].toString()),
      totalProfit: double.parse(json['total_profit'].toString()),
      createdAt: DateTime.parse(json['created_at'].toString()),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'user_id': userId,
      'total_amount': totalAmount,
      'total_profit': totalProfit,
    };
  }
}

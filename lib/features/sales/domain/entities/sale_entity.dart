import 'package:shoptrack/features/sales/domain/entities/sale_item_entity.dart';

class SaleEntity {
  final String id;
  final String shopId;
  final String userId;
  final double totalAmount;
  final double totalProfit;
  final DateTime createdAt;
  final List<SaleItemEntity> items;

  SaleEntity({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.totalAmount,
    required this.totalProfit,
    required this.createdAt,
    required this.items,
  });
}

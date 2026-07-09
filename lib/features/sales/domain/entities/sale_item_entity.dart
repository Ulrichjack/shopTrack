
class SaleItemEntity {

  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final int quantity;
  final double sellPrice;
  final double buyPrice;
  final double profit;

  SaleItemEntity({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellPrice,
    required this.buyPrice,
    required this.profit,
});

}
// lib/features/sales/data/repositories/sale_repository_impl.dart

import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_remote_datasource.dart';
import '../models/sale_model.dart';
import '../models/sale_item_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDataSource remoteDataSource;
  SaleRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> createSale(SaleEntity sale) async {
    // On transforme la liste d'Entités en liste de Models
    final itemsModel = sale.items
        .map(
          (item) => SaleItemModel(
            id: item.id,
            saleId: item.saleId,
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
            buyPrice: item.buyPrice,
            profit: item.profit,
          ),
        )
        .toList();

    final saleModel = SaleModel(
      id: sale.id,
      shopId: sale.shopId,
      userId: sale.userId,
      totalAmount: sale.totalAmount,
      totalProfit: sale.totalProfit,
      createdAt: sale.createdAt,
      items: itemsModel,
    );

    await remoteDataSource.createSale(saleModel);
  }

  @override
  Future<List<SaleEntity>> getDailySales(String shopId, DateTime date) async {
    return remoteDataSource.getDailySales(shopId, date);
  }
}

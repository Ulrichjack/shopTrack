

import 'package:shoptrack/features/sales/domain/entities/sale_entity.dart';

abstract class SaleRepository {

  Future<void> createSale(SaleEntity sales);

  Future<List<SaleEntity>> getDailySales(String shopId, DateTime date);
}


import 'package:shoptrack/features/products/domain/entities/product_entity.dart';

abstract class ProductRepository {

  Future<List<ProductEntity>> getProduct(String shopId);

  Future<void> createProduct(ProductEntity product);

  Future<ProductEntity?> getProductByBarCode(String barcode, String shopId);
  
}
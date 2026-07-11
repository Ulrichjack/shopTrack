import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ProductEntity>> getProduct(String shopId) async {
    return remoteDataSource.getProducts(shopId);
  }

  @override
  Future<void> createProduct(ProductEntity product) async {
    // On convertit l'Entity en Model pour que le DataSource l'accepte
    final productModel = ProductModel(
      id: product.id,
      shopId: product.shopId,
      name: product.name,
      buyPrice: product.buyPrice,
      sellPrice: product.sellPrice,
      quantity: product.quantity,
      minQuantity: product.minQuantity,
      barcode: product.barcode,
      photoUrl: product.photoUrl,
    );

    await remoteDataSource.createProduct(productModel);
  }

  @override
  Future<ProductEntity?> getProductByBarCode(String barcode, String shopId) async {
    return remoteDataSource.getProductByBarCode(barcode, shopId);
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    final productModel = ProductModel(
      id: product.id,
      shopId: product.shopId,
      name: product.name,
      buyPrice: product.buyPrice,
      sellPrice: product.sellPrice,
      quantity: product.quantity,
      minQuantity: product.minQuantity,
      barcode: product.barcode,
      photoUrl: product.photoUrl,
    );
    await remoteDataSource.updateProduct(productModel);
  }

}
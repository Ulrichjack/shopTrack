import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final SupabaseClient supabase;

  ProductRemoteDataSource(this.supabase);

  // Récupérer les produits depuis Supabase
  Future<List<ProductModel>> getProducts(String shopId) async {
    final response = await supabase
        .from('products')
        .select()
        .eq('shop_id', shopId);
    return response.map((json) => ProductModel.fromJson(json)).toList();
  }

  // Créer un produit dans Supabase
  Future<void> createProduct(ProductModel product) async {
    await supabase.from('products').insert(product.toJson());
  }

  Future<ProductModel?> getProductByBarCode(
    String barcode,
    String shopId,
  ) async {
    // maybeSingle() dit à Supabase : "Renvoie-moi 1 seul résultat, ou null s'il n'y a rien"
    final response = await supabase
        .from('products')
        .select()
        .eq('barcode', barcode)
        .eq('shop_id', shopId)
        .maybeSingle();

    if (response == null) {
      return null; // Produit non trouvé
    }

    return ProductModel.fromJson(response);
  }

  // Mettre à jour un produit existant
  Future<void> updateProduct(ProductModel product) async {
    await supabase
        .from('products')
        .update(product.toJson())
        .eq('id', product.id);
  }
}

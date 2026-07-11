import 'dart:io' as import_io;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';

// 1. On crée les instances de nos classes (DataSource et Repository)
final productRemoteDataSourceProvider = Provider((ref) {
  return ProductRemoteDataSource(Supabase.instance.client);
});

final productRepositoryProvider = Provider((ref) {
  final remoteDataSource = ref.read(productRemoteDataSourceProvider);
  return ProductRepositoryImpl(remoteDataSource);
});

// 2. Le Notifier qui va gérer l'état de la liste des produits (Loading, Error, Data)
class ProductNotifier extends AsyncNotifier<List<ProductEntity>> {

  // Cette méthode est appelée automatiquement au démarrage pour charger la liste
  @override
  Future<List<ProductEntity>> build() async {
    return _fetchProducts();
  }

  // Fonction privée pour récupérer les produits
  Future<List<ProductEntity>> _fetchProducts() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non connecté');

    // 👇 CORRECTION : On va chercher la boutique dont l'utilisateur est membre
    final memberResponse = await Supabase.instance.client
        .from('shop_members')
        .select('shop_id')
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();

    if (memberResponse == null) {
      throw Exception('Aucune boutique trouvée pour cet utilisateur');
    }

    final shopId = memberResponse['shop_id'] as String;

    final repository = ref.read(productRepositoryProvider);
    return repository.getProduct(shopId);
  }

  // Fonction pour ajouter un produit
  Future<void> addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required int minQuantity,
    String? barcode,
    // 👇 1. On accepte le fichier image
    import_io.File? imageFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final memberResponse = await Supabase.instance.client
          .from('shop_members')
          .select('shop_id')
          .eq('user_id', userId)
          .limit(1)
          .single();
      final shopId = memberResponse['shop_id'] as String;

      String? photoUrl;

      // 👇 2. LA MAGIE DE L'UPLOAD EST ICI 👇
      if (imageFile != null) {
        // On crée un nom unique pour l'image
        final fileName = '${shopId}_${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg';

        // On l'envoie dans le "Storage" de Supabase (dossier 'product-photos')
        await Supabase.instance.client.storage
            .from('product-photos')
            .upload(fileName, imageFile);

        // On récupère le lien public de l'image pour l'afficher plus tard
        photoUrl = Supabase.instance.client.storage
            .from('product-photos')
            .getPublicUrl(fileName);
      }

      final String finalBarcode = (barcode == null || barcode.trim().isEmpty)
          ? 'QR-${DateTime.now().millisecondsSinceEpoch}'
          : barcode.trim();


      final repository = ref.read(productRepositoryProvider);

      final newProduct = ProductEntity(
        id: '',
        shopId: shopId,
        name: name,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        quantity: quantity,
        minQuantity: minQuantity,
        barcode: finalBarcode,
        photoUrl: photoUrl, // 👇 3. On sauvegarde l'URL dans la base de données
      );

      await repository.createProduct(newProduct);
      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      // 👇 Correction de la double erreur signalée par Claude
      state = AsyncValue.data(await _fetchProducts());
      rethrow;
    }
  }

  // Fonction pour modifier un produit
  Future<void> updateProduct({
    required String id,
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required int minQuantity,
    String? barcode,
    String? existingPhotoUrl,
    import_io.File? newImageFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final memberResponse = await Supabase.instance.client
          .from('shop_members')
          .select('shop_id')
          .eq('user_id', userId!)
          .single();
      final shopId = memberResponse['shop_id'] as String;

      String? finalPhotoUrl = existingPhotoUrl;

      // Si l'utilisateur a choisi une NOUVELLE image, on l'upload
      if (newImageFile != null) {
        final fileName = '${shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('product-photos')
            .upload(fileName, newImageFile);
        finalPhotoUrl = Supabase.instance.client.storage
            .from('product-photos')
            .getPublicUrl(fileName);
      }

      final String finalBarcode = (barcode == null || barcode.trim().isEmpty)
          ? 'QR-${DateTime.now().millisecondsSinceEpoch}'
          : barcode.trim();

      final repository = ref.read(productRepositoryProvider);

      final updatedProduct = ProductEntity(
        id: id,
        shopId: shopId,
        name: name,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        quantity: quantity,
        minQuantity: minQuantity,
        barcode: finalBarcode,
        photoUrl: finalPhotoUrl,
      );

      await repository.updateProduct(updatedProduct);
      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      state = AsyncValue.data(await _fetchProducts());
      rethrow;
    }
  }

}

// 3. Le Provider final que l'écran va écouter
final productProvider = AsyncNotifierProvider<ProductNotifier, List<ProductEntity>>(() {
  return ProductNotifier();
});
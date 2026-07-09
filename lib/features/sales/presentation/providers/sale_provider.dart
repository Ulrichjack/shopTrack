import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_item_entity.dart';
import '../../data/datasources/sale_remote_datasource.dart';
import '../../data/repositories/sale_repository_impl.dart';
import 'cart_provider.dart';

final saleRemoteDataSourceProvider = Provider((ref) {
  return SaleRemoteDataSource(Supabase.instance.client);
});

final saleRepositoryProvider = Provider((ref) {
  final remoteDataSource = ref.read(saleRemoteDataSourceProvider);
  return SaleRepositoryImpl(remoteDataSource);
});

class SaleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createSale(List<SaleItemEntity> items, double totalAmount, double totalProfit) async {
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

      final sale = SaleEntity(
        id: '', // Généré par Supabase
        shopId: shopId,
        userId: userId,
        totalAmount: totalAmount,
        totalProfit: totalProfit,
        createdAt: DateTime.now(),
        items: items,
      );

      final repository = ref.read(saleRepositoryProvider);
      await repository.createSale(sale);

      // On vide le panier après la vente !
      ref.read(cartProvider.notifier).clearCart();

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final saleProvider = AsyncNotifierProvider<SaleNotifier, void>(() {
  return SaleNotifier();
});
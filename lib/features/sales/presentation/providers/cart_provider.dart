// lib/features/sales/presentation/providers/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sale_item_entity.dart';
import '../../../products/domain/entities/product_entity.dart';

// Le Notifier qui gère la liste des articles dans le panier
class CartNotifier extends Notifier<List<SaleItemEntity>> {
  @override
  List<SaleItemEntity> build() {
    return []; // Au début, le panier est vide
  }

  // 1. Ajouter un produit au panier
  void addProduct(ProductEntity product) {
    // On vérifie si le produit est déjà dans le panier
    final existingIndex = state.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      // S'il y est déjà, on augmente juste la quantité de +1
      updateQuantity(existingIndex, state[existingIndex].quantity + 1);
    } else {
      // Sinon, on l'ajoute comme nouvel article
      final newItem = SaleItemEntity(
        id: '', // Sera généré par Supabase plus tard
        saleId: '', // Sera lié plus tard
        productId: product.id,
        productName: product.name,
        quantity: 1,
        sellPrice: product.sellPrice, // Prix par défaut, modifiable
        buyPrice: product.buyPrice,
        profit: product.sellPrice - product.buyPrice,
      );

      // On met à jour l'état avec la nouvelle liste
      state = [...state, newItem];
    }
  }

  // 2. Modifier la quantité d'un article
  void updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      // Si la quantité tombe à 0, on supprime l'article du panier
      removeItem(index);
      return;
    }

    final item = state[index];
    final updatedItem = SaleItemEntity(
      id: item.id,
      saleId: item.saleId,
      productId: item.productId,
      productName: item.productName,
      quantity: newQuantity,
      sellPrice: item.sellPrice,
      buyPrice: item.buyPrice,
      // On recalcule le bénéfice total de cette ligne
      profit: (item.sellPrice - item.buyPrice) * newQuantity,
    );

    // On remplace l'ancien article par le nouveau dans la liste
    final newState = [...state];
    newState[index] = updatedItem;
    state = newState;
  }

  // 3. Modifier le prix de vente (Négociation avec le client)
  void updatePrice(int index, double newPrice) {
    final item = state[index];
    final updatedItem = SaleItemEntity(
      id: item.id,
      saleId: item.saleId,
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      sellPrice: newPrice, // Le nouveau prix négocié
      buyPrice: item.buyPrice,
      // On recalcule le bénéfice avec le nouveau prix
      profit: (newPrice - item.buyPrice) * item.quantity,
    );

    final newState = [...state];
    newState[index] = updatedItem;
    state = newState;
  }

  // 4. Supprimer un article du panier
  void removeItem(int index) {
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }

  // 5. Vider le panier complètement (après la vente)
  void clearCart() {
    state = [];
  }
}

// Le Provider principal du panier
final cartProvider = NotifierProvider<CartNotifier, List<SaleItemEntity>>(() {
  return CartNotifier();
});

// --- PROVIDERS CALCULÉS (Pour l'affichage en temps réel) ---

// Calcule le Total à payer
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(
    0,
    (total, item) => total + (item.sellPrice * item.quantity),
  );
});

// Calcule le Bénéfice total de la vente
final cartProfitProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (total, item) => total + item.profit);
});

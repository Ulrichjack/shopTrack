import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../providers/cart_provider.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  String _searchQuery = '';

  Widget _buildProductPhoto(ProductEntity product) {
    final photoUrl = product.photoUrl?.trim();
    final fallback = ColoredBox(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark),
      ),
    );

    final Widget image;
    if (photoUrl == null || photoUrl.isEmpty) {
      image = fallback;
    } else {
      image = photoUrl.startsWith('/') || photoUrl.contains('cache/')
          ? Image.file(
              File(photoUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            )
          : CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => ColoredBox(
                color: AppColors.primaryLight,
                child: const Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => fallback,
            );
    }

    return SizedBox.square(
      dimension: 54,
      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: image),
    );
  }

  // Fonction pour ouvrir le panneau du bas (BottomSheet) pour modifier prix/quantité
  void _showAddToCartBottomSheet(BuildContext context, ProductEntity product) {
    // 👇 1. On regarde combien de cet article sont DÉJÀ dans le panier
    final cartItems = ref.read(cartProvider);
    int quantityAlreadyInCart = 0;
    for (var item in cartItems) {
      if (item.productId == product.id) {
        quantityAlreadyInCart = item.quantity;
      }
    }

    // 👇 2. On calcule le stock RÉELLEMENT disponible
    final int maxAvailable = product.quantity - quantityAlreadyInCart;

    // 👇 3. Si tout le stock est déjà dans le panier, on bloque !
    if (maxAvailable <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Stock insuffisant : tout le stock est déjà dans le panier !',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return; // On n'ouvre même pas le panneau
    }

    // On initialise la quantité à 1 (ou au max disponible si c'est 0, mais bloqué au-dessus)
    int tempQty = 1;
    final priceController = TextEditingController(
      text: product.sellPrice.toInt().toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double currentPrice =
                double.tryParse(priceController.text) ?? product.sellPrice;
            final double currentProfit =
                (currentPrice - product.buyPrice) * tempQty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 👇 On affiche le stock restant disponible
                  Text(
                    'Disponible pour ajout : $maxAvailable',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),

                  // Modification du prix
                  const Text(
                    'Prix de vente négocié (F)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) => setModalState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Modification de la quantité
                  const Text(
                    'Quantité',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: tempQty > 1
                            ? () => setModalState(() => tempQty--)
                            : null,
                        icon: Icon(
                          Icons.remove_circle_outline,
                          size: 32,
                          color: tempQty > 1 ? AppColors.primary : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '$tempQty',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 👇 4. On bloque le bouton "+" si on atteint le maxAvailable
                      IconButton(
                        onPressed: tempQty < maxAvailable
                            ? () => setModalState(() => tempQty++)
                            : null,
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 32,
                          color: tempQty < maxAvailable
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Affichage du bénéfice en petit
                  Center(
                    child: Text(
                      'Bénéfice estimé : ${CurrencyFormatter.format(currentProfit)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      final finalPrice =
                          double.tryParse(priceController.text) ??
                          product.sellPrice;
                      for (int i = 0; i < tempQty; i++) {
                        final modifiedProduct = product.copyWith(
                          sellPrice: finalPrice,
                        );
                        ref
                            .read(cartProvider.notifier)
                            .addProduct(modifiedProduct);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Ajouter au panier',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle Vente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final String? scannedCode = await context.push('/scanner');
              if (scannedCode == null || scannedCode.trim().isEmpty) return;

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recherche du produit…'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              try {
                final foundProduct = await ref
                    .read(productProvider.notifier)
                    .findByBarcode(scannedCode);
                if (!context.mounted) return;

                if (foundProduct == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Produit introuvable sur ce téléphone et dans la boutique en ligne.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                _showAddToCartBottomSheet(context, foundProduct);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recherche impossible : $error'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un article...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Liste des produits
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur: $err')),
              data: (products) {
                final filtered = products
                    .where(
                      (p) =>
                          p.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) &&
                          p.quantity > 0,
                    )
                    .toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return ListTile(
                      leading: _buildProductPhoto(product),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Stock: ${product.quantity}'),
                      trailing: Text(
                        CurrencyFormatter.format(product.sellPrice),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _showAddToCartBottomSheet(context, product),
                    );
                  },
                );
              },
            ),
          ),

          // Panneau du bas : Résumé du panier
          if (cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cartItems.length} article(s)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        CurrencyFormatter.format(cartTotal),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/sale-confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Encaisser',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_mode_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../../shared/widgets/product_picker.dart';
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
    // La quantité se tape aussi bien qu'elle se martèle : les deux gestes
    // écrivent ici.
    final qtyController = TextEditingController(text: '1');

    // Le mode est lu ICI, une seule fois, et jamais dans la feuille.
    //
    // Une feuille modale est une ROUTE : elle vit dans un autre morceau de
    // l'arbre et survit au widget qui l'ouvre. Un `ref.watch` posé dedans
    // enregistre une dépendance qui ne se démonte pas proprement à la
    // fermeture — Flutter lève alors « '_dependents.isEmpty': is not true »
    // et l'écran devient rouge. Vu le 30/08/2026, en ajoutant l'affichage du
    // bénéfice et de l'étiquette de stock.
    //
    // Le mode Patron ne change pas pendant qu'on choisit une quantité : une
    // valeur capturée suffit, et c'est le même geste que
    // `ProviderScope.containerOf(context, listen: false)` employé ailleurs
    // pour survivre à une boîte de dialogue.
    final estPatron = ref.read(appModeProvider).value ?? false;

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
                  // Le stock restant. Chiffré pour tout le monde tant que
                  // `stockChiffreVisibleParLeVendeur` vaut vrai — voir la
                  // décision commentée sur cette constante.
                  //
                  // Les parenthèses comptent : `??` lie moins fort que `||`,
                  // donc `value ?? false || drapeau` s'évalue en
                  // `value ?? (false || drapeau)` et le drapeau ne sert plus à
                  // rien dès que `value` a une valeur.
                  Text(
                    (estPatron || stockChiffreVisibleParLeVendeur)
                        ? 'Disponible pour ajout : $maxAvailable'
                        : 'En stock',
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
                  // Le nombre se TAPE, il ne se martèle pas.
                  //
                  // Vingt crédits téléphoniques, c'était vingt appuis sur
                  // « + » avant de pouvoir valider — signalé deux fois pendant
                  // une simulation de vente, et la seconde fois la saisie s'est
                  // arrêtée là. Ce qui interrompt celui qui teste interrompra
                  // celui qui vend, tous les jours : c'est le geste le plus
                  // répété de l'application.
                  //
                  // Les boutons restent : pour un ou deux articles ils sont
                  // plus rapides que le clavier. Les deux gestes écrivent au
                  // même endroit.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: tempQty > 1
                            ? () => setModalState(() {
                                tempQty--;
                                qtyController.text = '$tempQty';
                              })
                            : null,
                        icon: Icon(
                          Icons.remove_circle_outline,
                          size: 32,
                          color: tempQty > 1 ? AppColors.primary : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 88,
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // On ne CORRIGE pas pendant la frappe.
                          //
                          // Ramener la valeur dans les bornes à chaque touche
                          // rend impossible de taper « 20 » quand le stock est
                          // de 15 : le « 2 » passerait, le « 0 » serait refusé
                          // sur un champ déjà remis à 15. On laisse écrire, on
                          // signale, et on empêche seulement de valider.
                          onChanged: (valeur) => setModalState(() {
                            tempQty = int.tryParse(valeur.trim()) ?? 0;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: tempQty < maxAvailable
                            ? () => setModalState(() {
                                tempQty++;
                                qtyController.text = '$tempQty';
                              })
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

                  if (tempQty > maxAvailable)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Il n\'en reste que $maxAvailable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Le bénéfice se déduit du prix d'achat : l'afficher revient
                  // à le donner. Un vendeur qui lit « bénéfice estimé : 500 »
                  // sur un article vendu 3 500 connaît la marge de la boutique
                  // en une soustraction, produit par produit.
                  //
                  // Le calcul, lui, reste : la ligne de vente doit porter son
                  // bénéfice figé pour que le bilan du patron soit juste.
                  if (estPatron) ...[
                    Center(
                      child: Text(
                        'Bénéfice estimé : '
                        '${CurrencyFormatter.format(currentProfit)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 12),

                  ElevatedButton(
                    // Désactivé plutôt que corrigé en douce : le commerçant
                    // voit ce qu'il a tapé, lit pourquoi ça ne passe pas, et
                    // décide. Une valeur ramenée en silence l'aurait laissé
                    // valider autre chose que ce qu'il croyait vendre.
                    onPressed: (tempQty < 1 || tempQty > maxAvailable)
                        ? null
                        : () {
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

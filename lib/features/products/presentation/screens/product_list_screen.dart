import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_mode_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_provider.dart';
import '../widgets/archived_products_sheet.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  String _selectedFilter =
      'Tous'; // Peut être 'Tous', 'Stock bas', ou 'Rupture'

  // Calcule la valeur totale du stock (Prix d'achat * Quantité)
  double _calculateTotalStockValue(List<ProductEntity> products) {
    return products.fold(
      0,
      (total, product) => total + (product.buyPrice * product.quantity),
    );
  }

  /// « 15 produits · 274 articles · 1 en rupture ».
  ///
  /// La valeur totale seule ne fait rien décider : elle dit combien d'argent
  /// dort sur l'étagère, jamais sur laquelle. Le nombre d'articles complète le
  /// tableau — mais c'est le compte des ruptures qui fait décrocher le
  /// téléphone pour rappeler le fournisseur, et il n'apparaissait nulle part
  /// sans faire défiler toute la liste.
  ///
  /// Les stocks faibles ne sont mentionnés **que** s'il n'y a aucune rupture :
  /// deux alertes côte à côte se neutralisent, et la rupture est la plus
  /// urgente des deux.
  String _resumeDuStock(List<ProductEntity> products) {
    final articles = products.fold<int>(0, (t, p) => t + p.quantity);
    final ruptures = products.where((p) => p.quantity <= 0).length;
    final faibles = products
        .where((p) => p.quantity > 0 && p.quantity <= p.minQuantity)
        .length;

    final morceaux = <String>[
      '${products.length} produit${products.length > 1 ? 's' : ''}',
      '$articles article${articles > 1 ? 's' : ''}',
      if (ruptures > 0)
        '$ruptures en rupture'
      else if (faibles > 0)
        '$faibles à racheter bientôt',
    ];
    return morceaux.join(' · ');
  }

  /// « 20 sacs » plutôt que « 20 » : le nombre seul ne dit pas dans quoi il
  /// compte, et un carton n'est pas une bouteille.
  static String _unitSuffix(ProductEntity product) {
    final unit = product.unit?.trim();
    return (unit == null || unit.isEmpty) ? '' : ' $unit';
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        // `false` — et c'est LUI qui décide, pas le `floating` de l'entête.
        // Tant qu'il valait `true`, le coordinateur redonnait la priorité à
        // l'entête au premier geste vers le haut : elle revenait recouvrir la
        // ligne qu'on venait chercher, quoi qu'on mette sur le SliverAppBar.
        // À `false`, elle ne réapparaît qu'une fois la liste revenue en haut.
        floatHeaderSlivers: false,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('Mon stock'),
            // Ni `floating` ni `snap` : l'entête ne revient qu'une fois
            // remonté tout en haut. En `floating`, il réapparaissait au
            // moindre geste vers le haut et recouvrait la ligne qu'on venait
            // chercher — on le repoussait, il revenait.
            floating: false,
            snap: false,
            elevation: 0,
            actions: [
              // Réservé au patron : ressortir un produit change ce que le
              // vendeur peut vendre.
              ValueListenableBuilder<bool>(
                valueListenable: bossModeAccess,
                builder: (context, estPatron, _) => estPatron
                    ? IconButton(
                        tooltip: 'Produits archivés',
                        icon: const Icon(Icons.inventory_2_outlined),
                        onPressed: () => showArchivedProductsSheet(context),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            // 1. Zone de Recherche, Filtres et Valeur du stock (En-tête)
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 👇 AFFICHAGE DE LA VALEUR DU STOCK CORRIGÉ 👇
                  productsAsync.when(
                    data: (products) {
                      // La valeur totale est calculée au prix d'ACHAT : elle le
                      // révèle dès qu'on divise par la quantité. Un vendeur voit
                      // donc le résumé (produits, articles, ruptures) mais pas
                      // le montant.
                      final estPatron =
                          ref.watch(appModeProvider).value ?? false;
                      final totalValue = _calculateTotalStockValue(products);
                      final resume = _resumeDuStock(products);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withOpacity(
                            0.5,
                          ), // Fond légèrement plus sombre pour faire ressortir
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    estPatron
                                        ? 'Valeur totale du stock'
                                        : 'Mon stock',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    resume,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (estPatron)
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    CurrencyFormatter.format(totalValue),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Barre de recherche
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un article...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtres (Tous / Stock bas / Rupture)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tous'),
                        const SizedBox(width: 10),
                        _buildFilterChip('Stock bas'),
                        const SizedBox(width: 10),
                        _buildFilterChip('Rupture'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Liste des produits
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, stack) => Center(child: Text('Erreur : $err')),
                data: (allProducts) {
                  // 👇 LOGIQUE DE FILTRAGE 👇
                  var filteredProducts = allProducts.where((product) {
                    // Filtre par recherche texte
                    final matchesSearch = product.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );

                    // Filtre par statut de stock
                    bool matchesFilter = true;
                    if (_selectedFilter == 'Stock bas') {
                      matchesFilter =
                          product.quantity <= product.minQuantity &&
                          product.quantity > 0;
                    } else if (_selectedFilter == 'Rupture') {
                      matchesFilter = product.quantity <= 0;
                    }

                    return matchesSearch && matchesFilter;
                  }).toList();

                  // 👇 NOUVEAU : TRI POUR METTRE LES RUPTURES EN BAS 👇
                  filteredProducts.sort((a, b) {
                    // Si 'a' est en rupture (<=0) et 'b' a du stock, 'a' va en bas
                    if (a.quantity <= 0 && b.quantity > 0) return 1;
                    // Si 'b' est en rupture et 'a' a du stock, 'b' va en bas
                    if (b.quantity <= 0 && a.quantity > 0) return -1;
                    // Sinon, ordre alphabétique — insensible à la casse et
                    // aux accents, sinon « Éponge » et « dolait » atterrissent
                    // après « Sucre » (cf. `comparerNomsProduits`).
                    return comparerNomsProduits(a.name, b.name);
                  });

                  if (filteredProducts.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun produit trouvé.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  // 👇 AFFICHAGE DE LA LISTE 👇
                  return ListView.separated(
                    // Marge basse volontairement large : le bouton flottant
                    // « Ajouter un article » recouvre sinon le dernier produit.
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final bool isOutOfStock = product.quantity <= 0;
                      final bool isLowStock =
                          product.quantity <= product.minQuantity &&
                          !isOutOfStock;

                      return GestureDetector(
                        onTap: () {
                          context.push('/product-detail', extra: product);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isOutOfStock
                                  ? Colors.red.shade200
                                  : (isLowStock
                                        ? Colors.orange.shade200
                                        : Colors.grey.shade200),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Image
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: product.photoUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: product.photoUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                              ),
                              const SizedBox(width: 12),

                              // Infos (Nom + Badge)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        // Si c're en rupture, on grise un peu le nom
                                        color: isOutOfStock
                                            ? Colors.grey
                                            : AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    // Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOutOfStock
                                            ? Colors.red.shade50
                                            : (isLowStock
                                                  ? Colors.orange.shade50
                                                  : Colors.green.shade50),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isOutOfStock
                                            ? 'Rupture : 0'
                                            : (isLowStock
                                                  ? 'Stock bas : ${product.quantity}${_unitSuffix(product)}'
                                                  : 'En stock : ${product.quantity}${_unitSuffix(product)}'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isOutOfStock
                                              ? Colors.red.shade700
                                              : (isLowStock
                                                    ? Colors.orange.shade800
                                                    : Colors.green.shade700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Prix
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(product.sellPrice),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock
                                          ? Colors.grey
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'vente',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/add-product'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajouter un article',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Helper pour dessiner les boutons de filtres
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

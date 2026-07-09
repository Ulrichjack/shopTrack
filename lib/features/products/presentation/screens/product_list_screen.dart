// lib/features/products/presentation/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/product_provider.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Tous'; // Peut être 'Tous', 'Stock bas', ou 'Rupture'

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon stock'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Zone de Recherche et Filtres (En-tête)
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
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
                const SizedBox(height: 16),

                // Filtres (Tous / Stock bas / Rupture)
                Row(
                  children: [
                    _buildFilterChip('Tous'),
                    const SizedBox(width: 10),
                    _buildFilterChip('Stock bas'),
                    const SizedBox(width: 10),
                    _buildFilterChip('Rupture'),
                  ],
                ),
              ],
            ),
          ),

          // 2. Liste des produits
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text('Erreur : $err')),
              data: (allProducts) {

                // 👇 LOGIQUE DE FILTRAGE 👇
                final filteredProducts = allProducts.where((product) {
                  // Filtre par recherche texte
                  final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());

                  // Filtre par statut de stock
                  bool matchesFilter = true;
                  if (_selectedFilter == 'Stock bas') {
                    matchesFilter = product.quantity <= product.minQuantity && product.quantity > 0;
                  } else if (_selectedFilter == 'Rupture') {
                    matchesFilter = product.quantity == 0;
                  }

                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('Aucun produit trouvé.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                // 👇 AFFICHAGE DE LA LISTE 👇
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final bool isOutOfStock = product.quantity == 0;
                    final bool isLowStock = product.quantity <= product.minQuantity && !isOutOfStock;

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
                            color: isOutOfStock ? Colors.red.shade200 : (isLowStock ? Colors.orange.shade200 : Colors.grey.shade200),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
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
                                child: Image.network(product.photoUrl!, fit: BoxFit.cover),
                              )
                                  : const Icon(Icons.image, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),

                            // Infos (Nom + Badge)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Badge
                                  // Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: product.quantity <= 0 ? Colors.red.shade50 : (isLowStock ? Colors.orange.shade50 : Colors.green.shade50),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      product.quantity <= 0
                                          ? 'Rupture : 0'
                                          : (isLowStock ? 'Stock bas : ${product.quantity}' : 'En stock : ${product.quantity}'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: product.quantity <= 0 ? Colors.red.shade700 : (isLowStock ? Colors.orange.shade800 : Colors.green.shade700),
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
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                const Text('vente', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/add-product'),
        child: const Icon(Icons.add, color: Colors.white),
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
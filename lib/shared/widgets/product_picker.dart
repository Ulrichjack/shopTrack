import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/sync/sync_service.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/products/presentation/providers/product_provider.dart';

/// Le vendeur voit-il la quantité exacte, ou seulement « Disponible » ?
///
/// **Décidé le 27/08/2026 : il la voit.** On livre l'option la plus utilisable
/// et on restreindra si la cliente le demande après usage — pas l'inverse.
///
/// Les deux arguments, pour que la décision se reprenne en connaissance :
///
/// - **Cacher le nombre gêne la vente.** Un client demande vingt pièces, il en
///   reste trois : la vendeuse commence, le bouton « + » se bloque, et elle
///   découvre la limite au milieu de la vente, devant le client. Elle ne peut
///   pas non plus signaler « il ne reste que trois savons, commande ».
/// - **Cacher le nombre n'empêche pas de se servir.** Ce qui attrape un
///   manquant, c'est le comptage — il l'attrape que le nombre ait été vu ou
///   non. Le gain réel est mince : sans le chiffre, on ne sait pas calibrer un
///   prélèvement pour qu'il passe inaperçu. C'est un frein, pas une barrière.
///
/// Le prix d'achat et la marge, eux, restent masqués sans discussion : aucune
/// utilité pour vendre, et ils révèlent ce que gagne le patron.
///
/// Basculer se fait ici, en un mot — `etiquetteStock` est le seul endroit qui
/// met le stock en forme.
const bool stockChiffreVisibleParLeVendeur = true;

/// Ce qu'on montre du stock, selon qui regarde.
String etiquetteStock(int quantite, {required bool modePatron}) {
  if (modePatron || stockChiffreVisibleParLeVendeur) {
    return 'Stock : $quantite';
  }
  return quantite > 0 ? 'Disponible' : 'Rupture';
}

/// Nombre de ventes par produit, pour remonter en tête ceux qui servent le
/// plus. Un vendeur d'œufs ne doit pas faire défiler 20 articles pour
/// retrouver celui qu'il vend toute la journée.
final productSaleCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(localDbProvider);
  final rows = await db.select(db.localSaleItems).get();
  final counts = <String, int>{};
  for (final row in rows) {
    counts[row.productId] = (counts[row.productId] ?? 0) + 1;
  }
  return counts;
});

/// Sélecteur de produit partagé par les écrans du module cycles.
/// Une liste déroulante native affiche mal le stock et se manipule mal sur un
/// petit écran : on ouvre plutôt une feuille avec des lignes lisibles.
class ProductPicker extends ConsumerWidget {
  const ProductPicker({
    super.key,
    required this.selectedProductId,
    required this.onChanged,
    this.label = 'Produit',
  });

  final String? selectedProductId;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur : $e'),
      data: (products) {
        final selected = products
            .where((p) => p.id == selectedProductId)
            .firstOrNull;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: products.isEmpty
                ? null
                : () => _openSheet(context, ref, products),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == null
                      ? Colors.grey.shade300
                      : AppColors.primary,
                  width: selected == null ? 1 : 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: selected == null
                        ? Colors.grey.shade400
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected?.name ??
                              (products.isEmpty
                                  ? 'Aucun produit — crée-en un dans Stock'
                                  : 'Choisir un produit'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selected == null
                                ? Colors.grey.shade500
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (selected != null)
                          Text(
                            etiquetteStock(
                              selected.quantity,
                              modePatron:
                                  ref.watch(appModeProvider).value ?? false,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    List<ProductEntity> products,
  ) async {
    final counts = ref.read(productSaleCountsProvider).value ?? {};
    // Les plus vendus d'abord : c'est ce que le vendeur cherche 9 fois sur 10.
    final ordered = [...products]
      ..sort((a, b) {
        final byUse = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
        return byUse != 0 ? byUse : a.name.compareTo(b.name);
      });

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProductSheet(
        label: label,
        products: ordered,
        counts: counts,
        selectedProductId: selectedProductId,
        modePatron: ref.read(appModeProvider).value ?? false,
      ),
    );

    if (picked != null) onChanged(picked);
  }
}

class _ProductSheet extends StatefulWidget {
  const _ProductSheet({
    required this.label,
    required this.products,
    required this.counts,
    required this.selectedProductId,
    required this.modePatron,
  });

  final String label;
  final List<ProductEntity> products;
  final Map<String, int> counts;
  final String? selectedProductId;

  /// Passé depuis le sélecteur : cette feuille est un `StatefulWidget` simple,
  /// elle n'a pas de `ref` pour lire le mode elle-même.
  final bool modePatron;

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.products
        : widget.products
              .where((p) => p.name.toLowerCase().contains(query))
              .toList();

    return Padding(
      // Remonte la feuille au-dessus du clavier pendant la recherche.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: widget.products.length > 8,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('Aucun produit trouvé'))
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = visible[index];
                          final isSelected =
                              product.id == widget.selectedProductId;
                          final sold = widget.counts[product.id] ?? 0;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? AppColors.primaryLight
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : Colors.grey.shade600,
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(() {
                              final stock = etiquetteStock(
                                product.quantity,
                                modePatron: widget.modePatron,
                              );
                              // Le nombre de ventes n'est pas sensible : il
                              // dit ce qui part, pas ce que ça coûte.
                              return sold > 0
                                  ? '$stock · vendu $sold fois'
                                  : stock;
                            }()),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, product.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

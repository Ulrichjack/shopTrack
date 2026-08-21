import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_provider.dart';

/// Le placard : ce qu'on a retiré de la vente sans effacer son passé.
///
/// Sans cet écran, archiver serait un aller sans retour — un produit rangé par
/// erreur deviendrait introuvable, et la seule issue serait d'en recréer un
/// autre, qui repartirait sans son historique.
Future<void> showArchivedProductsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: const _ArchivedProductsBody(),
    ),
  );
}

class _ArchivedProductsBody extends ConsumerStatefulWidget {
  const _ArchivedProductsBody();

  @override
  ConsumerState<_ArchivedProductsBody> createState() =>
      _ArchivedProductsBodyState();
}

class _ArchivedProductsBodyState extends ConsumerState<_ArchivedProductsBody> {
  late Future<List<ProductEntity>> _archives;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  void _recharger() {
    _archives = ref.read(productProvider.notifier).fetchArchivedProducts();
  }

  Future<void> _ressortir(ProductEntity produit) async {
    await ref.read(productProvider.notifier).unarchiveProduct(produit.id);
    if (!mounted) return;
    setState(_recharger);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produit.name} est revenu dans ton stock.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Produits archivés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<ProductEntity>>(
            future: _archives,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              final produits = snapshot.data ?? const <ProductEntity>[];
              if (produits.isEmpty) return const _PlacardVide();

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: produits.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final produit = produits[i];
                  return ListTile(
                    title: Text(produit.name),
                    subtitle: Text(
                      produit.archivedAt == null
                          ? 'Archivé'
                          : 'Archivé le '
                                '${DateFormat('dd/MM/yyyy').format(produit.archivedAt!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: () => _ressortir(produit),
                      child: const Text('Ressortir'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlacardVide extends StatelessWidget {
  const _PlacardVide();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun produit archivé.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Archiver un produit le retire du stock et du comptage sans '
              'toucher à tes anciens rapports.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

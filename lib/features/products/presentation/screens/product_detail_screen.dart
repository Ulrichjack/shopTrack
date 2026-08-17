import 'dart:io'; // 👈 NOUVEAU : Indispensable pour lire les images locales hors-ligne
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/providers/shop_settings_provider.dart';
import '../providers/product_provider.dart';
import '../providers/product_history_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductEntity product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  // 👇 NOUVELLE FONCTION : Affiche l'image qu'elle soit sur internet ou locale
  Widget _buildProductImage(String? url, {BoxFit fit = BoxFit.contain}) {
    if (url == null || url.isEmpty) {
      return const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      );
    }

    // Si c'est un fichier local (chemin sur le téléphone)
    if (url.startsWith('/') || url.contains('cache/')) {
      return Image.file(
        File(url),
        fit: fit,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    }

    // Si c'est une image en ligne (Supabase)
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }

  void _showAddStockBottomSheet(
    BuildContext context,
    ProductEntity currentProduct,
  ) {
    // Le prix d'achat ne se saisit qu'en inventaire périodique : c'est le
    // seul mode où il valorise le rapport. Ailleurs, le formulaire reste tel
    // qu'il était.
    final isPeriodic =
        ref.read(shopSettingsProvider).value?.saleCaptureMode == 'periodic';
    final quantityController = TextEditingController();
    // Pré-rempli au dernier prix connu : le plus souvent il n'a pas bougé,
    // et le commerçant valide sans rien retaper.
    final costController = TextEditingController(
      text: currentProduct.buyPrice.toInt().toString(),
    );
    final sellController = TextEditingController(
      text: currentProduct.sellPrice.toInt().toString(),
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Nouvel arrivage',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Article : ${currentProduct.name}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantité à ajouter',
                        prefixIcon: const Icon(Icons.add_box),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Les deux prix au même endroit : celui qui paie plus cher
                    // remonte son prix de vente dans la foulée. C'est un seul
                    // geste, et c'est le moment où il connaît les deux chiffres.
                    // Chacun est figé sur l'arrivage, donc les périodes déjà
                    // closes ne bougent plus quand un tarif change ensuite.
                    if (isPeriodic) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: costController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Prix d\'achat (F)',
                                helperText: 'Ce que tu as payé',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: sellController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Prix de vente (F)',
                                helperText: 'Ce que tu demandes',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 4),

                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final qty = int.tryParse(quantityController.text);
                              if (qty == null || qty <= 0) return;

                              setModalState(() => isSaving = true);

                              try {
                                await ref
                                    .read(productProvider.notifier)
                                    .addStock(
                                      currentProduct,
                                      qty,
                                      unitCost: isPeriodic
                                          ? double.tryParse(
                                              costController.text.trim(),
                                            )
                                          : null,
                                      sellPrice: isPeriodic
                                          ? double.tryParse(
                                              sellController.text.trim(),
                                            )
                                          : null,
                                    );
                                ref.invalidate(
                                  productHistoryProvider(currentProduct.id),
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Stock ajouté avec succès !',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirmer la recharge',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    String? photoUrl,
    String productId,
  ) {
    if (photoUrl == null || photoUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withAlpha(
          240,
        ), // Fond noir comme sur WhatsApp
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: 'product_photo_$productId', // 👈 Transition fluide
              child: _buildProductImage(photoUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBox(
    String title,
    double amount,
    Color color, {
    bool isProfit = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isProfit ? AppColors.success : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isProfit ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isProfit ? AppColors.primaryDark : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isProfit ? AppColors.primaryDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsList = ref.watch(productProvider).value ?? [];
    ProductEntity currentProduct = widget.product;

    for (var p in productsList) {
      if (p.id == widget.product.id) {
        currentProduct = p;
        break;
      }
    }

    final double profit = currentProduct.sellPrice - currentProduct.buyPrice;
    final bool isLowStock =
        currentProduct.quantity <= currentProduct.minQuantity;
    final bool isOutOfStock = currentProduct.quantity == 0;

    final historyAsync = ref.watch(productHistoryProvider(currentProduct.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.push('/edit-product', extra: currentProduct),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 👇 NOUVEL AFFICHAGE IMAGE AVEC ZOOM WHATSAPP 👇
            GestureDetector(
              onTap: () => _showFullScreenImage(
                context,
                currentProduct.photoUrl,
                currentProduct.id,
              ),
              child: Hero(
                tag: 'product_photo_${currentProduct.id}',
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white, // Fond blanc propre
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        currentProduct.photoUrl != null &&
                            currentProduct.photoUrl!.isNotEmpty
                        ? _buildProductImage(
                            currentProduct.photoUrl,
                            fit: BoxFit.contain,
                          )
                        : const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    currentProduct.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (currentProduct.barcode != null)
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_2,
                      color: AppColors.primaryDark,
                      size: 36,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            currentProduct.name,
                            textAlign: TextAlign.center,
                          ),
                          content: SizedBox(
                            width: 250,
                            height: 250,
                            child: Center(
                              child: QrImageView(
                                data: currentProduct.barcode!,
                                version: QrVersions.auto,
                                size: 200.0,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Fermer',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),

            Text(
              currentProduct.barcode != null
                  ? 'Code : ${currentProduct.barcode}'
                  : 'Aucun code scanné',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                _buildPriceBox(
                  'Achat',
                  currentProduct.buyPrice,
                  AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                _buildPriceBox(
                  'Vente',
                  currentProduct.sellPrice,
                  AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                _buildPriceBox(
                  'Bénéfice',
                  profit,
                  AppColors.primary,
                  isProfit: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock actuel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        // « 8 sacs » quand l'unité est renseignée : « unités »
                        // ne veut rien dire pour un sac de riz.
                        '${currentProduct.quantity} '
                        '${(currentProduct.unit ?? '').trim().isEmpty ? 'unités' : currentProduct.unit!.trim()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Statut',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.red.shade100
                              : (isLowStock
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOutOfStock
                              ? 'Rupture'
                              : (isLowStock ? 'Stock critique' : 'En stock'),
                          style: TextStyle(
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'HISTORIQUE RÉCENT (15 derniers)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Erreur : $err'),
              data: (history) {
                if (history.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Aucun mouvement pour ce produit.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length > 15 ? 15 : history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final isRecharge = item.type == 'recharge';
                    final isComptage = item.type == 'comptage';
                    final dateStr = DateFormat(
                      'dd/MM/yy HH:mm',
                    ).format(item.date);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isComptage
                                ? Colors.orange.shade50
                                : (isRecharge
                                      ? Colors.blue.shade50
                                      : AppColors.primaryLight),
                            child: Icon(
                              isComptage
                                  ? Icons.checklist
                                  : (isRecharge
                                        ? Icons.add_shopping_cart
                                        : Icons.point_of_sale),
                              color: isComptage
                                  ? Colors.orange.shade800
                                  : (isRecharge
                                        ? Colors.blue
                                        : AppColors.primaryDark),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label ??
                                      (isRecharge
                                          ? 'Recharge de stock'
                                          : 'Vente'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                // Un comptage n'est pas un mouvement : il
                                // constate un stock, il ne l'augmente ni ne
                                // le diminue. D'où l'absence de + ou −.
                                isComptage
                                    ? '${item.quantity}'
                                    : (isRecharge
                                          ? '+ ${item.quantity}'
                                          : '- ${item.quantity}'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isComptage
                                      ? Colors.orange.shade800
                                      : (isRecharge
                                            ? Colors.blue
                                            : AppColors.primaryDark),
                                ),
                              ),
                              if (!isRecharge &&
                                  !isComptage &&
                                  item.totalAmount != null)
                                Text(
                                  CurrencyFormatter.format(item.totalAmount!),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStockBottomSheet(context, currentProduct),
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_box, color: Colors.white),
        label: const Text(
          'Ajouter Stock',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

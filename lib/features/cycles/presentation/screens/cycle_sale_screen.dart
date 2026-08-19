import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/cycle_result_calculator.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../sales/domain/entities/sale_item_entity.dart';
import '../../../sales/presentation/providers/sale_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/product_unit_provider.dart';
import '../../../../shared/widgets/product_picker.dart';

class CycleSaleScreen extends ConsumerStatefulWidget {
  const CycleSaleScreen({super.key});

  @override
  ConsumerState<CycleSaleScreen> createState() => _CycleSaleScreenState();
}

class _CycleSaleScreenState extends ConsumerState<CycleSaleScreen> {
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedProductId;
  LocalProductUnit? _selectedUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Le récapitulatif doit se recalculer à chaque frappe : sans ça, on peut
    // vendre un carton entier en croyant vendre un plateau.
    _quantityController.addListener(_refresh);
    _priceController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Vente d'un produit ordinaire depuis ce même écran : le mode cycles est
  /// une couche par-dessus le socle simple, pas un remplacement. Un produit
  /// sans unité ni cycle doit rester vendable sans changer d'écran ni
  /// re-sélectionner le produit.
  Future<void> _submitSimple(ProductEntity product) async {
    final quantity = int.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    if (quantity == null || quantity <= 0 || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantité et prix sont obligatoires'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final item = SaleItemEntity(
        id: '',
        saleId: '',
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        sellPrice: price,
        buyPrice: product.buyPrice,
        profit: (price - product.buyPrice) * quantity,
        // Pas de cycleId : ligne de vente ordinaire, identique à celle que
        // produit l'écran de vente classique.
      );

      await ref
          .read(saleProvider.notifier)
          .createSale([item], price * quantity, item.profit);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vente enregistrée !'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanSyncError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submit({
    required String productId,
    required String productName,
    required String cycleId,
    required double cycleUnitCost,
  }) async {
    final unit = _selectedUnit;
    final quantity = int.tryParse(_quantityController.text);
    final pricePerUnit = double.tryParse(_priceController.text);

    if (unit == null || quantity == null || quantity <= 0 ||
        pricePerUnit == null || pricePerUnit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unité, quantité et prix sont obligatoires'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final conversion = UnitSaleConversion.convert(
      quantityInUnit: quantity,
      pricePerUnit: pricePerUnit,
      ratioToBase: unit.ratioToBase,
    );
    final quantityInBase = conversion.quantityInBase;
    final unitSellPricePerBase = conversion.pricePerBaseUnit;

    setState(() => _isSaving = true);
    try {
      final item = SaleItemEntity(
        id: '',
        saleId: '',
        productId: productId,
        productName: '$productName (${unit.unitName})',
        quantity: quantityInBase,
        sellPrice: unitSellPricePerBase,
        buyPrice: cycleUnitCost,
        profit: (unitSellPricePerBase - cycleUnitCost) * quantityInBase,
        cycleId: cycleId,
        unitId: unit.id,
      );

      await ref
          .read(saleProvider.notifier)
          .createSale([item], conversion.lineTotal, item.profit);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vente enregistrée !'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Sélecteur de quantité − / + repris de l'écran de vente classique :
  /// en pleine vente on tape rarement au clavier, on incrémente.
  /// [maximum] borne le « + » pour ne jamais dépasser le stock disponible.
  Widget _buildStepper({required int maximum, String? unite}) {
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    void setQuantity(int value) {
      _quantityController.text = value.toString();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: quantity > 1 ? () => setQuantity(quantity - 1) : null,
          icon: Icon(
            Icons.remove_circle_outline,
            size: 36,
            color: quantity > 1 ? AppColors.primary : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            // Saisissable, et pas seulement incrémentable : vendre 200 œufs au
            // détail demandait 199 appuis sur le « + ». Les deux boutons
            // restent pour les petites quantités, où ils vont plus vite qu'un
            // clavier qu'il faut ouvrir puis refermer.
            SizedBox(
              width: 110,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                // Le stock disponible reste la limite, quel que soit le
                // chemin : le « + » s'arrête déjà à `maximum`, la saisie
                // libre doit s'y arrêter aussi.
                onChanged: (texte) {
                  final saisie = int.tryParse(texte);
                  if (saisie != null && saisie > maximum) {
                    setQuantity(maximum);
                  }
                },
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            if (unite != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  unite,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: quantity < maximum
              ? () => setQuantity(quantity + 1)
              : null,
          icon: Icon(
            Icons.add_circle_outline,
            size: 36,
            color: quantity < maximum
                ? AppColors.primary
                : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  /// Récapitulatif temps réel : montre ce qui va RÉELLEMENT être vendu, en
  /// unités de base, avant de valider.
  Widget _buildSummary({
    required double unitCost,
    required int stockDisponible,
    required String productName,
  }) {
    final unit = _selectedUnit;
    final quantity = int.tryParse(_quantityController.text);
    final pricePerUnit = double.tryParse(_priceController.text);

    if (unit == null || quantity == null || quantity <= 0) {
      return const SizedBox.shrink();
    }

    final conversion = UnitSaleConversion.convert(
      quantityInUnit: quantity,
      pricePerUnit: pricePerUnit ?? 0,
      ratioToBase: unit.ratioToBase,
    );
    final stockInsuffisant = conversion.quantityInBase > stockDisponible;
    final profit =
        (conversion.pricePerBaseUnit - unitCost) * conversion.quantityInBase;
    final perte = pricePerUnit != null && profit < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stockInsuffisant || perte
            ? AppColors.error.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stockInsuffisant || perte
              ? AppColors.error
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu vends $quantity ${unit.unitName} '
            '= ${conversion.quantityInBase} $productName',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text('Stock disponible : $stockDisponible $productName'),
          if (pricePerUnit != null) ...[
            const SizedBox(height: 6),
            Text(
              'Total encaissé : ${CurrencyFormatter.format(conversion.lineTotal)}',
            ),
            Text(
              'Coût réel de ce stock : '
              '${CurrencyFormatter.format(unitCost * conversion.quantityInBase)}',
            ),
            const SizedBox(height: 6),
            Text(
              profit >= 0
                  ? 'Bénéfice : ${CurrencyFormatter.format(profit)}'
                  : 'PERTE : ${CurrencyFormatter.format(profit)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? AppColors.primaryDark : AppColors.error,
              ),
            ),
          ],
          if (stockInsuffisant) ...[
            const SizedBox(height: 8),
            const Text(
              'Stock insuffisant : cette vente sera refusée.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Formulaire de vente ordinaire, affiché dans ce même écran quand le
  /// produit choisi n'a pas de cycle/unité. Le produit reste sélectionné :
  /// aucun aller-retour, aucune re-saisie.
  Widget _buildSimpleSale(ProductEntity product, String raison) {
    final quantity = int.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);
    final stockInsuffisant = quantity != null && quantity > product.quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$raison On le vend donc à l\'unité, comme un article ordinaire.',
            style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Quantité vendue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildStepper(maximum: product.quantity),
        const SizedBox(height: 20),
        const Text(
          'Prix unitaire (FCFA)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        if (quantity != null && quantity > 0 && price != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: stockInsuffisant
                  ? AppColors.error.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: stockInsuffisant
                    ? AppColors.error
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock disponible : ${product.quantity}'),
                const SizedBox(height: 6),
                Text(
                  'Total encaissé : '
                  '${CurrencyFormatter.format(price * quantity)}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Bénéfice : ${CurrencyFormatter.format((price - product.buyPrice) * quantity)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: price >= product.buyPrice
                        ? AppColors.primaryDark
                        : AppColors.error,
                  ),
                ),
                if (stockInsuffisant) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Stock insuffisant : cette vente sera refusée.',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _submitSimple(product),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Enregistrer la vente',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nouvelle vente')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductPicker(
                selectedProductId: _selectedProductId,
                onChanged: (value) {
                  final product = productsAsync.value
                      ?.where((p) => p.id == value)
                      .firstOrNull;
                  setState(() {
                    _selectedProductId = value;
                    _selectedUnit = null;
                    // Prêt à confirmer : 1 unité au prix habituel. Le vendeur
                    // n'a plus rien à taper dans le cas courant.
                    _quantityController.text = '1';
                    _priceController.text =
                        product?.sellPrice.round().toString() ?? '';
                  });
                },
              ),

              if (_selectedProductId != null)
                Consumer(
                  builder: (context, ref, _) {
                    final productId = _selectedProductId!;
                    final cycleAsync = ref.watch(
                      openCycleForProductProvider(productId),
                    );
                    final unitsAsync = ref.watch(
                      productUnitsProvider(productId),
                    );
                    final product = productsAsync.value?.firstWhere(
                      (p) => p.id == productId,
                    );

                    return cycleAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Erreur : $e'),
                      data: (cycle) {
                        if (cycle == null) {
                          if (product == null) return const SizedBox.shrink();
                          return _buildSimpleSale(
                            product,
                            "Ce produit n'a pas de cycle ouvert.",
                          );
                        }
                        return unitsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text('Erreur : $e'),
                          data: (units) {
                            if (units.isEmpty) {
                              if (product == null) {
                                return const SizedBox.shrink();
                              }
                              return _buildSimpleSale(
                                product,
                                "Ce produit n'a pas d'unité de vente "
                                '(plateau, carton…).',
                              );
                            }
                            final cycleUnitCost = cycle.quantityReceived > 0
                                ? cycle.purchaseCost / cycle.quantityReceived
                                : 0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 24),
                                const Text(
                                  'Tu vends par…',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Boutons plutôt qu'une liste déroulante : les
                                // unités sont peu nombreuses et le choix doit
                                // être visible d'un coup d'œil en pleine vente.
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: units.map((u) {
                                    final isSelected =
                                        _selectedUnit?.id == u.id;
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedUnit = u;
                                        _quantityController.text = '1';
                                        // Prix conseillé pré-rempli dès le
                                        // choix de l'unité : plus qu'à
                                        // confirmer dans le cas courant.
                                        final marge =
                                            cycle.referenceMarginPerUnit;
                                        if (marge != null &&
                                            cycle.quantityReceived > 0) {
                                          _priceController.text =
                                              ((cycle.purchaseCost + marge) /
                                                      cycle.quantityReceived *
                                                      u.ratioToBase)
                                                  .round()
                                                  .toString();
                                        }
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.grey.shade300,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              u.unitName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '= ${u.ratioToBase} '
                                              '${product?.name ?? "unités"}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected
                                                    ? Colors.white70
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Quantité vendue (dans cette unité)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                _buildStepper(
                                  // Borne au stock réel converti dans l'unité
                                  // choisie : impossible de proposer 3 cartons
                                  // quand il n'en reste qu'un et demi.
                                  maximum: _selectedUnit == null
                                      ? 0
                                      : (product?.quantity ?? 0) ~/
                                            _selectedUnit!.ratioToBase,
                                  unite: _selectedUnit?.unitName,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Prix par unité vendue (FCFA)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: 2000',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                // Le « gain de référence » du cycle sert ici,
                                // et nulle part ailleurs : il propose un prix,
                                // il n'entre JAMAIS dans le bénéfice réel.
                                if (_selectedUnit != null &&
                                    cycle.referenceMarginPerUnit != null &&
                                    cycle.quantityReceived > 0)
                                  Builder(
                                    builder: (context) {
                                      final suggested =
                                          (cycle.purchaseCost +
                                              cycle
                                                  .referenceMarginPerUnit!) /
                                          cycle.quantityReceived *
                                          _selectedUnit!.ratioToBase;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Prix conseillé : '
                                                '${CurrencyFormatter.format(suggested)} '
                                                'par ${_selectedUnit!.unitName}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  _priceController.text =
                                                      suggested
                                                          .round()
                                                          .toString(),
                                              child: const Text('Utiliser'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                const SizedBox(height: 24),
                                _buildSummary(
                                  unitCost: cycleUnitCost,
                                  stockDisponible: product?.quantity ?? 0,
                                  productName: product?.name ?? 'unités',
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isSaving || product == null
                                      ? null
                                      : () => _submit(
                                          productId: productId,
                                          productName: product.name,
                                          cycleId: cycle.id,
                                          cycleUnitCost: cycleUnitCost,
                                        ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text(
                                    'Enregistrer la vente',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../providers/inventory_count_provider.dart';

class InventoryCountScreen extends ConsumerStatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  ConsumerState<InventoryCountScreen> createState() =>
      _InventoryCountScreenState();
}

class _InventoryCountScreenState extends ConsumerState<InventoryCountScreen> {
  final _searchController = TextEditingController();
  final _quantityControllers = <String, TextEditingController>{};
  final _savingProductIds = <String>{};
  final _recountingProductIds = <String>{};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String productId) {
    return _quantityControllers.putIfAbsent(
      productId,
      TextEditingController.new,
    );
  }

  Future<void> _saveLine(InventoryCountLine line) async {
    final controller = _controllerFor(line.product.id);
    final quantity = int.tryParse(controller.text.trim());
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisis une quantité entière positive ou nulle.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _savingProductIds.add(line.product.id));
    try {
      await ref
          .read(inventoryCountActionsProvider)
          .saveCount(productId: line.product.id, countedQuantity: quantity);
      if (!mounted) return;

      controller.clear();
      _recountingProductIds.remove(line.product.id);
      FocusScope.of(context).unfocus();

      // Pas de message de confirmation : la carte du produit affiche déjà
      // « X compté(s) » et l'écart, et la barre de progression avance. Sur un
      // tour de 15 produits, un bandeau par validation masquait le bas de
      // l'écran à chaque fois sans rien apprendre de plus. Les erreurs, elles,
      // gardent leur message — il faut interrompre.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanSyncError(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingProductIds.remove(line.product.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(inventoryCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Comptage du stock')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _query = value.trim().toLowerCase());
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer la recherche',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  overviewAsync.when(
                    loading: () => const _ProgressCard.loading(),
                    error: (_, _) => const _ProgressCard(
                      counted: 0,
                      total: 0,
                      isComplete: false,
                    ),
                    data: (overview) => _ProgressCard(
                      counted: overview.countedProducts,
                      total: overview.totalProducts,
                      isComplete: overview.isRoundComplete,
                      isFirstRound: overview.isFirstRound,
                      periodStartedAt: overview.periodStartedAt,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: overviewAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => _LoadError(
                  message: humanSyncError(error),
                  onRetry: () => ref.invalidate(inventoryCountProvider),
                ),
                data: (overview) {
                  if (overview.lines.isEmpty) {
                    return const _EmptyProducts();
                  }

                  final visibleLines = overview.lines
                      .where(
                        (line) =>
                            _query.isEmpty ||
                            line.product.name.toLowerCase().contains(_query),
                      )
                      .toList();

                  if (visibleLines.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun produit ne correspond à la recherche.',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(inventoryCountProvider);
                      await ref.read(inventoryCountProvider.future);
                    },
                    child: ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                      itemCount: visibleLines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final line = visibleLines[index];
                        final recounting = _recountingProductIds.contains(
                          line.product.id,
                        );
                        return _ProductCountCard(
                          line: line,
                          controller: _controllerFor(line.product.id),
                          isSaving: _savingProductIds.contains(line.product.id),
                          showInput: !line.isCounted || recounting,
                          canRecount: overview.isRoundComplete && !recounting,
                          onSave: () => _saveLine(line),
                          onRecount: () {
                            setState(
                              () => _recountingProductIds.add(line.product.id),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.counted,
    required this.total,
    required this.isComplete,
    this.isFirstRound = true,
    this.periodStartedAt,
  }) : isLoading = false;

  const _ProgressCard.loading()
    : counted = 0,
      total = 0,
      isComplete = false,
      isFirstRound = true,
      periodStartedAt = null,
      isLoading = true;

  final int counted;
  final int total;
  final bool isComplete;
  final bool isLoading;

  /// Le geste est le même à chaque tour ; seul le rôle du comptage change.
  /// L'app l'annonce au lieu de demander au commerçant de le déclarer : deux
  /// boutons « départ » / « reste » l'obligeraient à trancher une question
  /// comptable, et un mauvais choix casserait sa période sans qu'il le voie.
  final bool isFirstRound;
  final DateTime? periodStartedAt;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : counted / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.success : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete
                    ? Icons.check_circle_outline
                    : Icons.fact_check_outlined,
                color: isComplete
                    ? AppColors.successDark
                    : AppColors.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoading
                      ? 'Chargement de la progression…'
                      : '$counted produits sur $total comptés',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isComplete
                        ? AppColors.successDark
                        : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: isLoading ? null : progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: Colors.white.withValues(alpha: 0.75),
            color: isComplete ? AppColors.successDark : AppColors.primary,
          ),
          if (!isLoading && !isComplete) ...[
            const SizedBox(height: 8),
            Text(
              isFirstRound
                  ? 'Premier comptage : tu poses ton point de départ.'
                  : periodStartedAt == null
                  ? 'Ce comptage ferme la période en cours.'
                  : 'Ce comptage ferme la période ouverte le '
                        '${DateFormat('dd/MM').format(periodStartedAt!)}.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            // Le rappel du comptage à l'aveugle n'a de valeur que la première
            // fois : ensuite c'est du texte que personne ne relit.
            if (isFirstRound) ...[
              const SizedBox(height: 4),
              const Text(
                'Compte ce que tu vois. Le stock enregistré reste caché.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProductCountCard extends StatelessWidget {
  const _ProductCountCard({
    required this.line,
    required this.controller,
    required this.isSaving,
    required this.showInput,
    required this.canRecount,
    required this.onSave,
    required this.onRecount,
  });

  final InventoryCountLine line;
  final TextEditingController controller;
  final bool isSaving;
  final bool showInput;
  final bool canRecount;
  final VoidCallback onSave;
  final VoidCallback onRecount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (line.isCounted && !showInput)
                  const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
            // Rappelle dans quoi il compte ce produit : « en sacs », « en
            // bouteilles ». Sans ça il peut compter des unités là où il
            // suivait des cartons.
            if ((line.product.unit ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'en ${line.product.unit!.trim()}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 14),
            if (showInput)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !isSaving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) {
                        if (!isSaving) onSave();
                      },
                      decoration: InputDecoration(
                        labelText: (line.product.unit ?? '').trim().isEmpty
                            ? 'Quantité comptée'
                            : 'Quantité comptée (${line.product.unit!.trim()})',
                        hintText: '0',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: isSaving ? null : onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Valider'),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${line.count!.countedQuantity} compté(s)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Écart après validation : '
                          '${_formatDifference(line.difference!)}',
                          style: TextStyle(
                            color: line.difference == 0
                                ? AppColors.successDark
                                : AppColors.warningDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Avertir, jamais refuser : un comptage est une
                        // observation, on ne discute pas avec ce que le
                        // commerçant a sous les yeux. Compter plus que
                        // possible est d'ailleurs une information — un
                        // arrivage n'a pas été enregistré — et bloquer la
                        // saisie la ferait disparaître au profit d'un chiffre
                        // inventé pour passer le formulaire.
                        if (line.difference! > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Plus que possible : arrivage oublié ?',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canRecount)
                    OutlinedButton.icon(
                      onPressed: onRecount,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Recompter'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Aucun produit à compter.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Ajoute ou synchronise les produits de la boutique avant de '
              'commencer l’inventaire.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

String _formatDifference(int difference) {
  if (difference > 0) return '+$difference';
  return '$difference';
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

  /// Le jour où le stock a réellement été compté, pour TOUTE la session.
  ///
  /// Une boutique se compte en une fois, sur un bout de papier, et se saisit
  /// plus tard : la date appartient donc au tour de comptage, pas à chaque
  /// produit. Nul tant qu'on n'y a pas touché — le comptage vaut alors pour
  /// aujourd'hui, comme avant.
  DateTime? _dateDuComptage;

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _choisirLaDate() async {
    final maintenant = DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: _dateDuComptage ?? maintenant,
      // Un an en arrière comme les pertes et les recettes ; jamais dans le
      // futur : on ne compte pas un stock qu'on n'a pas encore vu.
      firstDate: DateTime(maintenant.year - 1),
      lastDate: DateTime(maintenant.year, maintenant.month, maintenant.day),
    );
    if (choisie != null) setState(() => _dateDuComptage = choisie);
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
          .saveCount(
            productId: line.product.id,
            countedQuantity: quantity,
            dateDuComptage: _dateDuComptage,
          );
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
      body: NestedScrollView(
        // `false` — et c'est LUI qui décide, pas le `floating` de l'entête.
        // Tant qu'il valait `true`, le coordinateur redonnait la priorité à
        // l'entête au premier geste vers le haut : elle revenait recouvrir la
        // ligne qu'on venait chercher, quoi qu'on mette sur le SliverAppBar.
        // À `false`, elle ne réapparaît qu'une fois la liste revenue en haut.
        floatHeaderSlivers: false,
        headerSliverBuilder: (context, innerBoxIsScrolled) => const [
          SliverAppBar(
            title: Text('Comptage du stock'),
            // Ni `floating` ni `snap` : l'entête ne revient qu'une fois
            // remonté tout en haut. En `floating`, il réapparaissait au
            // moindre geste vers le haut et recouvrait la ligne qu'on venait
            // chercher — on le repoussait, il revenait.
            floating: false,
            snap: false,
          ),
        ],
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    _BandeauDateComptage(
                      date: _dateDuComptage,
                      onChanger: _choisirLaDate,
                    ),
                    const SizedBox(height: 12),
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
                        dateDuComptage: _dateDuComptage,
                        // On quitte le comptage pour le rapport : y revenir
                        // n'aurait aucun sens, le tour est fermé.
                        onVoirRapport: () => context.go('/inventory-report'),
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
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final line = visibleLines[index];
                          final recounting = _recountingProductIds.contains(
                            line.product.id,
                          );
                          return _ProductCountCard(
                            line: line,
                            controller: _controllerFor(line.product.id),
                            isSaving: _savingProductIds.contains(
                              line.product.id,
                            ),
                            showInput: !line.isCounted || recounting,
                            canRecount: overview.isRoundComplete && !recounting,
                            onSave: () => _saveLine(line),
                            onRecount: () {
                              setState(
                                () =>
                                    _recountingProductIds.add(line.product.id),
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
    this.dateDuComptage,
    this.onVoirRapport,
  }) : isLoading = false;

  const _ProgressCard.loading()
    : counted = 0,
      total = 0,
      isComplete = false,
      isFirstRound = true,
      periodStartedAt = null,
      dateDuComptage = null,
      onVoirRapport = null,
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

  /// La date choisie pour ce tour, ou nul pour aujourd'hui. Affichée comme
  /// borne de fin : savoir d'où part la période sans savoir où elle s'arrête
  /// ne permet pas de se repérer.
  final DateTime? dateDuComptage;
  final VoidCallback? onVoirRapport;

  /// Durée de la période, en jours pleins.
  static int _joursEntre(DateTime debut, DateTime fin) =>
      DateTime(fin.year, fin.month, fin.day)
          .difference(DateTime(debut.year, debut.month, debut.day))
          .inDays;

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
          // Tour terminé : un récapitulatif de ce qui vient d'être fermé.
          //
          // Avant, la barre se remplissait et il ne se passait rien — il
          // fallait deviner qu'on devait aller dans l'onglet Rapport. Le
          // commerçant restait sur un écran qui ne lui disait ni ce qu'il
          // venait de mesurer, ni où en voir le résultat.
          if (!isLoading && isComplete) ...[
            const SizedBox(height: 10),
            Text(
              periodStartedAt == null
                  ? 'Point de départ posé le '
                        '${DateFormat('dd/MM/yyyy').format(dateDuComptage ?? DateTime.now())}. '
                        'Le résultat viendra au prochain comptage.'
                  : 'Période fermée : du '
                        '${DateFormat('dd/MM/yyyy').format(periodStartedAt!)} au '
                        '${DateFormat('dd/MM/yyyy').format(dateDuComptage ?? DateTime.now())}'
                        ' — ${_joursEntre(periodStartedAt!, dateDuComptage ?? DateTime.now())} jour(s).',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.successDark,
              ),
            ),
            if (periodStartedAt != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onVoirRapport,
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Voir le résultat'),
                ),
              ),
            ],
          ],
          if (!isLoading && !isComplete) ...[
            const SizedBox(height: 8),
            Text(
              isFirstRound
                  ? 'Premier comptage : tu poses ton point de départ, '
                        'daté du '
                        '${DateFormat('dd/MM/yyyy').format(dateDuComptage ?? DateTime.now())}.'
                  : periodStartedAt == null
                  ? 'Ce comptage ferme la période en cours.'
                  : 'Période mesurée : du '
                        '${DateFormat('dd/MM').format(periodStartedAt!)} au '
                        '${DateFormat('dd/MM').format(dateDuComptage ?? DateTime.now())}.',
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
        padding: const EdgeInsets.all(12),
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
            // Chaque produit a sa propre période : compter le riz aujourd'hui
            // et le sucre la semaine prochaine donne deux intervalles
            // différents. Sans cette date, impossible de voir que le riz n'a
            // pas été compté depuis trois semaines pendant que le pain l'était
            // hier — et donc de savoir lequel compter en priorité.
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                line.dernierComptage == null
                    ? 'Jamais compté'
                    : 'Compté le '
                          '${DateFormat('dd/MM/yyyy').format(line.dernierComptage!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: line.dernierComptage == null
                      ? AppColors.warningDark
                      : Colors.grey.shade600,
                  fontWeight: line.dernierComptage == null
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
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

/// Rappelle à quelle date ce comptage sera enregistré, et laisse la changer.
///
/// Discret quand c'est aujourd'hui — le cas courant n'a pas à s'expliquer —
/// et franchement visible dès qu'on compte pour un jour passé, parce que
/// c'est là qu'une erreur coûte cher : une date fausse déplace la frontière
/// de la période, et les recettes basculent du mauvais côté.
class _BandeauDateComptage extends StatelessWidget {
  const _BandeauDateComptage({required this.date, required this.onChanger});

  final DateTime? date;
  final VoidCallback onChanger;

  @override
  Widget build(BuildContext context) {
    final estAujourdhui = date == null;
    final libelle = estAujourdhui
        ? "Comptage d'aujourd'hui"
        : 'Comptage du ${DateFormat('dd/MM/yyyy').format(date!)}';

    return InkWell(
      onTap: onChanger,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: estAujourdhui ? AppColors.primaryLight : AppColors.warning,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_calendar_outlined,
              size: 18,
              color: estAujourdhui
                  ? AppColors.primaryDark
                  : AppColors.warningDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                libelle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: estAujourdhui
                      ? AppColors.primaryDark
                      : AppColors.warningDark,
                ),
              ),
            ),
            Text(
              'changer',
              style: TextStyle(
                fontSize: 12,
                color: estAujourdhui
                    ? AppColors.primaryDark
                    : AppColors.warningDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

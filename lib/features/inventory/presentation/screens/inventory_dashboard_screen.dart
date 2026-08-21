import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/takings_provider.dart';
import '../../../../shared/widgets/shop_switcher.dart';

/// Accueil des boutiques en inventaire périodique.
///
/// Écran distinct plutôt qu'une variante du tableau de bord classique : en
/// mode périodique aucune vente n'est enregistrée, donc « ventes du jour »,
/// « caisse calculée » et l'écart de caisse n'existent pas. Les afficher à
/// zéro serait faux et inquiétant. Séparer évite aussi de semer des dizaines
/// de conditions dans un écran déjà trop chargé.
class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final takingsAsync = ref.watch(takingsProvider);
    final takings = takingsAsync.value ?? const <LocalShopTaking>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTaking = takings
        .where((t) => _isSameDay(t.date, today))
        .firstOrNull;

    // Le mois en cours, pour situer la journée sans attendre l'inventaire.
    final monthStart = DateTime(now.year, now.month);
    final monthTakings = takings.where(
      (t) => !t.date.isBefore(monthStart) && !t.date.isAfter(today),
    );
    final monthTotal = monthTakings.fold<double>(0, (s, t) => s + t.amount);

    // On ne compte que depuis la première recette notée : avant elle, la
    // boutique n'existait pas ou n'avait rien à déclarer. Sinon une boutique
    // créée le 13 s'entend dire « 12 jours sans recette ».
    final joursManquants = takings.isEmpty
        ? const <DateTime>[]
        : calculerJoursSansRecette(
            datesNotees: takings.map((taking) => taking.date),
            debut: _laterOf(_earliestDay(takings), monthStart),
            finExclue: today,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ShopSwitcher(
          repli: const Text(
            'ShopTrack',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(takingsProvider);
          await ref.read(takingsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              DateFormat('EEEE d MMMM', 'fr_FR').format(now),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // La recette du jour est LE chiffre de cet écran : c'est la seule
            // saisie quotidienne, et son absence fausse tout le reste.
            _TakingsCard(
              amount: todayTaking?.amount,
              onTap: () => context.push('/daily-takings'),
            ),

            if (joursManquants.isNotEmpty) ...[
              const SizedBox(height: 16),
              _BandeauJoursManquants(
                jours: joursManquants,
                onJourChoisi: (date) => context.push(
                  '/daily-takings?date=${DateFormat('yyyy-MM-dd').format(date)}',
                ),
              ),
            ],

            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _SmallCard(
                    label: 'Encaissé ce mois',
                    value: CurrencyFormatter.format(monthTotal),
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SmallCard(
                    label: 'Jours notés',
                    value: '${monthTakings.length}',
                    icon: Icons.event_available_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dans ce mode, tu ne saisis pas les ventes. Note la '
                      'recette chaque soir, compte ton stock quand tu veux, '
                      'et l\'application calcule ce qui a été vendu.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Premier jour où une recette a été notée.
  static DateTime _earliestDay(List<LocalShopTaking> takings) {
    var earliest = takings.first.date;
    for (final t in takings) {
      if (t.date.isBefore(earliest)) earliest = t.date;
    }
    return DateTime(earliest.year, earliest.month, earliest.day);
  }

  static DateTime _laterOf(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TakingsCard extends StatelessWidget {
  const _TakingsCard({required this.amount, required this.onTap});

  final double? amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final saisie = amount != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: saisie ? AppColors.primary : Colors.orange.shade700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  saisie ? 'Recette du jour' : 'Recette non notée',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              saisie ? CurrencyFormatter.format(amount!) : 'À saisir ce soir',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              saisie ? 'Toucher pour corriger' : 'Toucher pour saisir',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandeauJoursManquants extends StatelessWidget {
  const _BandeauJoursManquants({
    required this.jours,
    required this.onJourChoisi,
  });

  final List<DateTime> jours;
  final ValueChanged<DateTime> onJourChoisi;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('d MMMM', 'fr_FR');
    final joursVisibles = jours.take(3).toList();
    final joursRestants = jours.skip(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.error_outline, color: AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jours.length == 1
                      ? '1 jour sans recette notée'
                      : '${jours.length} jours sans recette notée',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final jour in joursVisibles)
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(format.format(jour)),
                        onPressed: () => onJourChoisi(jour),
                      ),
                    if (joursRestants.isNotEmpty)
                      PopupMenuButton<DateTime>(
                        tooltip: 'Voir les autres jours',
                        onSelected: onJourChoisi,
                        itemBuilder: (context) => [
                          for (final jour in joursRestants)
                            PopupMenuItem(
                              value: jour,
                              child: Text(format.format(jour)),
                            ),
                        ],
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('et ${joursRestants.length} autre(s)'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

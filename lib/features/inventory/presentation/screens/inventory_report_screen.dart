import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/inventory_reconciliation_calculator.dart';
import '../providers/inventory_report_provider.dart';
import '../utils/inventory_report_pdf.dart';

/// Le verdict de la période : ce qui est sorti, et si l'argent correspond.
class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(inventoryReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rapport de période'),
        actions: [
          IconButton(
            tooltip: 'Partager le rapport PDF',
            icon: const Icon(Icons.share_outlined),
            onPressed: reportAsync.value?.hasData != true
                ? null
                : () async {
                    final report = reportAsync.value!;
                    final prefs = await SharedPreferences.getInstance();
                    final pdf = await buildInventoryReportPdf(
                      report,
                      shopName: prefs.getString('cached_shop_name'),
                    );
                    final finPeriode = DateFormat(
                      'yyyyMMdd',
                    ).format(report.periodEnd!);
                    await Printing.sharePdf(
                      bytes: pdf,
                      filename: 'Rapport_ShopTrack_$finPeriode.pdf',
                    );
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(humanSyncError(e), textAlign: TextAlign.center),
            ),
          ),
          data: (report) => _Body(report: report),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.report});

  final InventoryPeriodReport report;

  @override
  Widget build(BuildContext context) {
    if (!report.hasData) {
      return _EmptyState(report: report);
    }

    final r = report.result;
    final format = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'Du ${format.format(report.periodStart!)} '
          'au ${format.format(report.periodEnd!)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),

        // Les réserves d'abord : un chiffre présenté comme complet alors
        // qu'il ne l'est pas est pire que pas de chiffre du tout.
        if (!report.isComplete) _IncompleteWarning(report: report),
        if (report.daysWithoutTakings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MissingTakingsWarning(days: report.daysWithoutTakings),
        ],
        if (!report.isComplete || report.daysWithoutTakings.isNotEmpty)
          const SizedBox(height: 20),

        const Text(
          'CE QUI EST SORTI',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < r.products.length; i++) ...[
                _ProductLine(product: r.products[i]),
                if (i < r.products.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),

        if (r.inconsistentProducts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InconsistentWarning(products: r.inconsistentProducts),
        ],

        const SizedBox(height: 28),
        const Text(
          'ET L\'ARGENT ?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Line('Valeur de ce qui est sorti', r.expectedRevenue),
                _Line('Recettes que tu as notées', r.actualTakings),
                const Divider(height: 24),
                _GapLine(gap: r.unexplainedGap),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),
        const Text(
          'TON RÉSULTAT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Line('Recettes encaissées', r.actualTakings),
                _Line('Coût de la marchandise sortie', -r.costOfGoodsSold),
                // Sans cette ligne le total ne tomberait pas juste dès qu'une
                // perte est déclarée, et le bénéfice paraîtrait faux.
                if (r.lossValue > 0) _Line('Pertes déclarées', -r.lossValue),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bénéfice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(r.profit),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: r.profit >= 0
                            ? AppColors.primaryDark
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductLine extends StatelessWidget {
  const _ProductLine({required this.product});

  final InventoryProductResult product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        product.productName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${CurrencyFormatter.format(product.expectedRevenue)} · '
        'gain ${CurrencyFormatter.format(product.margin)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${product.presumedSales}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'sortis',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.amount);

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Text(CurrencyFormatter.format(amount)),
        ],
      ),
    );
  }
}

/// L'écart nommé plutôt que signé : « manquant » parle, « −6 000 » se
/// déchiffre. C'est le chiffre que le commerçant ne peut pas voir sans l'app.
class _GapLine extends StatelessWidget {
  const _GapLine({required this.gap});

  final double gap;

  @override
  Widget build(BuildContext context) {
    final rounded = gap.round();
    final (label, color) = switch (rounded) {
      0 => ('Tout concorde', AppColors.primaryDark),
      < 0 => ('Il manque', AppColors.error),
      _ => ('Tu as encaissé plus', Colors.blue),
    };

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              CurrencyFormatter.format(gap.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
          ],
        ),
        // Une ligne, pas un paragraphe : le commerçant veut le chiffre et ce
        // qu'il doit vérifier, pas un cours de comptabilité. Mais l'écart ne
        // reste jamais nu — sans un mot, « il manque » se lit « on m'a volé ».
        if (rounded != 0) ...[
          const SizedBox(height: 6),
          Text(
            rounded < 0
                ? 'Vol, casse ou oubli de note : à vérifier.'
                : 'Arrivage oublié ou comptage à revoir.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }
}

class _IncompleteWarning extends StatelessWidget {
  const _IncompleteWarning({required this.report});

  final InventoryPeriodReport report;

  @override
  Widget build(BuildContext context) {
    final morceaux = <String>[
      if (report.productsNeverCounted > 0)
        '${report.productsNeverCounted} jamais compté(s)',
      if (report.productsAwaitingSecondCount > 0)
        '${report.productsAwaitingSecondCount} en attente d\'un 2e comptage',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Résultat partiel : ${morceaux.join(', ')}.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingTakingsWarning extends StatelessWidget {
  const _MissingTakingsWarning({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${days.length} jour(s) sans recette notée : l\'écart peut '
              'venir de là.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InconsistentWarning extends StatelessWidget {
  const _InconsistentWarning({required this.products});

  final List<InventoryProductResult> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Compté plus que possible sur : '
        '${products.map((p) => p.productName).join(', ')}. '
        'Un arrivage n\'a pas été enregistré.',
        style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.report});

  final InventoryPeriodReport report;

  @override
  Widget build(BuildContext context) {
    final message = report.productsAwaitingSecondCount > 0
        ? 'Tes points de repère sont posés. Compte à nouveau ton stock dans '
              'quelques jours et le rapport te dira ce qui a été vendu.'
        : 'Compte ton stock une première fois : ce sera ton point de départ.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

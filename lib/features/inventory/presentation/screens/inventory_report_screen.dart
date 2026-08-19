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
import '../../../../shared/widgets/choice_sheet.dart';

/// Le verdict de la période : ce qui est sorti, et si l'argent correspond.
class InventoryReportScreen extends ConsumerStatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  ConsumerState<InventoryReportScreen> createState() =>
      _InventoryReportScreenState();
}

class _InventoryReportScreenState extends ConsumerState<InventoryReportScreen> {
  int? _indiceComptageSelectionne;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(
      inventoryReportProvider(_indiceComptageSelectionne),
    );

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
            title: const Text('Rapport de période'),
            // Ni `floating` ni `snap` : l'entête ne revient qu'une fois
            // remonté tout en haut. En `floating`, il réapparaissait au
            // moindre geste vers le haut et recouvrait la ligne qu'on venait
            // chercher — on le repoussait, il revenait.
            floating: false,
            snap: false,
            actions: [
              // Libellé « PDF » et non une icône de partage : le commerçant ne
              // cherche pas à partager, il veut son papier. Ce qu'il en fait
              // ensuite — l'envoyer, l'imprimer, le garder — le regarde.
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
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
                        // Même geste que le bilan mensuel : l'aperçu natif,
                        // d'où l'on enregistre ou imprime. `sharePdf` ouvrait
                        // le partage sans jamais montrer le document.
                        await Printing.layoutPdf(
                          onLayout: (_) async => pdf,
                          name: 'Rapport_ShopTrack_$finPeriode.pdf',
                        );
                      },
              ),
            ],
          ),
        ],
        body: SafeArea(
          top: false,
          child: reportAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(humanSyncError(e), textAlign: TextAlign.center),
              ),
            ),
            data: (report) {
              final selectionToujoursDisponible = report.periodesDisponibles
                  .any(
                    (periode) =>
                        periode.indiceComptage == _indiceComptageSelectionne,
                  );
              final indiceAffiche = selectionToujoursDisponible
                  ? _indiceComptageSelectionne
                  : report.periodesDisponibles.firstOrNull?.indiceComptage;

              return _Body(
                report: report,
                indiceComptageSelectionne: indiceAffiche,
                onPeriodeChoisie: (indice) {
                  setState(() => _indiceComptageSelectionne = indice);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.report,
    required this.indiceComptageSelectionne,
    required this.onPeriodeChoisie,
  });

  final InventoryPeriodReport report;
  final int? indiceComptageSelectionne;
  final ValueChanged<int> onPeriodeChoisie;

  @override
  Widget build(BuildContext context) {
    if (!report.hasData) {
      return _EmptyState(report: report);
    }

    final r = report.result;
    final format = DateFormat('dd/MM/yyyy');
    final formatCourt = DateFormat('dd/MM');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Le bénéfice d'abord, en grand. C'est la seule question que le
        // commerçant se pose en ouvrant cet écran ; l'enterrer sous trois
        // sections l'obligeait à faire défiler pour la trouver.
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BÉNÉFICE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(r.profit),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: r.profit >= 0
                        ? AppColors.primaryDark
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Du ${format.format(report.periodStart!)} '
                  'au ${format.format(report.periodEnd!)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Une feuille de recherche plutôt qu'un menu déroulant : douze périodes
        // par an, soixante en cinq ans — on ne retrouve rien dans une liste
        // déroulante de soixante dates.
        if (report.periodesDisponibles.length > 1) ...[
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.event_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Période'),
              subtitle: Text(
                'Du ${formatCourt.format(report.periodStart!)} '
                'au ${formatCourt.format(report.periodEnd!)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final choix = await showChoiceSheet<PeriodeRapportInventaire>(
                  context: context,
                  titre: 'Choisir une période',
                  elements: report.periodesDisponibles,
                  libelle: (p) =>
                      'Du ${formatCourt.format(p.debut)} '
                      'au ${formatCourt.format(p.fin)}',
                );
                if (choix != null) onPeriodeChoisie(choix.indiceComptage);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Les réserves d'abord : un chiffre présenté comme complet alors
        // qu'il ne l'est pas est pire que pas de chiffre du tout.
        if (!report.isComplete) _IncompleteWarning(report: report),
        if (report.daysWithoutTakings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MissingTakingsWarning(days: report.daysWithoutTakings),
        ],
        if (report.recettesAvantLePremierComptage > 0) ...[
          const SizedBox(height: 12),
          _RecettesOrphelinesNotice(
            nombre: report.recettesAvantLePremierComptage,
          ),
        ],
        if (!report.isComplete ||
            report.daysWithoutTakings.isNotEmpty ||
            report.recettesAvantLePremierComptage > 0)
          const SizedBox(height: 16),

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

        const SizedBox(height: 20),
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
            padding: const EdgeInsets.all(12),
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

        const SizedBox(height: 20),
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
            padding: const EdgeInsets.all(12),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      visualDensity: VisualDensity.compact,
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

/// Recettes notées avant le tout premier comptage — invisibles à jamais.
///
/// En bleu et non en rouge : ce n'est pas une anomalie à corriger, c'est une
/// explication. Elles ne réapparaîtront dans aucune période, jamais, parce
/// que le premier comptage est le point de départ et qu'on ne reconstitue
/// pas le stock d'avant. Le dire évite de chercher une erreur qui n'existe
/// pas — jusqu'ici, elles s'évaporaient sans un mot.
class _RecettesOrphelinesNotice extends StatelessWidget {
  const _RecettesOrphelinesNotice({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$nombre recette(s) notée(s) avant ton premier comptage ne '
              'sont comptées dans aucune période : il n\'y avait pas encore '
              'de stock de départ pour les rapprocher.',
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
    // Deux causes très différentes : compter plus que possible accuse un
    // arrivage oublié, déclarer trop de pertes accuse la saisie de pertes.
    // Un seul message pour les deux envoyait le commerçant chercher au mauvais
    // endroit.
    final comptes = products
        .where((p) => p.hasNegativeOutflow)
        .map((p) => p.productName)
        .toList();
    final pertes = products
        .where((p) => !p.hasNegativeOutflow && p.lossesExceedOutflow)
        .map((p) => p.productName)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comptes.isNotEmpty)
            Text(
              'Compté plus que possible sur : ${comptes.join(', ')}. '
              'Un arrivage n\'a pas été enregistré.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          if (comptes.isNotEmpty && pertes.isNotEmpty)
            const SizedBox(height: 6),
          if (pertes.isNotEmpty)
            Text(
              'Plus de pertes que de marchandise sortie sur : '
              '${pertes.join(', ')}.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
        ],
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

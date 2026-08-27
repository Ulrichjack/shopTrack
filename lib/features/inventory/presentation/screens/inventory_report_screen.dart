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
        //
        // Mais seulement quand il veut dire quelque chose : voir
        // `verdictFinancierFiable`. Les sorties de dix produits comparées à la
        // caisse de vingt donnaient un excédent fantôme, affiché en grand et en
        // vert, avec la réserve en petit dessous. On retient le gros chiffre.
        if (report.verdictFinancierFiable)
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
          )
        else
          _BilanPasPret(report: report),
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
        // Le détail des réserves. Ce qui manque est déjà annoncé en haut par
        // `_BilanPasPret` ; ici on donne les dates exactes, qui sont ce dont
        // le commerçant a besoin pour aller corriger.
        if (report.daysWithoutTakings.isNotEmpty) ...[
          _MissingTakingsWarning(days: report.daysWithoutTakings),
          const SizedBox(height: 12),
        ],
        if (report.recettesAvantLePremierComptage > 0) ...[
          _RecettesOrphelinesNotice(
            nombre: report.recettesAvantLePremierComptage,
          ),
          const SizedBox(height: 12),
        ],
        if (report.daysWithoutTakings.isNotEmpty ||
            report.recettesAvantLePremierComptage > 0)
          const SizedBox(height: 4),

        const Text(
          'CE QUI A ÉTÉ VENDU',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        // Deux colonnes annoncées une fois en haut plutôt que répétées sous
        // chaque nombre : les chiffres s'alignent, et « vendus » ne se lit plus
        // comme une étiquette collée au seul produit qu'on regarde.
        const Padding(
          padding: EdgeInsets.only(right: 12, bottom: 6),
          child: Row(
            children: [
              Expanded(child: SizedBox()),
              SizedBox(
                width: _largeurColonne,
                child: Text(
                  'vendus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: _largeurColonne,
                child: Text(
                  'perdus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
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

        // Ce qu'il reste à compter pour que la PROCHAINE période s'ouvre.
        //
        // Recompter une partie de la boutique ne fait rien apparaître : le
        // rapport s'aligne sur le produit le moins compté. Sans ce bandeau, le
        // commerçant compte, revient, ne voit rien bouger, et croit que l'app
        // ne fonctionne pas. C'est arrivé — d'où ce message, qui NOMME les
        // articles au lieu d'en donner le nombre.
        //
        // Seulement quand le bilan affiché EST prêt : c'est alors une
        // information sur la période SUIVANTE, secondaire, qui a sa place en
        // bas. Quand le bilan n'est pas prêt, les mêmes noms sont déjà tout en
        // haut dans `_BilanPasPret` — les répéter ici ferait croire à deux
        // listes différentes.
        if (report.verdictFinancierFiable &&
            report.produitsAFinirDeCompter.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ResteAFinir(produits: report.produitsAFinirDeCompter),
        ],

        if (r.inconsistentProducts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InconsistentWarning(products: r.inconsistentProducts),
        ],

        // Les deux seuls blocs qui comparent le calculé à l'encaissé. Ils ne
        // valent que si les deux couvrent la même chose — sinon on ne les
        // montre pas du tout, plutôt que de les montrer sous réserve. La
        // liste des produits ci-dessus, elle, reste : ce qui est sorti d'un
        // produit compté est un fait, quel que soit l'état du reste.
        if (report.verdictFinancierFiable) ...[
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
                  _Line('Valeur de ce qui a été vendu', r.expectedRevenue),
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
                  _Line('Coût de la marchandise vendue', -r.costOfGoodsSold),
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
      ],
    );
  }
}

/// Largeur des deux colonnes de nombres. Fixe, sinon « 12 » et « 148 » ne
/// tombent pas sous le même axe et le tableau cesse d'en être un.
const double _largeurColonne = 54;

class _ProductLine extends StatelessWidget {
  const _ProductLine({required this.product});

  final InventoryProductResult product;

  @override
  Widget build(BuildContext context) {
    final perdus = product.declaredLosses;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.format(product.expectedRevenue)} · '
                  'gain ${CurrencyFormatter.format(product.margin)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _largeurColonne,
            child: Text(
              // `presumedSales`, c'est-à-dire ce qui est parti MOINS les
              // pertes déclarées. Tout le modèle du module sépare exprès les
              // deux — une sortie ne dit pas pourquoi la marchandise est
              // partie, une vente présumée si.
              '${product.presumedSales}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: _largeurColonne,
            // La casse n'apparaissait que dans le total de la boutique :
            // impossible de savoir QUEL article se casse. C'est pourtant ce
            // qui fait décider d'arrêter d'en vendre, ou de changer de
            // fournisseur. Un tiret plutôt qu'un zéro : l'œil saute les
            // lignes saines et s'arrête sur les autres.
            child: Text(
              perdus > 0 ? '$perdus' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: perdus > 0 ? 20 : 16,
                fontWeight: perdus > 0 ? FontWeight.bold : FontWeight.normal,
                color: perdus > 0 ? AppColors.error : Colors.grey.shade400,
              ),
            ),
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

/// Ce qui prend la place du bénéfice quand le chiffre ne serait pas
/// comparable à la caisse.
///
/// Deux états possibles, jamais trois : soit le commerçant a son résultat,
/// soit il a la liste de ce qui manque pour l'obtenir. Un montant assorti
/// d'une réserve est le pire des trois — il retient le montant et oublie la
/// réserve. C'est ce qui affichait « bénéfice » sur la caisse de vingt
/// produits dont dix seulement étaient comptés.
class _BilanPasPret extends StatelessWidget {
  const _BilanPasPret({required this.report});

  final InventoryPeriodReport report;

  @override
  Widget build(BuildContext context) {
    // Formulé en gestes à faire, pas en états du système : « à compter une
    // deuxième fois » se traduit tout seul en action, « en attente d'un 2e
    // comptage » demande de comprendre le modèle de données.
    final manques = <String>[
      if (report.productsNeverCounted > 0)
        '${report.productsNeverCounted} produit(s) jamais compté(s)',
      if (report.productsAwaitingSecondCount > 0)
        '${report.productsAwaitingSecondCount} produit(s) à compter une '
            'deuxième fois',
      if (report.daysWithoutTakings.isNotEmpty)
        '${report.daysWithoutTakings.length} jour(s) sans recette notée',
      // Nommés, pas comptés : ils sont rares, et le commerçant doit savoir
      // lequel vérifier. C'est presque toujours un arrivage non saisi.
      if (report.result.inconsistentProducts.isNotEmpty)
        'compté plus que possible : '
            '${report.result.inconsistentProducts.map((p) => p.productName).join(', ')}',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                color: Colors.orange.shade800,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bilan pas encore prêt',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final manque in manques)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $manque',
                style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
              ),
            ),
          // Les noms tout de suite, ici. Le bandeau qui les portait vivait
          // SOUS la liste des produits vendus : sur les 324 articles d'une
          // vraie boutique, il fallait faire défiler tout le rapport pour
          // apprendre ce qu'on devait aller compter.
          if (report.produitsAFinirDeCompter.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.produitsAFinirDeCompter.take(6).join(' · '),
              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
            ),
            if (report.produitsAFinirDeCompter.length > 6)
              InkWell(
                onTap: () =>
                    montrerListeAFinir(context, report.produitsAFinirDeCompter),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Voir les ${report.produitsAFinirDeCompter.length} produits',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            'Ton bénéfice s\'affichera ici quand tout sera compté. En '
            'attendant, tu peux voir plus bas ce qui est sorti des produits '
            'déjà comptés.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

/// La liste complète de ce qu'il reste à compter, dans une feuille déroulante.
///
/// Six noms suffisent sur une petite boutique. Sur les 324 articles d'un vrai
/// catalogue, ils ne servent à rien — et trois cents lignes dans le corps du
/// rapport le rendraient illisible.
Future<void> montrerListeAFinir(BuildContext context, List<String> produits) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, controleur) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${produits.length} produits à compter',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: controleur,
              itemCount: produits.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.check_box_outline_blank,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                title: Text(produits[index]),
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, color: AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days.length == 1
                      // « L'écart peut venir de là » datait d'avant : l'écart
                      // n'est plus affiché du tout dans ce cas, la phrase
                      // renvoyait donc à un chiffre absent de l'écran.
                      ? 'Note la recette de ce jour pour débloquer ton bilan.'
                      : 'Note la recette de ces ${days.length} jours pour '
                            'débloquer ton bilan.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                // Dire LESQUELS. L'accueil compte depuis la première recette
                // notée, le rapport depuis le premier comptage : les deux
                // chiffres diffèrent légitimement, mais un nombre seul avait
                // l'air de contredire l'autre écran. Les dates lèvent le doute
                // sans qu'on ait à expliquer deux définitions.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final jour in days)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Text(
                          DateFormat('d MMM', 'fr_FR').format(jour),
                          style: const TextStyle(fontSize: 12),
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

/// « Tu as recompté, mais il reste ceux-ci avant que le bilan suivant existe. »
class _ResteAFinir extends StatelessWidget {
  const _ResteAFinir({required this.produits});

  final List<String> produits;

  @override
  Widget build(BuildContext context) {
    final visibles = produits.take(6).toList();
    final reste = produits.length - visibles.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.playlist_add_check, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produits.length == 1
                      ? 'Un produit reste à compter pour ouvrir le bilan '
                            'suivant.'
                      : '${produits.length} produits restent à compter pour '
                            'ouvrir le bilan suivant.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  visibles.join(' · '),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (reste > 0)
                  InkWell(
                    onTap: () => montrerListeAFinir(context, produits),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Voir les ${produits.length} produits',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Ce que tu viens de compter est bien enregistré : le bilan '
                  'ne se ferme que lorsque tous ces articles ont le même '
                  'nombre de comptages.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

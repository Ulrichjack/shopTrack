import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/currency_formatter.dart';
import '../providers/inventory_report_provider.dart';

const _couleurPrincipale = PdfColor.fromInt(0xFF1D9E75);

/// Construit le rapport partageable à partir du résultat déjà calculé.
Future<Uint8List> buildInventoryReportPdf(
  InventoryPeriodReport report, {
  String? shopName,
}) async {
  final pdf = pw.Document();
  final formatDate = DateFormat('dd/MM/yyyy');
  final result = report.result;
  final nomBoutique = shopName?.trim();
  final periode = report.periodStart != null && report.periodEnd != null
      ? 'Du ${formatDate.format(report.periodStart!)} '
            'au ${formatDate.format(report.periodEnd!)}'
      : 'Période non disponible';
  final morceaux = <String>[
    if (report.productsNeverCounted > 0)
      '${report.productsNeverCounted} jamais compté(s)',
    if (report.productsAwaitingSecondCount > 0)
      '${report.productsAwaitingSecondCount} en attente d\'un 2e comptage',
  ];

  // Les mêmes réserves qu'à l'écran : un PDF présenté comme complet alors
  // qu'il ne l'est pas circule ensuite sans son contexte.
  final reserves = <String>[
    if (!report.isComplete) 'Résultat partiel : ${morceaux.join(', ')}.',
    if (report.daysWithoutTakings.isNotEmpty)
      '${report.daysWithoutTakings.length} jour(s) sans recette notée : '
          'l\'écart peut venir de là.',
    if (result.inconsistentProducts.isNotEmpty)
      'Compté plus que possible sur : '
          '${result.inconsistentProducts.map((p) => p.productName).join(', ')}.',
  ];

  pdf.addPage(
    pw.MultiPage(
      // Sur chaque page : le document circule seul, souvent photographié ou
      // renvoyé. Il doit dire d'où il vient et de quand il date.
      footer: (context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'Généré automatiquement par ShopTrack · '
          '${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())} · '
          'page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
      // Marges resserrées : avec les marges par défaut, une quinzaine de
      // produits repoussait « TON RÉSULTAT » — donc le bénéfice — en page 2,
      // et le patron recevait un papier dont le chiffre principal manquait.
      pageFormat: PdfPageFormat.a4.copyWith(
        marginTop: 32,
        marginBottom: 28,
        marginLeft: 32,
        marginRight: 32,
      ),
      build: (context) => [
        pw.Text(
          nomBoutique == null || nomBoutique.isEmpty
              ? 'ShopTrack'
              : nomBoutique,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Rapport de période',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          periode,
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        if (reserves.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          ...reserves.map(
            (reserve) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                reserve,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.orange900,
                ),
              ),
            ),
          ),
        ],
        pw.SizedBox(height: 16),
        _titreSection('CE QUI EST SORTI'),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: const ['Produit', 'Quantité sortie', 'Valeur', 'Gain'],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: _couleurPrincipale),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ),
          cellAlignment: pw.Alignment.centerRight,
          cellAlignments: const {0: pw.Alignment.centerLeft},
          columnWidths: const {
            0: pw.FlexColumnWidth(2.8),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.5),
          },
          data: result.products
              .map(
                (product) => [
                  product.productName,
                  '${product.presumedSales}',
                  CurrencyFormatter.format(product.expectedRevenue),
                  CurrencyFormatter.format(product.margin),
                ],
              )
              .toList(),
        ),
        pw.SizedBox(height: 18),
        // Insécable : sans ça le cadre se coupait en deux pages et le patron
        // recevait un « TON RÉSULTAT » réduit à une seule ligne.
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _titreSection('ET L\'ARGENT ?'),
              pw.SizedBox(height: 10),
              _encadreMontants([
                _ligneMontant(
                  'Valeur de ce qui est sorti',
                  result.expectedRevenue,
                ),
                _ligneMontant(
                  'Recettes que tu as notées',
                  result.actualTakings,
                ),
                pw.Divider(color: PdfColors.grey300),
                _ligneEcart(result.unexplainedGap),
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _titreSection('TON RÉSULTAT'),
              pw.SizedBox(height: 10),
              _encadreMontants([
                _ligneMontant('Recettes encaissées', result.actualTakings),
                _ligneMontant(
                  'Coût de la marchandise sortie',
                  -result.costOfGoodsSold,
                ),
                // Sans cette ligne, un lecteur qui refait l'addition trouve un
                // autre bénéfice que celui imprimé — sur un document partagé.
                if (result.lossValue > 0)
                  _ligneMontant('Pertes déclarées', -result.lossValue),
                pw.Divider(color: PdfColors.grey300),
                _ligneMontant(
                  'Bénéfice',
                  result.profit,
                  accentue: true,
                  couleur: result.profit >= 0
                      ? PdfColors.green700
                      : PdfColors.red700,
                ),
              ]),
            ],
          ),
        ),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _titreSection(String titre) {
  return pw.Text(
    titre,
    style: pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey700,
      letterSpacing: 1.2,
    ),
  );
}

pw.Widget _encadreMontants(List<pw.Widget> enfants) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(children: enfants),
  );
}

pw.Widget _ligneMontant(
  String libelle,
  double montant, {
  bool accentue = false,
  PdfColor couleur = PdfColors.black,
}) {
  final style = pw.TextStyle(
    fontSize: accentue ? 14 : 11,
    fontWeight: accentue ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: couleur,
  );

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Text(libelle, style: style)),
        pw.SizedBox(width: 12),
        pw.Text(CurrencyFormatter.format(montant), style: style),
      ],
    ),
  );
}

pw.Widget _ligneEcart(double ecart) {
  final arrondi = ecart.round();
  final (libelle, couleur) = switch (arrondi) {
    0 => ('Tout concorde', PdfColors.green700),
    < 0 => ('Il manque', PdfColors.red700),
    _ => ('Tu as encaissé plus', PdfColors.blue700),
  };

  return _ligneMontant(libelle, ecart.abs(), accentue: true, couleur: couleur);
}

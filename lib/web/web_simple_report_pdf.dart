import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/pdf_theme.dart';
import 'web_bilan_data.dart';

/// Résumé mensuel du mode simple à partir des seules données confirmées.
Future<void> imprimerBilanSimpleWeb({
  required String nomBoutique,
  required DateTime mois,
  required WebBilanData bilan,
}) async {
  final theme = await chargerThemePdf();
  final document = pw.Document();
  String fcfa(int valeur) =>
      '${NumberFormat.decimalPattern('fr_FR').format(valeur)} FCFA';
  int entier(Object? valeur) => valeur is num
      ? valeur.round() : int.tryParse('$valeur') ?? 0;
  pw.Widget ligne(String titre, String valeur) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 7),
    child: pw.Row(children: [
      pw.Expanded(child: pw.Text(titre)),
      pw.Text(valeur, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ]),
  );
  document.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    theme: theme,
    margin: const pw.EdgeInsets.all(42),
    build: (_) => [
      pw.Text('ShopTrack', style: pw.TextStyle(
        fontSize: 14, fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#174E46'))),
      pw.SizedBox(height: 18),
      pw.Text('Bilan mensuel', style: pw.TextStyle(
        fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.Text(nomBoutique),
      pw.Text(DateFormat('MMMM yyyy', 'fr_FR').format(mois)),
      pw.SizedBox(height: 25),
      pw.Divider(),
      ligne('Ventes enregistrées', '${bilan.nombreVentes}'),
      ligne('Chiffre d’affaires', fcfa(bilan.totalVentes)),
      if (bilan.beneficeBrutVentes != null)
        ligne('Marge brute des ventes', fcfa(bilan.beneficeBrutVentes!)),
      ligne('Dépenses de caisse', fcfa(bilan.depenses)),
      if (bilan.beneficeNetVentes != null)
        ligne('Bénéfice après dépenses', fcfa(bilan.beneficeNetVentes!)),
      ligne('Argent déplacé hors du tiroir', fcfa(bilan.deplacements)),
      pw.Divider(),
      if (bilan.clotures.isNotEmpty) ...[
        pw.SizedBox(height: 15),
        pw.Text('Journées clôturées', style: pw.TextStyle(
          fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        for (final cloture in bilan.clotures) ...[
          pw.Text('${cloture['closing_date']}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ligne('Ventes', fcfa(entier(cloture['total_sales']))),
          ligne('Bénéfice net', fcfa(entier(cloture['net_profit']))),
          ligne('Espèces comptées', fcfa(entier(cloture['physical_cash']))),
          ligne('Écart de caisse', fcfa(entier(cloture['cash_gap']))),
          if ((cloture['note'] as String?)?.isNotEmpty == true)
            pw.Text('Note : ${cloture['note']}',
                style: const pw.TextStyle(fontSize: 9)),
          pw.Divider(),
        ],
      ],
      pw.SizedBox(height: 16),
      pw.Text('Montants synchronisés avec le serveur de test. '
          'Les journées non clôturées sont comprises dans les totaux mensuels '
          'mais absentes du détail des clôtures.',
          style: const pw.TextStyle(fontSize: 9)),
      if (bilan.beneficeBrutVentes == null)
        pw.Text('Bénéfice indisponible : une vente n’a pas de coût connu.',
            style: const pw.TextStyle(fontSize: 9)),
    ],
  ));
  await Printing.layoutPdf(
    name: 'shoptrack-bilan-${mois.year}-${mois.month.toString().padLeft(2, '0')}.pdf',
    onLayout: (_) => document.save(),
  );
}

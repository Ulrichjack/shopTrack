import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/pdf_theme.dart';
import 'web_bilan_data.dart';
import 'web_bilan_detail.dart';

/// Bilan mensuel du mode simple à partir des seules données confirmées.
///
/// Même contenu que l'écran, et dans le même ordre : ce document circule seul,
/// souvent photographié et renvoyé. S'il disait autre chose que l'écran, c'est
/// lui qu'on croirait, parce que c'est lui qu'on garde.
Future<void> imprimerBilanSimpleWeb({
  required String nomBoutique,
  required DateTime mois,
  required WebBilanData bilan,
}) async {
  final theme = await chargerThemePdf();
  final document = pw.Document();
  String fcfa(int valeur) =>
      '${NumberFormat.decimalPattern('fr_FR').format(valeur)} FCFA';

  /// Ne jamais remplacer une absence par zéro.
  ///
  /// `entier(null)` valait 0, et une journée dont le tiroir n'avait jamais été
  /// compté s'imprimait « Espèces comptées : 0 FCFA, Écart : 0 FCFA » — ce qui
  /// se lit comme une caisse vérifiée et juste. Un tiret ne ment pas.
  int? entierOuNul(Object? valeur) => valeur is num ? valeur.round() : null;
  int entier(Object? valeur) => entierOuNul(valeur) ?? 0;
  String montantOuTiret(Object? valeur) {
    final montant = entierOuNul(valeur);
    return montant == null ? '—' : fcfa(montant);
  }

  pw.Widget ligne(String titre, String valeur) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 7),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Text(titre)),
        pw.Text(valeur, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
  pw.Widget titreSection(String titre) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Text(
      titre,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
  );

  final tranches = ventesParSemaine(bilan.clotures);
  final ecarts = ecartsDeCaisse(bilan.clotures);

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(42),
      // Sur chaque page : le document circule seul et doit dire d'où il vient.
      footer: (contexte) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          '$nomBoutique — ${DateFormat('MMMM yyyy', 'fr_FR').format(mois)}'
          '  •  page ${contexte.pageNumber}/${contexte.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (_) => [
        pw.Text(
          'ShopTrack',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#174E46'),
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Bilan mensuel',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
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

        titreSection('VENTES PAR SEMAINE'),
        for (var i = 0; i < tranches.length; i++)
          ligne(libellesSemaines[i], fcfa(tranches[i])),

        titreSection('ÉCARTS DE CAISSE'),
        ligne('Manques', fcfa(ecarts.manques)),
        ligne('Surplus', fcfa(ecarts.surplus)),
        ligne('Solde des écarts', fcfa(ecarts.total)),
        pw.Text(
          ecarts.journeesComptees == 0
              ? 'Aucun tiroir compté ce mois-ci : il n’y a donc aucun écart à '
                    'constater, ce qui n’est pas la même chose qu’une caisse juste.'
              : '${ecarts.journeesComptees} journée(s) dont le tiroir a été '
                    'réellement compté.',
          style: const pw.TextStyle(fontSize: 9),
        ),

        titreSection('DÉTAIL PAR JOUR'),
        if (bilan.clotures.isEmpty)
          pw.Text(
            'Aucune journée clôturée ce mois-ci.',
            style: const pw.TextStyle(fontSize: 10),
          )
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F2F6F4'),
            ),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            headers: const [
              'Jour',
              'Ventes',
              'Bénéfice',
              'Comptée',
              'Écart',
            ],
            data: [
              for (final cloture in bilan.clotures)
                [
                  () {
                    final jour = jourDeCloture(cloture);
                    return jour == null
                        ? '${cloture['closing_date']}'
                        : DateFormat('dd/MM').format(jour);
                  }(),
                  fcfa(entier(cloture['total_sales'])),
                  fcfa(entier(cloture['net_profit'])),
                  montantOuTiret(cloture['physical_cash']),
                  montantOuTiret(cloture['cash_gap']),
                ],
            ],
          ),
        for (final cloture in bilan.clotures)
          if ((cloture['note'] as String?)?.isNotEmpty == true)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                '${cloture['closing_date']} — ${cloture['note']}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),

        pw.SizedBox(height: 16),
        pw.Text(
          'Un tiret dans « Comptée » ou « Écart » signifie que le tiroir n’a '
          'pas été compté ce jour-là, pas qu’il était vide.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        if (bilan.journeesNonCloturees > 0)
          pw.Text(
            '${bilan.journeesNonCloturees} journée(s) avec des ventes n’ont '
            'jamais été clôturées. Leurs ventes sont comprises dans les totaux '
            'du mois, mais absentes du détail par jour.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        pw.Text(
          'Montants synchronisés avec le serveur de test.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        if (bilan.beneficeBrutVentes == null)
          pw.Text(
            'Bénéfice indisponible : une vente n’a pas de coût connu.',
            style: const pw.TextStyle(fontSize: 9),
          ),
      ],
    ),
  );
  await Printing.layoutPdf(
    name:
        'shoptrack-bilan-${mois.year}-${mois.month.toString().padLeft(2, '0')}.pdf',
    onLayout: (_) => document.save(),
  );
}

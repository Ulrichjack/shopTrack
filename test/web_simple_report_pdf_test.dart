import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shoptrack/web/web_bilan_data.dart';
import 'package:shoptrack/web/web_simple_report_pdf.dart';

/// Génération réelle du bilan PDF.
///
/// Une table PDF qui déborde de la page lève à l'**exécution** : ni l'analyse
/// ni la compilation ne l'attrapent, et personne ne le verrait avant qu'une
/// cliente appuie sur « exporter ». D'où un mois complet, chargé.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('fr_FR', null));

  WebBilanData bilanDeTest({
    required int nombreDeJours,
    bool avecComptages = true,
    int? beneficeBrut = 480000,
    int journeesOubliees = 0,
  }) => WebBilanData(
    nombreVentes: nombreDeJours * 12,
    totalVentes: nombreDeJours * 125000,
    nombreRecettes: 0,
    totalRecettes: 0,
    commandesLivrees: 0,
    totalCommandesLivrees: 0,
    coutCommandesConnu: 0,
    commandesSansCout: 0,
    encoreDuCommandes: 0,
    beneficeBrutVentes: beneficeBrut,
    depenses: 42000,
    deplacements: 150000,
    journeesNonCloturees: journeesOubliees,
    clotures: [
      for (var jour = 1; jour <= nombreDeJours; jour++)
        {
          'closing_date':
              '2026-11-${jour.toString().padLeft(2, '0')}',
          'total_sales': 125000 + jour * 1000,
          'net_profit': 32000 + jour * 100,
          // Un jour sur quatre sans comptage : c'est le cas qui imprimait
          // « 0 FCFA » et se lisait comme une caisse vérifiée.
          'physical_cash': avecComptages && jour % 4 != 0
              ? 124500 + jour * 1000
              : null,
          'cash_gap': avecComptages && jour % 4 != 0
              ? (jour.isEven ? 500 : -500)
              : null,
          'note': jour % 7 == 0 ? 'note de la journée $jour' : null,
        },
    ],
  );

  test('un mois complet de 30 clôtures produit un PDF valide', () async {
    final octets = await construireBilanSimpleWebPdf(
      nomBoutique: 'Boutique de test ShopTrack',
      mois: DateTime(2026, 11),
      bilan: bilanDeTest(nombreDeJours: 30, journeesOubliees: 2),
    );
    // En-tête PDF, et un document qui pèse quelque chose : une table vide
    // produirait un fichier minuscule sans lever d'erreur.
    expect(String.fromCharCodes(octets.take(5)), '%PDF-');
    expect(octets.length, greaterThan(20000));

    // Écrit pour pouvoir être ouvert et regardé à l'œil.
    final sortie = Directory.systemTemp.createTempSync('shoptrack-bilan-');
    final fichier = File('${sortie.path}/bilan-30-jours.pdf')
      ..writeAsBytesSync(octets);
    printOnFailure('PDF écrit dans ${fichier.path}');
    expect(fichier.existsSync(), isTrue);
  });

  test('un mois sans aucune clôture ne casse pas le document', () async {
    final octets = await construireBilanSimpleWebPdf(
      nomBoutique: 'Boutique sans clôture',
      mois: DateTime(2026, 11),
      bilan: bilanDeTest(nombreDeJours: 0),
    );
    expect(String.fromCharCodes(octets.take(5)), '%PDF-');
  });

  test('un mois dont aucun tiroir n’a été compté passe aussi', () async {
    final octets = await construireBilanSimpleWebPdf(
      nomBoutique: 'Boutique sans comptage',
      mois: DateTime(2026, 11),
      bilan: bilanDeTest(nombreDeJours: 12, avecComptages: false),
    );
    expect(String.fromCharCodes(octets.take(5)), '%PDF-');
  });

  test('un bénéfice inconnu n’empêche pas l’export', () async {
    // `beneficeBrutVentes` nul veut dire qu'une vente n'a pas de coût connu.
    // Les lignes de marge disparaissent, le document doit rester imprimable.
    final octets = await construireBilanSimpleWebPdf(
      nomBoutique: 'Boutique sans coût',
      mois: DateTime(2026, 11),
      bilan: bilanDeTest(nombreDeJours: 5, beneficeBrut: null),
    );
    expect(String.fromCharCodes(octets.take(5)), '%PDF-');
  });

  test('des montants à sept chiffres ne débordent pas du tableau', () async {
    // Le cas qui fait éclater une table PDF : des colonnes très larges.
    final octets = await construireBilanSimpleWebPdf(
      nomBoutique: 'Boutique à gros volumes',
      mois: DateTime(2026, 11),
      bilan: WebBilanData(
        nombreVentes: 4000,
        totalVentes: 98765432,
        nombreRecettes: 0,
        totalRecettes: 0,
        commandesLivrees: 0,
        totalCommandesLivrees: 0,
        coutCommandesConnu: 0,
        commandesSansCout: 0,
        encoreDuCommandes: 0,
        beneficeBrutVentes: 12345678,
        depenses: 7654321,
        deplacements: 8765432,
        clotures: const [
          {
            'closing_date': '2026-11-15',
            'total_sales': 9876543,
            'net_profit': 1234567,
            'physical_cash': 9870000,
            'cash_gap': -6543,
            'note': null,
          },
        ],
      ),
    );
    expect(String.fromCharCodes(octets.take(5)), '%PDF-');
  });
}

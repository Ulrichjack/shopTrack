import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shoptrack/web/web_bilan_sections.dart';

/// Rendu réel des sections chiffrées, sur le gabarit le plus hostile du
/// projet : petit téléphone **et** texte grossi. Trois bugs de contenu masqué
/// en bas ont déjà été rencontrés ici (voir `CLAUDE.md`), et un débordement
/// fait échouer un test Flutter — c'est donc la seule vérification d'écran
/// qui ne demande ni navigateur ni serveur.
void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  String fcfa(num montant) => '${montant.round()} FCFA';

  Future<void> rendre(WidgetTester tester, Widget section) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: Scaffold(
          // Les sections vivent dans la liste du bilan : même contexte ici,
          // sinon une hauteur non bornée masquerait un débordement vertical.
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [section],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final clotures = [
    {
      'closing_date': '2026-11-03',
      'total_sales': 125000,
      'total_withdrawals': 4000,
      'calculated_cash': 121000,
      'net_profit': 32000,
      'physical_cash': 120500,
      'cash_gap': -500,
      'note': 'manque signalé par la vendeuse',
    },
    {
      'closing_date': '2026-11-12',
      'total_sales': 98000,
      'total_withdrawals': 0,
      'calculated_cash': 98000,
      'net_profit': 21000,
      'physical_cash': null,
      'cash_gap': null,
      'note': null,
    },
    {
      'closing_date': '2026-11-25',
      'total_sales': 1450000,
      'total_withdrawals': 250000,
      'calculated_cash': 1200000,
      'net_profit': 380000,
      'physical_cash': 1203000,
      'cash_gap': 3000,
      'note': null,
    },
  ];

  testWidgets('les barres par semaine tiennent sur un petit écran', (
    tester,
  ) async {
    await rendre(tester, BarresSemaines(clotures: clotures, fcfa: fcfa));
    expect(find.text('Sem. 1 (1-7)'), findsOneWidget);
    expect(find.text('Sem. 4 (22-fin)'), findsOneWidget);
    // Un montant à sept chiffres avec un texte grossi : c'est la ligne qui
    // débordait avant que le montant devienne Flexible.
    expect(find.text('1450000 FCFA'), findsOneWidget);
  });

  testWidgets('un mois sans clôture affiche quatre tranches à zéro', (
    tester,
  ) async {
    await rendre(tester, BarresSemaines(clotures: const [], fcfa: fcfa));
    expect(find.text('0 FCFA'), findsNWidgets(4));
  });

  testWidgets('le bloc des écarts sépare manques, surplus et solde', (
    tester,
  ) async {
    await rendre(tester, BlocEcartsDeCaisse(clotures: clotures, fcfa: fcfa));
    expect(find.text('MANQUES'), findsOneWidget);
    expect(find.text('500 FCFA'), findsOneWidget);
    expect(find.text('3000 FCFA'), findsOneWidget);
    expect(find.text('2500 FCFA'), findsOneWidget, reason: 'solde des écarts');
    // Trois clôtures, deux tiroirs comptés : le troisième n'a pas d'écart.
    expect(
      find.textContaining('2 journée(s) dont le tiroir a été'),
      findsOneWidget,
    );
  });

  testWidgets('aucun tiroir compté ne se lit pas « caisse juste »', (
    tester,
  ) async {
    await rendre(
      tester,
      BlocEcartsDeCaisse(
        clotures: const [
          {'closing_date': '2026-11-03', 'cash_gap': null},
        ],
        fcfa: fcfa,
      ),
    );
    expect(
      find.textContaining('n’est pas la même chose qu’une caisse juste'),
      findsOneWidget,
    );
  });

  testWidgets('le tableau par jour garde un tiret pour un tiroir non compté', (
    tester,
  ) async {
    await rendre(tester, TableauParJour(clotures: clotures, fcfa: fcfa));
    expect(find.text('03/11'), findsOneWidget);
    expect(find.text('12/11'), findsOneWidget);
    // La journée du 12 n'a ni comptage ni écart : deux tirets, pas deux zéros.
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('le tableau par jour défile horizontalement', (tester) async {
    await rendre(tester, TableauParJour(clotures: clotures, fcfa: fcfa));
    // Cinq colonnes de montants ne tiennent pas dans 360 px : le tableau doit
    // pouvoir défiler plutôt que tronquer des chiffres.
    final defilement = find.descendant(
      of: find.byType(TableauParJour),
      matching: find.byType(Scrollable),
    );
    expect(defilement, findsWidgets);
    await tester.drag(defilement.first, const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('Écart'), findsOneWidget);
  });

  testWidgets('la carte de clôture nomme l’écart et garde la note', (
    tester,
  ) async {
    await rendre(tester, CarteCloture(cloture: clotures[0], fcfa: fcfa));
    expect(find.textContaining('mardi 3 novembre 2026'), findsOneWidget);
    expect(find.text('Manque 500 FCFA'), findsOneWidget);
    expect(find.text('manque signalé par la vendeuse'), findsOneWidget);
    expect(find.text('COMPTÉE'), findsOneWidget);
  });

  testWidgets('une clôture sans comptage le dit au lieu d’afficher zéro', (
    tester,
  ) async {
    await rendre(tester, CarteCloture(cloture: clotures[1], fcfa: fcfa));
    expect(find.text('Tiroir non compté'), findsOneWidget);
    expect(find.text('Caisse juste'), findsNothing);
    expect(find.text('—'), findsOneWidget, reason: 'la ligne « comptée »');
  });

  testWidgets('un surplus et un écart nul ne se disent pas pareil', (
    tester,
  ) async {
    await rendre(tester, CarteCloture(cloture: clotures[2], fcfa: fcfa));
    expect(find.text('Surplus 3000 FCFA'), findsOneWidget);

    await rendre(
      tester,
      CarteCloture(
        cloture: const {'closing_date': '2026-11-04', 'cash_gap': 0},
        fcfa: fcfa,
      ),
    );
    expect(find.text('Caisse juste'), findsOneWidget);
  });

  testWidgets('l’avertissement des journées oubliées reste lisible', (
    tester,
  ) async {
    await rendre(tester, const AvertissementJourneesOubliees(nombre: 3));
    expect(find.textContaining('3 journée(s)'), findsOneWidget);
    expect(find.textContaining('l’argent est bien entré'), findsOneWidget);
  });
}

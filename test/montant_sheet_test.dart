// La feuille qui a fait l'écran rouge du 31/08.
//
// Le contrôleur était créé par l'appelant puis libéré juste après l'`await`,
// pendant que la feuille finissait son animation avec un `TextField` branché
// dessus. Ces tests ouvrent la feuille, la ferment, et laissent l'animation
// aller jusqu'au bout : c'est exactement le moment où ça cassait.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/shared/widgets/montant_sheet.dart';

void main() {
  /// Monte un écran avec un bouton qui ouvre la feuille, et garde ce qu'elle
  /// renvoie.
  Future<Future<SaisieMontant?> Function()> poser(
    WidgetTester tester, {
    String? Function(int montant)? valider,
    bool avecModePaiement = false,
    int? valeurInitiale,
  }) async {
    late BuildContext contexte;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            contexte = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    return () async {
      return showMontantSheet(
        context: contexte,
        titre: 'Encaisser',
        valeurInitiale: valeurInitiale,
        avecModePaiement: avecModePaiement,
        valider: valider ?? (_) => null,
      );
    };
  }

  testWidgets('ouvrir puis fermer ne casse rien', (tester) async {
    final ouvrir = await poser(tester);

    final futur = ouvrir();
    await tester.pumpAndSettle();
    expect(find.text('Encaisser'), findsOneWidget);

    // Fermer par la croix, puis laisser l'animation finir. C'est là que le
    // contrôleur libéré trop tôt faisait tomber l'application.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(await futur, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un montant valide revient avec son mode', (tester) async {
    final ouvrir = await poser(tester, avecModePaiement: true);

    final futur = ouvrir();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '40000');
    await tester.tap(find.text('Orange Money'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final saisie = await futur;
    expect(saisie?.montant, 40000);
    expect(saisie?.mode, 'orange_money');
    expect(tester.takeException(), isNull);
  });

  testWidgets('les espèces sont le choix par défaut', (tester) async {
    // Le cas courant dans une boutique. Un défaut sur « Autre » obligerait à
    // choisir vingt fois par jour, et la vingt-et-unième serait oubliée.
    final ouvrir = await poser(tester, avecModePaiement: true);

    final futur = ouvrir();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5000');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect((await futur)?.mode, 'especes');
  });

  testWidgets('un montant refusé garde la feuille ouverte', (tester) async {
    // Le plafond vit ici, pas seulement sur le serveur : une opération refusée
    // bloque la file cinq essais durant et fait apparaître un bandeau que
    // personne ne sait lire.
    final ouvrir = await poser(
      tester,
      valider: (montant) => montant > 85000 ? 'Pas plus de 85 000 F.' : null,
    );

    ouvrir();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '200000');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Pas plus de 85 000 F.'), findsOneWidget);
    expect(
      find.text('Valider'),
      findsOneWidget,
      reason: 'la feuille reste ouverte pour corriger',
    );
  });

  testWidgets('zéro et vide sont refusés', (tester) async {
    final ouvrir = await poser(tester);

    ouvrir();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Entre un montant.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Entre un montant.'), findsOneWidget);
  });

  testWidgets('le prix déjà fixé est pré-rempli', (tester) async {
    // Corriger un prix de 150 000 F en le retapant en entier invite à la faute
    // de frappe : le champ part de la valeur actuelle.
    final ouvrir = await poser(tester, valeurInitiale: 150000);

    ouvrir();
    await tester.pumpAndSettle();

    expect(find.text('150000'), findsOneWidget);
  });
}

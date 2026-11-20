import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shoptrack/web/web_navigation.dart';

void main() {
  List<WebPage> pages({
    bool inventaire = false,
    bool cycles = false,
    bool commandes = false,
    bool patron = true,
  }) => destinationsWeb(
    inventairePeriodique: inventaire,
    cyclesActifs: cycles,
    commandesActives: commandes,
    estPatron: patron,
  ).map((destination) => destination.page).toList();

  test('le mode simple donne un bilan au propriétaire', () {
    expect(pages(), [
      WebPage.accueil,
      WebPage.journal,
      WebPage.caisse,
      WebPage.stock,
      WebPage.bilan,
      WebPage.employes,
    ]);
    expect(pages(patron: false), [
      WebPage.accueil,
      WebPage.journal,
      WebPage.caisse,
      WebPage.stock,
    ]);
  });

  test('l’inventaire remplace le journal et peut accueillir les commandes', () {
    expect(pages(inventaire: true, commandes: true), [
      WebPage.accueil,
      WebPage.stock,
      WebPage.bilan,
      WebPage.inventaire,
      WebPage.commandes,
    ]);
  });

  test('les cycles ne sont visibles que du propriétaire', () {
    expect(pages(cycles: true, patron: true), contains(WebPage.cycles));
    expect(pages(cycles: true, patron: false), isNot(contains(WebPage.cycles)));
  });

  test('les commandes sont un module additionnel', () {
    expect(pages(cycles: true, commandes: true), [
      WebPage.accueil,
      WebPage.journal,
      WebPage.stock,
      WebPage.bilan,
      WebPage.cycles,
      WebPage.commandes,
    ]);
  });

  testWidgets(
    'les cinq destinations visibles restent affichables sur un petit téléphone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final items = destinationsWeb(
        inventairePeriodique: false,
        cyclesActifs: true,
        commandesActives: true,
        estPatron: true,
      ).take(4).toList();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              destinations: [
                for (final item in items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: 'Plus',
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Plus'), findsOneWidget);
    },
  );
}

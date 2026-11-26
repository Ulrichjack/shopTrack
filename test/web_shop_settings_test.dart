import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/web/web_shop_settings.dart';

void main() {
  test('les valeurs par défaut sont celles de l’Android', () {
    const reglages = WebShopSettings();
    expect(reglages.unitMode, 'simple');
    expect(reglages.saleCaptureMode, 'realtime');
    expect(reglages.multiPointEnabled, isFalse);
    expect(reglages.commandesEnabled, isFalse);
    expect(reglages.venteParUnites, isFalse);
    expect(reglages.inventairePeriodique, isFalse);
  });

  group('avec()', () {
    test('changer un réglage ne perd pas multi_point_enabled', () {
      // LE piège de cet écran. L'enregistrement est un upsert : une colonne
      // absente du message reprend sa valeur par défaut côté serveur. Si la
      // copie oubliait `multiPointEnabled`, activer les commandes éteindrait
      // le multi-point d'une boutique qui n'avait rien demandé.
      const depart = WebShopSettings(
        multiPointEnabled: true,
        unitMode: 'hierarchical',
      );
      expect(depart.avec(commandes: true).multiPointEnabled, isTrue);
      expect(depart.avec(inventairePeriodique: true).multiPointEnabled, isTrue);
      expect(depart.avec(venteParUnites: false).multiPointEnabled, isTrue);
    });

    test('ne touche que le réglage demandé', () {
      const depart = WebShopSettings(commandesEnabled: true);
      final apres = depart.avec(venteParUnites: true);
      expect(apres.unitMode, 'hierarchical');
      expect(apres.commandesEnabled, isTrue);
      expect(apres.saleCaptureMode, 'realtime');
    });

    test('traduit les booléens dans le vocabulaire du serveur', () {
      const depart = WebShopSettings();
      expect(depart.avec(venteParUnites: true).unitMode, 'hierarchical');
      expect(depart.avec(venteParUnites: false).unitMode, 'simple');
      expect(
        depart.avec(inventairePeriodique: true).saleCaptureMode,
        'periodic',
      );
      expect(
        depart.avec(inventairePeriodique: false).saleCaptureMode,
        'realtime',
      );
    });
  });

  group('combinaisonImpossible', () {
    test('inventaire périodique et commandes ne cohabitent pas', () {
      // Un acompte en espèces écrit une ligne de caisse ; en périodique il n'y
      // a pas de caisse calculée, et cette ligne n'aurait aucun écran où
      // apparaître. L'argent serait encaissé et invisible.
      expect(
        combinaisonImpossible(
          const WebShopSettings(
            saleCaptureMode: 'periodic',
            commandesEnabled: true,
          ),
        ),
        isTrue,
      );
    });

    test('chacun seul est permis', () {
      expect(
        combinaisonImpossible(
          const WebShopSettings(saleCaptureMode: 'periodic'),
        ),
        isFalse,
      );
      expect(
        combinaisonImpossible(const WebShopSettings(commandesEnabled: true)),
        isFalse,
      );
      expect(combinaisonImpossible(const WebShopSettings()), isFalse);
    });

    test('la vente par unités ne s’exclut avec rien', () {
      expect(
        combinaisonImpossible(
          const WebShopSettings(
            unitMode: 'hierarchical',
            commandesEnabled: true,
          ),
        ),
        isFalse,
      );
    });
  });

  _testsDeRendu();
}

// --- Rendu de l'écran des réglages (WebShopSettingsBody) ---

Future<void> _rendreReglages(
  WidgetTester tester,
  WebShopSettings reglages, {
  ValueChanged<WebShopSettings>? onChanged,
}) async {
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
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            WebShopSettingsBody(
              reglages: reglages,
              onChanged: onChanged ?? (_) {},
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SwitchListTile _interrupteur(WidgetTester tester, String titre) =>
    tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text(titre),
        matching: find.byType(SwitchListTile),
      ),
    );

void _testsDeRendu() {
  testWidgets('une boutique simple neuve ne montre pas la vente par unités', (
    tester,
  ) async {
    await _rendreReglages(tester, const WebShopSettings());
    // Le module est masqué pour les nouvelles boutiques : on ne doit pas
    // pouvoir l'allumer depuis le web.
    expect(find.text('Vente par unités'), findsNothing);
    expect(find.text('Inventaire périodique'), findsOneWidget);
    expect(find.text('Commandes avec acompte'), findsOneWidget);
  });

  testWidgets('la vente par unités apparaît si elle est déjà active', (
    tester,
  ) async {
    await _rendreReglages(
      tester,
      const WebShopSettings(unitMode: 'hierarchical'),
    );
    expect(find.text('Vente par unités'), findsOneWidget);
    expect(_interrupteur(tester, 'Vente par unités').value, isTrue);
  });

  testWidgets('commandes actif grise l’inventaire, pas l’inverse encore', (
    tester,
  ) async {
    await _rendreReglages(
      tester,
      const WebShopSettings(commandesEnabled: true),
    );
    // L'exclusion est visible : l'inventaire ne peut pas s'activer tant que
    // les commandes le sont. Un interrupteur grisé a onChanged == null.
    expect(_interrupteur(tester, 'Inventaire périodique').onChanged, isNull);
    expect(_interrupteur(tester, 'Commandes avec acompte').onChanged, isNotNull);
    expect(find.textContaining('Indisponible'), findsOneWidget);
  });

  testWidgets('inventaire actif grise les commandes', (tester) async {
    await _rendreReglages(
      tester,
      const WebShopSettings(saleCaptureMode: 'periodic'),
    );
    expect(_interrupteur(tester, 'Commandes avec acompte').onChanged, isNull);
    expect(_interrupteur(tester, 'Inventaire périodique').onChanged, isNotNull);
  });

  testWidgets('activer un interrupteur remonte le réglage complet', (
    tester,
  ) async {
    WebShopSettings? demande;
    await _rendreReglages(
      tester,
      const WebShopSettings(multiPointEnabled: true),
      onChanged: (r) => demande = r,
    );
    // Sur 360x640 avec texte grossi, le troisième interrupteur est sous le
    // pli : on fait remonter la liste jusqu'à l'amener bien dans l'écran.
    // Qu'il réponde au tap prouve qu'il n'est pas masqué, seulement plus bas —
    // la liste défile, contrairement à un contenu coincé derrière un bouton.
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commandes avec acompte'));
    await tester.pumpAndSettle();
    expect(demande, isNotNull);
    expect(demande!.commandesEnabled, isTrue);
    // Le piège de l'upsert : multi_point ne doit pas tomber en touchant autre
    // chose.
    expect(demande!.multiPointEnabled, isTrue);
  });
}

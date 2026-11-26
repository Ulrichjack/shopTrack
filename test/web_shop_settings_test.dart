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
}

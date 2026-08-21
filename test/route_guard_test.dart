import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/router.dart';

/// La seule barrière de l'application. Cacher un bouton dans l'interface ne
/// protège rien : ces règles-là sont ce qui tient réellement la porte.
void main() {
  String? route({
    bool connecte = true,
    bool doitChanger = false,
    bool accesPatron = false,
    required String vers,
  }) => routeImposee(
    connecte: connecte,
    doitChangerMotDePasse: doitChanger,
    accesPatron: accesPatron,
    emplacement: vers,
  );

  group('sans être connecté', () {
    test('tout écran renvoie à la connexion', () {
      expect(route(connecte: false, vers: '/home'), '/login');
      expect(route(connecte: false, vers: '/products'), '/login');
      expect(route(connecte: false, vers: '/bilan'), '/login');
    });

    test("l'écran de premier mot de passe aussi", () {
      // Sans session il n'y a pas de compte à protéger, et cet écran
      // appellerait `changerMotDePasse` sans savoir sur qui.
      expect(route(connecte: false, vers: routePremierMotDePasse), '/login');
    });

    test('connexion et inscription restent ouvertes', () {
      expect(route(connecte: false, vers: '/login'), isNull);
      expect(route(connecte: false, vers: '/register'), isNull);
    });
  });

  group('mot de passe provisoire à remplacer', () {
    test('aucun écran ne s\'ouvre tant qu\'il n\'est pas changé', () {
      for (final vers in ['/home', '/products', '/sales/new', '/profile']) {
        expect(
          route(doitChanger: true, vers: vers),
          routePremierMotDePasse,
          reason: '$vers devrait renvoyer vers le changement de mot de passe',
        );
      }
    });

    test("l'écran de changement, lui, s'ouvre", () {
      expect(route(doitChanger: true, vers: routePremierMotDePasse), isNull);
    });

    test('passe avant la barrière Patron, même pour un patron', () {
      // Un patron ne reçoit jamais de mot de passe provisoire aujourd'hui,
      // mais si cela arrivait, le changement doit primer : le laisser entrer
      // dans le bilan avec un mot de passe que quelqu'un d'autre connaît
      // reviendrait à ouvrir le bilan à cette personne.
      expect(
        route(doitChanger: true, accesPatron: true, vers: '/bilan'),
        routePremierMotDePasse,
      );
    });

    test('une fois changé, cet écran ne réapparaît plus', () {
      expect(route(vers: routePremierMotDePasse), '/home');
    });
  });

  group('barrière des écrans Patron', () {
    test('un vendeur est renvoyé au profil', () {
      for (final vers in bossOnlyRoutes) {
        expect(
          route(vers: vers),
          '/profile',
          reason: '$vers ne doit pas s\'ouvrir sans le mode Patron',
        );
      }
    });

    test('le patron y accède', () {
      for (final vers in bossOnlyRoutes) {
        expect(route(accesPatron: true, vers: vers), isNull);
      }
    });

    test('les écrans ordinaires restent ouverts au vendeur', () {
      expect(route(vers: '/home'), isNull);
      expect(route(vers: '/products'), isNull);
      expect(route(vers: '/sales/new'), isNull);
      expect(route(vers: '/profile'), isNull);
    });
  });

  test('connecté, on ne revient pas sur la connexion', () {
    expect(route(vers: '/login'), '/home');
    expect(route(vers: '/register'), '/home');
  });
}

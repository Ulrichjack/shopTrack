import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/web/web_bilan_detail.dart';

Map<String, dynamic> cloture(
  String date, {
  int ventes = 0,
  Object? ecart = 0,
}) => {'closing_date': date, 'total_sales': ventes, 'cash_gap': ecart};

void main() {
  group('ventesParSemaine', () {
    test('range chaque jour dans la tranche de l’Android', () {
      final tranches = ventesParSemaine([
        cloture('2026-11-01', ventes: 1000),
        cloture('2026-11-07', ventes: 500),
        cloture('2026-11-08', ventes: 200),
        cloture('2026-11-14', ventes: 300),
        cloture('2026-11-15', ventes: 40),
        cloture('2026-11-21', ventes: 60),
        cloture('2026-11-22', ventes: 7),
        cloture('2026-11-30', ventes: 3),
      ]);
      expect(tranches, [1500, 500, 100, 10]);
    });

    test('la dernière tranche absorbe la fin du mois, 31 jours compris', () {
      final tranches = ventesParSemaine([
        cloture('2026-12-22', ventes: 1),
        cloture('2026-12-31', ventes: 1),
      ]);
      expect(tranches[3], 2);
    });

    test('mois sans clôture : quatre tranches à zéro, pas une liste vide', () {
      expect(ventesParSemaine(const []), [0, 0, 0, 0]);
    });
  });

  group('jourDeCloture', () {
    test('ne décale pas la date, quel que soit le fuseau du navigateur', () {
      final jour = jourDeCloture(cloture('2026-11-01'));
      expect(jour, isNotNull);
      expect(jour!.year, 2026);
      expect(jour.month, 11);
      // Le piège : `DateTime.parse('2026-11-01').toLocal()` recule au 31/10
      // pour un navigateur à l'ouest de Greenwich, et la clôture du 1er
      // basculerait dans le mois précédent.
      expect(jour.day, 1);
    });

    test('date illisible : nul plutôt qu’une date inventée', () {
      expect(jourDeCloture({'closing_date': 'hier'}), isNull);
      expect(jourDeCloture(const {}), isNull);
    });
  });

  group('ecartsDeCaisse', () {
    test('sépare les manques des surplus', () {
      final ecarts = ecartsDeCaisse([
        cloture('2026-11-03', ecart: -500),
        cloture('2026-11-04', ecart: 200),
        cloture('2026-11-05', ecart: -100),
      ]);
      expect(ecarts.manques, 600);
      expect(ecarts.surplus, 200);
      expect(ecarts.total, -400);
      expect(ecarts.journeesComptees, 3);
    });

    test('un tiroir non compté n’est ni un manque ni un surplus', () {
      final ecarts = ecartsDeCaisse([
        cloture('2026-11-03', ecart: null),
        cloture('2026-11-04', ecart: null),
        cloture('2026-11-05', ecart: 0),
      ]);
      expect(ecarts.manques, 0);
      expect(ecarts.surplus, 0);
      // Trois clôtures, mais une seule journée réellement vérifiée : annoncer
      // « 3 journées comptées » ferait croire à un contrôle qui n'a pas eu lieu.
      expect(ecarts.journeesComptees, 1);
    });
  });

  group('journeesNonCloturees', () {
    final aujourdhui = DateTime(2026, 11, 20);

    test('compte les jours vendus sans clôture', () {
      final nombre = journeesNonCloturees(
        ventes: [
          {'created_at': '2026-11-17T10:00:00Z'},
          {'created_at': '2026-11-18T10:00:00Z'},
          {'created_at': '2026-11-18T16:00:00Z'},
        ],
        clotures: [cloture('2026-11-17')],
        aujourdhui: aujourdhui,
      );
      // Le 17 est clôturé ; le 18 ne l'est pas, et ses deux ventes ne font
      // qu'une journée.
      expect(nombre, 1);
    });

    test('le jour en cours n’est pas une journée oubliée', () {
      final nombre = journeesNonCloturees(
        ventes: [
          {'created_at': '2026-11-20T09:00:00Z'},
        ],
        clotures: const [],
        aujourdhui: aujourdhui,
      );
      expect(nombre, 0);
    });

    test('une vente juste après minuit au Cameroun compte pour ce jour-là', () {
      // 23h30 UTC le 18 = 00h30 le 19 à Douala. Compté en UTC, ce serait le 18.
      final nombre = journeesNonCloturees(
        ventes: [
          {'created_at': '2026-11-18T23:30:00Z'},
        ],
        clotures: [cloture('2026-11-18')],
        aujourdhui: aujourdhui,
      );
      expect(nombre, 1, reason: 'le 19 reste sans clôture');
    });

    test('une date de vente illisible ne crée pas de journée fantôme', () {
      final nombre = journeesNonCloturees(
        ventes: [
          {'created_at': null},
          {'created_at': 'pas une date'},
        ],
        clotures: const [],
        aujourdhui: aujourdhui,
      );
      expect(nombre, 0);
    });
  });
}

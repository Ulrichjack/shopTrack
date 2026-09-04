// Le bilan mensuel doit voir les journées vendues mais jamais clôturées.
//
// La caisse continue a rendu la clôture facultative : le commerçant vend le
// mardi, oublie de clôturer, revend le mercredi — et son argent se reporte
// tout seul, c'est ce que le client demandait. Mais le bilan ne lisait QUE la
// table des clôtures : ces journées disparaissaient du mois, ventes comprises.
//
// Deux jours d'activité invisibles, sans un mot. Le genre de trou qu'on ne
// remarque qu'en cherchant pourquoi le total du mois paraît petit.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/reports/presentation/providers/monthly_report_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'cached_shop_id': 'shop-1'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<MonthlyReportState> bilan() async {
    final container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container.read(monthlyReportProvider(DateTime(2026, 8, 1)).future);
  }

  test('une journée vendue sans clôture entre dans le bilan', () async {
    await db.batch((batch) {
      // Le 10 : clôturé normalement.
      batch.insert(
        db.localDailyClosings,
        LocalDailyClosing(
          id: 'c1',
          shopId: 'shop-1',
          userId: 'u1',
          closingDate: DateTime(2026, 8, 10),
          morningBalance: 0,
          totalSales: 30000,
          totalWithdrawals: 0,
          calculatedCash: 30000,
          grossProfit: 5000,
          netProfit: 5000,
          physicalCash: 30000,
          cashGap: 0,
          isClosed: true,
        ),
      );
      // Le 11 : vendu, jamais clôturé.
      batch.insert(
        db.localSales,
        LocalSale(
          id: 'v1',
          shopId: 'shop-1',
          userId: 'u1',
          totalAmount: 18000,
          totalProfit: 3000,
          createdAt: DateTime(2026, 8, 11, 14),
        ),
      );
    });

    final r = await bilan();

    expect(
      r.totalSales,
      48000,
      reason: 'les 18 000 F du 11 sont entrés en caisse, ils comptent',
    );
    expect(r.dailyClosings.length, 2);
    expect(
      r.journeesNonCloturees,
      1,
      reason: 'l\'écran doit pouvoir le signaler',
    );

    final onze = r.dailyClosings.firstWhere((c) => c.closingDate.day == 11);
    expect(onze.isClosed, isFalse);
    expect(
      onze.physicalCash,
      isNull,
      reason: 'personne n\'a compté le tiroir ce jour-là',
    );
    expect(
      onze.cashGap,
      isNull,
      reason:
          'sans comptage il n\'y a pas d\'écart — en inventer un serait '
          'pire que de ne rien afficher',
    );
  });

  test(
    'un versement bancaire d\'un jour non clôturé ne mange pas le bénéfice',
    () async {
      // Même règle que la caisse du jour : déplacer l'argent n'est pas le
      // dépenser. Le bilan doit appliquer la même distinction, sinon les
      // journées non clôturées afficheraient un résultat négatif là où
      // les journées clôturées en montrent un juste.
      await db.batch((batch) {
        batch.insert(
          db.localSales,
          LocalSale(
            id: 'v1',
            shopId: 'shop-1',
            userId: 'u1',
            totalAmount: 25000,
            totalProfit: 4000,
            createdAt: DateTime(2026, 8, 12, 10),
          ),
        );
        batch.insertAll(db.localCashMovements, [
          LocalCashMovement(
            id: 'm1',
            shopId: 'shop-1',
            userId: 'u1',
            amount: 20000,
            type: 'withdrawal',
            category: 'Versement banque',
            createdAt: DateTime(2026, 8, 12, 18),
          ),
          LocalCashMovement(
            id: 'm2',
            shopId: 'shop-1',
            userId: 'u1',
            amount: 1500,
            type: 'withdrawal',
            category: 'Transport',
            createdAt: DateTime(2026, 8, 12, 12),
          ),
        ]);
      });

      final r = await bilan();

      expect(
        r.totalNetProfit,
        2500,
        reason: '4 000 de marge moins la seule vraie dépense, 1 500',
      );
      expect(
        r.totalWithdrawals,
        21500,
        reason: 'la caisse, elle, perd tout ce qui sort',
      );
    },
  );

  test(
    'une journée d\'une AUTRE boutique n\'entre pas dans ce bilan',
    () async {
      // Le téléchargement fusionne sans jamais vider : la base locale garde les
      // ventes de chaque boutique visitée sur ce téléphone.
      await db.batch((batch) {
        batch.insertAll(db.localSales, [
          LocalSale(
            id: 'v1',
            shopId: 'shop-1',
            userId: 'u1',
            totalAmount: 10000,
            totalProfit: 2000,
            createdAt: DateTime(2026, 8, 13, 10),
          ),
          LocalSale(
            id: 'v2',
            shopId: 'shop-2',
            userId: 'u1',
            totalAmount: 99000,
            totalProfit: 40000,
            createdAt: DateTime(2026, 8, 13, 11),
          ),
        ]);
      });

      final r = await bilan();

      expect(r.totalSales, 10000);
      expect(r.journeesNonCloturees, 1);
    },
  );

  test('la journée EN COURS n\'est pas une journée oubliée', () {
    // Vu à l'écran le 04/09 à 10h : « Comprend 1 journée non clôturée » sur une
    // boutique dont la veille était clôturée sans écart. C'était aujourd'hui —
    // et bien sûr qu'aujourd'hui n'est pas clôturé, la journée n'est pas finie.
    //
    // Dit comme un reproche, l'avertissement devient un décor. Le jour où il
    // signale un vrai oubli, personne ne le lit. Même règle que le retard d'une
    // commande : on compare au JOUR, pas à l'instant.
    bool estOubliee(DateTime jourDeLaCloture, {required bool cloturee}) {
      if (cloturee) return false;
      final maintenant = DateTime.now();
      final jour = DateTime(
        jourDeLaCloture.year,
        jourDeLaCloture.month,
        jourDeLaCloture.day,
      );
      return jour.isBefore(
        DateTime(maintenant.year, maintenant.month, maintenant.day),
      );
    }

    final maintenant = DateTime.now();
    final aujourdhui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );

    expect(
      estOubliee(aujourdhui.add(const Duration(hours: 10)), cloturee: false),
      isFalse,
      reason: 'la journée en cours ne se reproche pas',
    );
    expect(
      estOubliee(aujourdhui.subtract(const Duration(days: 1)), cloturee: false),
      isTrue,
      reason: 'hier sans clôture est un vrai oubli',
    );
    expect(
      estOubliee(aujourdhui.subtract(const Duration(days: 1)), cloturee: true),
      isFalse,
    );
  });
}

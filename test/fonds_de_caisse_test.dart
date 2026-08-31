import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/network/connectivity_provider.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/dashboard/presentation/providers/dashboard_provider.dart';

/// La première saisie initialise la caisse continue. Une correction ne
/// réécrit jamais cette origine : elle ajoute un ajustement daté.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'cached_shop_id': 'shop-1',
      'cached_user_id': 'user-1',
    });
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        localDbProvider.overrideWithValue(db),
        connectivityProvider.overrideWith((ref) => Stream.value(false)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<LocalCashMovement>> fonds() => (db.select(
    db.localCashMovements,
  )..where((row) => row.type.equals('morning_balance'))).get();

  Future<List<LocalCashMovement>> ajustements() => (db.select(
    db.localCashMovements,
  )..where((row) => row.type.isIn(['adjustment_in', 'adjustment_out']))).get();

  test(
    'saisir deux fois le fonds du matin corrige, sans ajouter de ligne',
    () async {
      final actions = container.read(dashboardProvider.notifier);

      await actions.saveMorningBalance(23500);
      await actions.saveMorningBalance(23500);

      final lignes = await fonds();
      expect(lignes, hasLength(1), reason: 'un seul point de départ');
      expect(lignes.single.amount, 23500);
      expect(await ajustements(), isEmpty);
    },
  );

  test(
    'corriger le montant ajoute une trace sans réécrire l\'origine',
    () async {
      final actions = container.read(dashboardProvider.notifier);

      await actions.saveMorningBalance(20000);
      await actions.saveMorningBalance(27000);

      final lignes = await fonds();
      expect(lignes, hasLength(1));
      expect(lignes.single.amount, 20000, reason: 'origine immuable');

      final corrections = await ajustements();
      expect(corrections, hasLength(1));
      expect(corrections.single.type, 'adjustment_in');
      expect(corrections.single.amount, 7000);
      expect(corrections.single.note, isNotEmpty);
    },
  );

  test('un comptage réel ajoute un ajustement daté avec son motif', () async {
    final actions = container.read(dashboardProvider.notifier);

    await actions.saveMorningBalance(50000);
    final difference = await actions.adjustCashBalance(
      physicalCash: 40000,
      reason: 'Retrait oublié après la fermeture',
    );

    expect(difference, -10000);
    final corrections = await ajustements();
    expect(corrections, hasLength(1));
    expect(corrections.single.type, 'adjustment_out');
    expect(corrections.single.amount, 10000);
    expect(corrections.single.note, 'Retrait oublié après la fermeture');
  });
}

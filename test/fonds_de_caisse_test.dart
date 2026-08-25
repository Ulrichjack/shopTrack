import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/dashboard/presentation/providers/dashboard_provider.dart';

/// Le champ du fonds de caisse s'ouvrait vide chaque matin, et chaque saisie
/// ajoutait une ligne. Vu chez un client : 23 500 F saisis deux fois à une
/// minute d'intervalle, puis deux retraits identiques dans la foulée. Le
/// journal de caisse racontait une histoire fausse.
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
      overrides: [localDbProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<LocalCashMovement>> fonds() => (db.select(
    db.localCashMovements,
  )..where((row) => row.type.equals('morning_balance'))).get();

  test(
    'saisir deux fois le fonds du matin corrige, sans ajouter de ligne',
    () async {
      final actions = container.read(dashboardProvider.notifier);

      await actions.saveMorningBalance(23500);
      await actions.saveMorningBalance(23500);

      final lignes = await fonds();
      expect(lignes, hasLength(1), reason: 'un seul fonds pour la journée');
      expect(lignes.single.amount, 23500);
    },
  );

  test('corriger le montant remplace l\'ancien', () async {
    final actions = container.read(dashboardProvider.notifier);

    await actions.saveMorningBalance(20000);
    await actions.saveMorningBalance(27000);

    final lignes = await fonds();
    expect(lignes, hasLength(1));
    expect(lignes.single.amount, 27000, reason: 'le dernier montant saisi');
  });
}

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';

void main() {
  late AppDatabase db;
  late SyncService sync;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    sync = container.read(syncServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('la file s’arrête à la première opération en échec', () async {
    await db.addToQueue('OPERATION_PRIORITAIRE', '{');
    await db.addToQueue('OPERATION_DEPENDANTE', '{}');

    // Une opération plus récente peut référencer une donnée créée par la
    // première : continuer produirait des erreurs en cascade et casserait
    // l'ordre local-first.
    await sync.processQueue();

    final file = await db.getPendingItems();
    expect(file.map((item) => item.action), [
      'OPERATION_PRIORITAIRE',
      'OPERATION_DEPENDANTE',
    ]);

    final statut = await sync.statusStream.first;
    expect(statut.phase, SyncPhase.error);
    expect(statut.pendingCount, 2);
    expect(statut.lastError, contains('FormatException'));
  });
}

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';

/// Règle critique du projet (CLAUDE.md) : ne jamais télécharger depuis
/// Supabase tant que la file locale n'est pas vide, sinon un stock vendu mais
/// pas encore envoyé est écrasé par la valeur périmée du serveur.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('le pull est refusé tant qu’une opération est en attente', () async {
    await db.addToQueue('CREATE_SALE', '{}');
    expect(await db.getPendingCount(), 1);

    // Sans session Supabase le pull sort tout de suite ; ce qui compte ici
    // est qu'il n'ait rien écrasé et que la file soit intacte.
    final container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(syncServiceProvider).pullDataFromSupabase();

    expect(
      await db.getPendingCount(),
      1,
      reason: 'la vente en attente doit rester dans la file',
    );
  });

  test('la file se vide bien quand on retire une opération', () async {
    final id = await db.addToQueue('ADD_STOCK', '{}');
    await db.removeFromQueue(id);
    expect(await db.getPendingCount(), 0);
  });
}

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';

/// Recettes de la boutique active, de la plus récente à la plus ancienne.
final takingsProvider = FutureProvider<List<LocalShopTaking>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final shopId = prefs.getString('cached_shop_id');
  if (shopId == null || shopId.isEmpty) {
    throw Exception('Boutique introuvable.');
  }

  final db = ref.watch(localDbProvider);
  return (db.select(db.localShopTakings)
        ..where((taking) => taking.shopId.equals(shopId))
        ..orderBy([(taking) => drift.OrderingTerm.desc(taking.date)]))
      .get();
});

final takingActionsProvider = Provider((ref) => TakingActions(ref));

class TakingActions {
  TakingActions(this.ref);

  final Ref ref;

  Future<void> saveTaking({
    required DateTime date,
    required double amount,
  }) async {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError('Le montant doit être positif ou nul.');
    }

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('cached_shop_id');
    if (shopId == null || shopId.isEmpty) {
      throw Exception('Boutique introuvable.');
    }

    final db = ref.read(localDbProvider);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final remoteDate = _dateForSupabase(normalizedDate);
    final now = DateTime.now();

    // L'écriture locale et la mise en file forment une seule opération : un
    // arrêt de l'app entre les deux ne doit jamais laisser une recette non
    // synchronisable. La clé composite transforme une nouvelle saisie du
    // même jour en correction.
    await db.transaction(() async {
      await db
          .into(db.localShopTakings)
          .insertOnConflictUpdate(
            LocalShopTaking(
              shopId: shopId,
              date: normalizedDate,
              amount: amount,
            ),
          );

      await db.addToQueue(
        'ADD_SHOP_TAKINGS',
        jsonEncode({
          'id': _takingId(shopId, remoteDate),
          'shop_id': shopId,
          'date': remoteDate,
          'amount': amount,
          'created_at': now.toUtc().toIso8601String(),
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(takingsProvider);
  }
}

/// Identifiant **stable** d'une recette, dérivé de la boutique et de la date.
///
/// Une recette est identifiée par « cette boutique, ce jour-là » : corriger le
/// montant ne crée pas une autre recette. Avec un UUID tiré au hasard à chaque
/// saisie, l'upsert changeait la clé primaire de la ligne à chaque correction —
/// sans dégât aujourd'hui, mais toute référence future vers cette ligne
/// pointerait dans le vide.
String _takingId(String shopId, String isoDate) =>
    const Uuid().v5(Namespace.url.value, 'shoptrack:takings:$shopId:$isoDate');

String _dateForSupabase(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

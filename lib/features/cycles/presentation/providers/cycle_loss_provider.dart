import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../products/presentation/providers/product_provider.dart';

final cycleLossesProvider =
    FutureProvider.family<List<LocalCycleLossesData>, String>((ref, cycleId) async {
      final db = ref.watch(localDbProvider);
      return (db.select(
        db.localCycleLosses,
      )..where((t) => t.cycleId.equals(cycleId))).get();
    });

final cycleLossActionsProvider = Provider((ref) => CycleLossActions(ref));

class CycleLossActions {
  CycleLossActions(this.ref);
  final Ref ref;

  Future<void> addLoss({
    required String cycleId,
    required String productId,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    final db = ref.read(localDbProvider);
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('cached_shop_id');
    if (shopId == null) throw Exception('Boutique introuvable.');

    final product = await (db.select(
      db.localProducts,
    )..where((t) => t.id.equals(productId))).getSingle();
    if (product.quantity < quantity) {
      throw Exception(
        'Stock insuffisant pour déclarer cette perte '
        '(disponible : ${product.quantity}).',
      );
    }

    final id = const Uuid().v4();
    final now = DateTime.now();

    await db
        .into(db.localCycleLosses)
        .insert(
          LocalCycleLossesData(
            id: id,
            cycleId: cycleId,
            quantity: quantity,
            reason: reason,
            note: note,
            createdAt: now,
          ),
        );
    await db.addToQueue(
      'ADD_CYCLE_LOSS',
      jsonEncode({
        'id': id,
        'cycle_id': cycleId,
        'quantity': quantity,
        'reason': reason,
        'note': note,
        'created_at': now.toIso8601String(),
      }),
    );

    // Une perte retire la quantité du stock disponible, comme une vente —
    // même RPC apply_stock_movement, delta négatif, type 'loss' (pas de
    // trace dans stock_movements pour ce type : cycle_losses est déjà
    // l'historique de cette opération, exactement comme sale_items pour une
    // vente).
    await (db.update(
      db.localProducts,
    )..where((t) => t.id.equals(productId))).write(
      LocalProductsCompanion(
        quantity: drift.Value(product.quantity - quantity),
      ),
    );
    await db.addToQueue(
      'ADD_STOCK',
      jsonEncode({
        'movement_id': const Uuid().v4(),
        'product_id': productId,
        'shop_id': shopId,
        'quantity': -quantity,
        'type': 'loss',
      }),
    );

    await ref.read(syncServiceProvider).processQueue();

    ref.invalidate(cycleLossesProvider(cycleId));
    ref.invalidate(productProvider);
  }
}

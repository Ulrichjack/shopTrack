import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';

/// Raisons possibles d'une perte. Les clés doivent rester identiques à la
/// contrainte SQL de `inventory_losses`, sinon Supabase rejette l'envoi.
const inventoryLossReasons = <String, String>{
  'casse': 'Casse',
  'peremption': 'Périmé',
  'invendu': 'Invendu jeté',
  'vol': 'Vol constaté',
  'autre': 'Autre',
};

/// Une perte déclarée, avec le produit auquel elle se rattache.
class InventoryLossEntry {
  const InventoryLossEntry({required this.loss, required this.product});

  final LocalInventoryLoss loss;
  final LocalProduct? product;

  String get productName => product?.name ?? 'Produit supprimé';
  String get reasonLabel => inventoryLossReasons[loss.reason] ?? loss.reason;
}

/// Pertes de la boutique, les plus récentes d'abord.
final inventoryLossesProvider = FutureProvider<List<InventoryLossEntry>>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  final shopId = prefs.getString('cached_shop_id');
  if (shopId == null || shopId.isEmpty) {
    throw Exception('Boutique introuvable.');
  }

  final db = ref.watch(localDbProvider);
  final losses =
      await (db.select(db.localInventoryLosses)
            ..where((row) => row.shopId.equals(shopId))
            ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)]))
          .get();

  final products = await (db.select(
    db.localProducts,
  )..where((row) => row.shopId.equals(shopId))).get();
  final byId = {for (final product in products) product.id: product};

  return losses
      .map((loss) => InventoryLossEntry(loss: loss, product: byId[loss.productId]))
      .toList();
});

final inventoryLossActionsProvider = Provider(
  (ref) => InventoryLossActions(ref),
);

class InventoryLossActions {
  InventoryLossActions(this.ref);

  final Ref ref;

  /// Enregistre une perte. **Ne touche pas au stock** : en inventaire
  /// périodique le stock ne bouge qu'au comptage, et la marchandise cassée a
  /// déjà quitté l'étagère. La déclaration sert uniquement à retirer ces
  /// quantités des ventes présumées au moment du rapport.
  Future<LocalInventoryLoss> declareLoss({
    required String productId,
    required int quantity,
    required String reason,
    DateTime? occurredAt,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('La quantité perdue doit être supérieure à zéro.');
    }
    if (!inventoryLossReasons.containsKey(reason)) {
      throw ArgumentError('Raison de perte inconnue : $reason');
    }

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('cached_shop_id');
    if (shopId == null || shopId.isEmpty) {
      throw Exception('Boutique introuvable.');
    }

    final db = ref.read(localDbProvider);
    final loss = LocalInventoryLoss(
      id: const Uuid().v4(),
      shopId: shopId,
      productId: productId,
      quantity: quantity,
      reason: reason,
      note: (note ?? '').trim().isEmpty ? null : note!.trim(),
      occurredAt: occurredAt ?? DateTime.now(),
    );

    await db.transaction(() async {
      await db.into(db.localInventoryLosses).insertOnConflictUpdate(loss);
      await db.addToQueue(
        'ADD_INVENTORY_LOSS',
        jsonEncode({
          'id': loss.id,
          'shop_id': loss.shopId,
          'product_id': loss.productId,
          'quantity': loss.quantity,
          'reason': loss.reason,
          'note': loss.note,
          'occurred_at': loss.occurredAt.toUtc().toIso8601String(),
        }),
      );
    });

    // Même geste que le comptage et la recette : on pousse tout de suite, et
    // la file garde l'écriture si le réseau manque.
    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(inventoryLossesProvider);
    return loss;
  }
}

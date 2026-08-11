import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';

// Unités d'un produit (ex: œuf(1), plateau(30), carton(360)).
final productUnitsProvider =
    FutureProvider.family<List<LocalProductUnit>, String>((
      ref,
      productId,
    ) async {
      final db = ref.watch(localDbProvider);
      return (db.select(db.localProductUnits)
            ..where((t) => t.productId.equals(productId))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.sortOrder)]))
          .get();
    });

final productUnitActionsProvider = Provider((ref) => ProductUnitActions(ref));

class ProductUnitActions {
  ProductUnitActions(this.ref);
  final Ref ref;

  Future<void> addUnit({
    required String productId,
    required String unitName,
    required int ratioToBase,
    int sortOrder = 0,
  }) async {
    final db = ref.read(localDbProvider);
    final id = const Uuid().v4();

    await db
        .into(db.localProductUnits)
        .insert(
          LocalProductUnit(
            id: id,
            productId: productId,
            unitName: unitName,
            ratioToBase: ratioToBase,
            sortOrder: sortOrder,
          ),
        );

    final payload = {
      'id': id,
      'product_id': productId,
      'unit_name': unitName,
      'ratio_to_base': ratioToBase,
      'sort_order': sortOrder,
    };
    await db.addToQueue('ADD_PRODUCT_UNIT', jsonEncode(payload));
    await ref.read(syncServiceProvider).processQueue();

    ref.invalidate(productUnitsProvider(productId));
  }

  Future<void> deleteUnit({
    required String unitId,
    required String productId,
  }) async {
    final db = ref.read(localDbProvider);

    // Une unité déjà utilisée dans une vente ne peut pas disparaître : les
    // lignes de vente y font référence, et le rapport de cycle en dépend.
    final used = await (db.select(
      db.localSaleItems,
    )..where((t) => t.unitId.equals(unitId))).get();
    if (used.isNotEmpty) {
      throw Exception(
        'Cette unité a déjà servi pour ${used.length} vente(s) : '
        'elle ne peut plus être supprimée.',
      );
    }

    await (db.delete(
      db.localProductUnits,
    )..where((t) => t.id.equals(unitId))).go();
    await db.addToQueue('DELETE_PRODUCT_UNIT', jsonEncode({'id': unitId}));
    await ref.read(syncServiceProvider).processQueue();

    ref.invalidate(productUnitsProvider(productId));
  }
}

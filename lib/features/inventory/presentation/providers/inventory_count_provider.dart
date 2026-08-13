import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../products/presentation/providers/product_provider.dart';
import 'inventory_report_provider.dart';

class InventoryCountLine {
  const InventoryCountLine({
    required this.product,
    required this.isCounted,
    this.count,
  });

  final LocalProduct product;
  final bool isCounted;
  final LocalInventoryCount? count;

  /// Disponible uniquement après validation : la quantité théorique ne doit
  /// jamais apparaître pendant la saisie à l'aveugle.
  int? get difference =>
      count == null ? null : count!.countedQuantity - product.quantity;
}

class InventoryCountOverview {
  const InventoryCountOverview({
    required this.lines,
    required this.countedProducts,
    required this.isRoundComplete,
  });

  final List<InventoryCountLine> lines;
  final int countedProducts;
  final bool isRoundComplete;

  int get totalProducts => lines.length;
}

final inventoryCountProvider = FutureProvider<InventoryCountOverview>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  final shopId = prefs.getString('cached_shop_id');
  if (shopId == null || shopId.isEmpty) {
    throw Exception('Boutique introuvable.');
  }

  return loadInventoryCountOverview(ref.watch(localDbProvider), shopId);
});

final inventoryCountActionsProvider = Provider(
  (ref) => InventoryCountActions(ref),
);

class InventoryCountActions {
  InventoryCountActions(this.ref);

  final Ref ref;

  Future<LocalInventoryCount> saveCount({
    required String productId,
    required int countedQuantity,
  }) async {
    if (countedQuantity < 0) {
      throw ArgumentError('La quantité comptée ne peut pas être négative.');
    }

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('cached_shop_id');
    if (shopId == null || shopId.isEmpty) {
      throw Exception('Boutique introuvable.');
    }

    final db = ref.read(localDbProvider);
    late LocalInventoryCount savedCount;

    // Chaque produit est autonome : son repère local et son opération de
    // synchronisation sont atomiques, sans attendre que le reste soit compté.
    await db.transaction(() async {
      final product =
          await (db.select(db.localProducts)..where(
                (row) => row.id.equals(productId) & row.shopId.equals(shopId),
              ))
              .getSingleOrNull();
      if (product == null) {
        throw Exception('Produit introuvable dans cette boutique.');
      }

      final previous =
          await (db.select(db.localInventoryCounts)
                ..where(
                  (row) =>
                      row.shopId.equals(shopId) &
                      row.productId.equals(productId),
                )
                ..orderBy([(row) => drift.OrderingTerm.desc(row.countedAt)])
                ..limit(1))
              .getSingleOrNull();

      final clock = DateTime.now();
      var now = DateTime(
        clock.year,
        clock.month,
        clock.day,
        clock.hour,
        clock.minute,
        clock.second,
      );
      if (previous != null && !now.isAfter(previous.countedAt)) {
        now = previous.countedAt.add(const Duration(seconds: 1));
      }
      savedCount = LocalInventoryCount(
        id: const Uuid().v4(),
        shopId: shopId,
        productId: productId,
        countedAt: now,
        countedQuantity: countedQuantity,
        previousCountedAt: previous?.countedAt,
        previousQuantity: previous?.countedQuantity,
      );

      await db.into(db.localInventoryCounts).insert(savedCount);
      await db.addToQueue(
        'ADD_INVENTORY_COUNT',
        jsonEncode({
          'id': savedCount.id,
          'shop_id': shopId,
          'product_id': productId,
          'counted_at': now.toUtc().toIso8601String(),
          'counted_quantity': countedQuantity,
          'previous_counted_at': previous?.countedAt.toUtc().toIso8601String(),
          'previous_quantity': previous?.countedQuantity,
          'created_at': now.toUtc().toIso8601String(),
        }),
      );

      // Compter, c'est constater la réalité : le stock affiché doit s'aligner
      // sur ce qui a été compté. Sans ça, l'écran Stock continue d'annoncer
      // « Rupture : 0 » alors que le commerçant vient de déclarer 8 sacs.
      //
      // Le type 'inventory_adjustment' n'est pas un approvisionnement : le
      // rapport ne compte que les 'recharge', donc un ajustement n'est jamais
      // pris pour un achat.
      final delta = countedQuantity - product.quantity;
      if (delta != 0) {
        await (db.update(
          db.localProducts,
        )..where((row) => row.id.equals(productId))).write(
          LocalProductsCompanion(quantity: drift.Value(countedQuantity)),
        );
        await db.addToQueue(
          'ADD_STOCK',
          jsonEncode({
            'movement_id': const Uuid().v4(),
            'product_id': productId,
            'shop_id': shopId,
            'quantity': delta,
            'type': 'inventory_adjustment',
          }),
        );
      }
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(inventoryCountProvider);
    ref.invalidate(productProvider);
    ref.invalidate(inventoryReportProvider);
    return savedCount;
  }
}

/// Reconstruit le tour courant sans table de session supplémentaire.
///
/// Chaque produit avance d'un repère par tour. Si les compteurs sont égaux,
/// le dernier tour est complet. Dès qu'un produit reçoit un repère de plus,
/// un nouveau tour commence et la progression repart à 1/N, y compris après
/// fermeture de l'application.
Future<InventoryCountOverview> loadInventoryCountOverview(
  AppDatabase db,
  String shopId,
) async {
  final products =
      await (db.select(db.localProducts)
            ..where((row) => row.shopId.equals(shopId))
            ..orderBy([(row) => drift.OrderingTerm.asc(row.name)]))
          .get();

  if (products.isEmpty) {
    return const InventoryCountOverview(
      lines: [],
      countedProducts: 0,
      isRoundComplete: false,
    );
  }

  final counts =
      await (db.select(db.localInventoryCounts)
            ..where((row) => row.shopId.equals(shopId))
            ..orderBy([(row) => drift.OrderingTerm.desc(row.countedAt)]))
          .get();

  final countsByProduct = <String, List<LocalInventoryCount>>{};
  for (final count in counts) {
    countsByProduct.putIfAbsent(count.productId, () => []).add(count);
  }

  final countNumbers = products
      .map((product) => countsByProduct[product.id]?.length ?? 0)
      .toList();
  final minimum = countNumbers.reduce(math.min);
  final maximum = countNumbers.reduce(math.max);
  final isComplete = maximum > 0 && minimum == maximum;

  var countedProducts = 0;
  final lines = <InventoryCountLine>[];
  for (var index = 0; index < products.length; index++) {
    final product = products[index];
    final number = countNumbers[index];
    final isCounted = isComplete ? number == maximum : number > minimum;
    if (isCounted) countedProducts++;

    lines.add(
      InventoryCountLine(
        product: product,
        isCounted: isCounted,
        count: isCounted ? countsByProduct[product.id]?.firstOrNull : null,
      ),
    );
  }

  return InventoryCountOverview(
    lines: lines,
    countedProducts: countedProducts,
    isRoundComplete: isComplete,
  );
}

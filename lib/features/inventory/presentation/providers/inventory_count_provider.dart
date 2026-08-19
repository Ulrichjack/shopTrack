import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/current_shop_provider.dart';
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
    this.roundNumber = 1,
    this.periodStartedAt,
  });

  final List<InventoryCountLine> lines;
  final int countedProducts;

  /// Numéro du tour en cours. Le 1er pose le point de départ, les suivants
  /// ferment une période — c'est le même geste, l'app en déduit le rôle plutôt
  /// que de demander au commerçant de le déclarer.
  final int roundNumber;

  /// Début de la période que ce tour va fermer. Null au tout premier comptage.
  final DateTime? periodStartedAt;

  bool get isFirstRound => roundNumber <= 1;
  final bool isRoundComplete;

  int get totalProducts => lines.length;
}

final inventoryCountProvider = FutureProvider<InventoryCountOverview>((
  ref,
) async {
  final shopId = await watchShopId(ref);

  return loadInventoryCountOverview(ref.watch(localDbProvider), shopId);
});

final inventoryCountActionsProvider = Provider(
  (ref) => InventoryCountActions(ref),
);

class InventoryCountActions {
  InventoryCountActions(this.ref);

  final Ref ref;

  /// [dateDuComptage] : le jour où le stock a RÉELLEMENT été compté.
  ///
  /// Un commerçant compte sa boutique le samedi soir sur un bout de papier et
  /// saisit le lundi. Sans ce paramètre, le comptage portait la date de la
  /// saisie : la période était décalée de deux jours, et les recettes de ces
  /// deux jours basculaient du mauvais côté de la frontière. Les écrans des
  /// pertes et des recettes laissaient déjà choisir leur date — le comptage
  /// était le seul à l'imposer.
  ///
  /// Nul = aujourd'hui, comportement d'avant.
  Future<LocalInventoryCount> saveCount({
    required String productId,
    required int countedQuantity,
    DateTime? dateDuComptage,
  }) async {
    if (countedQuantity < 0) {
      throw ArgumentError('La quantité comptée ne peut pas être négative.');
    }

    final shopId = await requireShopId(ref);

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
      // Une date choisie garde l'heure courante : deux comptages du même jour
      // doivent rester ordonnables entre eux, et `previousCountedAt` s'appuie
      // sur cet ordre.
      final base = dateDuComptage == null
          ? clock
          : DateTime(
              dateDuComptage.year,
              dateDuComptage.month,
              dateDuComptage.day,
              clock.hour,
              clock.minute,
              clock.second,
            );
      var now = DateTime(
        base.year,
        base.month,
        base.day,
        base.hour,
        base.minute,
        base.second,
      );
      if (previous != null && !now.isAfter(previous.countedAt)) {
        // Une date CHOISIE n'est jamais déplacée en douce.
        //
        // Ce décalage d'une seconde existe pour ordonner deux comptages
        // tombant dans la même seconde d'horloge. Appliqué à une date saisie
        // à la main, il la remplaçait sans rien dire : un comptage daté du
        // 12 août ressortait au 18 août, une seconde après le précédent, et
        // le commerçant voyait trois périodes identiques sans comprendre.
        //
        // Insérer un comptage AVANT un autre demanderait de recalculer la
        // chaîne `previousCountedAt` / `previousQuantity` de toutes les
        // lignes suivantes. Tant que ce n'est pas fait, on refuse clairement
        // plutôt que d'enregistrer une date fausse.
        if (dateDuComptage != null) {
          final d = previous.countedAt;
          final jour =
              '${d.day.toString().padLeft(2, '0')}/'
              '${d.month.toString().padLeft(2, '0')}/${d.year}';
          throw Exception(
            'Ce produit a déjà été compté le $jour. '
            'Un nouveau comptage doit être postérieur à celui-là.',
          );
        }
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
  DateTime? periodStartedAt;
  for (var index = 0; index < products.length; index++) {
    final product = products[index];
    final number = countNumbers[index];
    final isCounted = isComplete ? number == maximum : number > minimum;
    if (isCounted) countedProducts++;

    final last = countsByProduct[product.id]?.firstOrNull;
    // Le repère du tour précédent : pour un produit déjà compté ce tour-ci
    // c'est le comptage d'avant, pour les autres c'est leur dernier comptage.
    // Dans les deux cas on remonte au même tour, donc l'affichage ne change
    // pas au fil de la saisie.
    final previous = isCounted ? last?.previousCountedAt : last?.countedAt;
    if (previous != null &&
        (periodStartedAt == null || previous.isAfter(periodStartedAt))) {
      periodStartedAt = previous;
    }

    lines.add(
      InventoryCountLine(
        product: product,
        isCounted: isCounted,
        count: isCounted ? last : null,
      ),
    );
  }

  return InventoryCountOverview(
    lines: lines,
    countedProducts: countedProducts,
    isRoundComplete: isComplete,
    roundNumber: isComplete ? maximum : minimum + 1,
    periodStartedAt: periodStartedAt,
  );
}

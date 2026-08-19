import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../../core/providers/current_shop_provider.dart';

final cyclesProvider =
    AsyncNotifierProvider<CyclesNotifier, List<LocalSupplyCycle>>(() {
      return CyclesNotifier();
    });

// Le cycle actif d'un produit = le plus récent avec status 'open'. Une vente
// ou une perte doit forcément s'y rattacher (sinon pas de coût réel connu).
//
// Dérivé de cyclesProvider et non d'une requête directe : ainsi créer ou
// fermer un cycle rafraîchit ce provider tout seul. Une lecture indépendante
// resterait sur son ancien résultat et afficherait « aucun cycle ouvert »
// juste après en avoir créé un.
final openCycleForProductProvider =
    FutureProvider.family<LocalSupplyCycle?, String>((ref, productId) async {
      final cycles = await ref.watch(cyclesProvider.future);
      final open =
          cycles
              .where((c) => c.productId == productId && c.status == 'open')
              .toList()
            ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
      return open.isEmpty ? null : open.first;
    });

class CyclesNotifier extends AsyncNotifier<List<LocalSupplyCycle>> {
  @override
  Future<List<LocalSupplyCycle>> build() async {
    final db = ref.read(localDbProvider);
    return db.select(db.localSupplyCycles).get();
  }

  Future<void> createCycle({
    required String productId,
    required int quantityReceived,
    required double purchaseCost,
    double? referenceMarginPerUnit,
  }) async {
    final db = ref.read(localDbProvider);
    final shopId = await requireShopId(ref);

    // Un seul cycle ouvert à la fois par produit.
    //
    // Rien ne l'empêchait, et deux cycles ouverts rendent les DEUX rapports
    // faux. `openCycleForProductProvider` retient le plus récent : toutes les
    // ventes suivantes s'y rattachent en silence. Le premier cycle garde alors
    // pour l'éternité un stock restant que le commerçant a pourtant vendu,
    // pendant que le second peut descendre en stock négatif — l'écran de vente
    // borne la quantité au stock du PRODUIT, pas à ce que ce cycle a reçu.
    //
    // Vu le 18/08/2026 : un cycle de 3 600 œufs encore ouvert, un second de
    // 360 créé par-dessus, et 500 œufs devenus invendables sur le papier.
    // `get()` et non `getSingleOrNull()` : celui-ci lèverait une erreur brute
    // sur les bases où le doublon existe déjà, au lieu du message ci-dessous.
    final dejaOuverts = await (db.select(db.localSupplyCycles)..where(
          (t) =>
              t.productId.equals(productId) & t.status.equals('open'),
        ))
        .get();
    if (dejaOuverts.isNotEmpty) {
      throw Exception(
        'Un arrivage est déjà en cours pour ce produit. '
        'Termine-le avant d\'en enregistrer un nouveau.',
      );
    }

    final id = const Uuid().v4();
    final openedAt = DateTime.now();

    await db
        .into(db.localSupplyCycles)
        .insert(
          LocalSupplyCyclesCompanion.insert(
            id: id,
            shopId: shopId,
            productId: productId,
            openedAt: openedAt,
            quantityReceived: quantityReceived,
            purchaseCost: purchaseCost,
            referenceMarginPerUnit: drift.Value(referenceMarginPerUnit),
          ),
        );

    final payload = {
      'id': id,
      'shop_id': shopId,
      'product_id': productId,
      'opened_at': openedAt.toIso8601String(),
      'quantity_received': quantityReceived,
      'purchase_cost': purchaseCost,
      'reference_margin_per_unit': referenceMarginPerUnit,
      'status': 'open',
    };
    await db.addToQueue('ADD_SUPPLY_CYCLE', jsonEncode(payload));

    // Un cycle rend sa quantité reçue disponible à la vente : on l'ajoute au
    // stock du produit exactement comme une recharge classique (même table
    // stock_movements, même RPC apply_stock_movement), sinon la quantité
    // reçue n'apparaît jamais dans products.quantity et aucune vente n'est
    // possible depuis ce cycle.
    final product = await (db.select(
      db.localProducts,
    )..where((t) => t.id.equals(productId))).getSingle();
    await (db.update(
      db.localProducts,
    )..where((t) => t.id.equals(productId))).write(
      LocalProductsCompanion(
        quantity: drift.Value(product.quantity + quantityReceived),
      ),
    );
    final movementId = const Uuid().v4();
    await db
        .into(db.localStockMovements)
        .insert(
          LocalStockMovement(
            id: movementId,
            shopId: shopId,
            productId: productId,
            quantity: quantityReceived,
            type: 'recharge',
            createdAt: openedAt,
          ),
        );
    await db.addToQueue(
      'ADD_STOCK',
      jsonEncode({
        'movement_id': movementId,
        'product_id': productId,
        'shop_id': shopId,
        'quantity': quantityReceived,
        'type': 'recharge',
      }),
    );

    await ref.read(syncServiceProvider).processQueue();

    ref.invalidate(productProvider);
    ref.invalidateSelf();
    await future;
  }

  /// Archive un cycle : son résultat est figé, il ne reçoit plus ni vente ni
  /// perte. Ne touche pas au stock — ce qui reste invendu reste vendable.
  Future<void> closeCycle(String cycleId) =>
      _setCycleStatus(cycleId, closed: true);

  /// Rouvre un cycle fermé par erreur. Sans ça, la seule issue serait de
  /// créer un second cycle pour un même arrivage, ce qui fausse l'historique.
  Future<void> reopenCycle(String cycleId) =>
      _setCycleStatus(cycleId, closed: false);

  Future<void> _setCycleStatus(String cycleId, {required bool closed}) async {
    final db = ref.read(localDbProvider);
    final closedAt = closed ? DateTime.now() : null;
    final status = closed ? 'closed' : 'open';

    await (db.update(
      db.localSupplyCycles,
    )..where((t) => t.id.equals(cycleId))).write(
      LocalSupplyCyclesCompanion(
        status: drift.Value(status),
        closedAt: drift.Value(closedAt),
      ),
    );

    await db.addToQueue(
      'CLOSE_SUPPLY_CYCLE',
      jsonEncode({
        'id': cycleId,
        'status': status,
        'closed_at': closedAt?.toIso8601String(),
      }),
    );
    await ref.read(syncServiceProvider).processQueue();

    ref.invalidateSelf();
    await future;
  }
}

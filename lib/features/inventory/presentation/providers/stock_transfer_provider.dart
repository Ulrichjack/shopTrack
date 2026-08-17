import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../products/presentation/providers/product_provider.dart';
import 'inventory_report_provider.dart';

/// Un transfert vu depuis la boutique active.
class TransferEntry {
  const TransferEntry({
    required this.transfer,
    required this.productName,
    required this.estEnvoi,
    required this.autreBoutique,
  });

  final LocalStockTransfer transfer;
  final String productName;

  /// Envoyé par cette boutique, ou reçu par elle.
  final bool estEnvoi;

  /// Nom de l'autre boutique, quand on le connaît.
  final String autreBoutique;

  bool get estConfirme => transfer.receivedQuantity != null;

  /// Ce qui s'est perdu en route, une fois la réception confirmée.
  int get manquant => estConfirme
      ? (transfer.quantity - transfer.receivedQuantity!).clamp(0, 1 << 31)
      : 0;
}

final stockTransfersProvider = FutureProvider<List<TransferEntry>>((ref) async {
  final shopId = await watchShopId(ref);
  final db = ref.watch(localDbProvider);

  final lignes =
      await (db.select(db.localStockTransfers)
            ..where(
              (row) =>
                  row.fromShopId.equals(shopId) |
                  row.toShopId.equals(shopId),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.transferredAt)]))
          .get();

  final produits = await db.select(db.localProducts).get();
  final parId = {for (final produit in produits) produit.id: produit};

  return lignes
      .map(
        (ligne) => TransferEntry(
          transfer: ligne,
          productName: parId[ligne.productId]?.name ?? 'Produit inconnu',
          estEnvoi: ligne.fromShopId == shopId,
          // Le nom de l'autre boutique n'est pas dans la base locale : seules
          // les données de la boutique active y descendent. On l'affichera
          // depuis la liste des boutiques du compte, côté écran.
          autreBoutique: ligne.fromShopId == shopId
              ? ligne.toShopId
              : ligne.fromShopId,
        ),
      )
      .toList();
});

final stockTransferActionsProvider = Provider(
  (ref) => StockTransferActions(ref),
);

class StockTransferActions {
  StockTransferActions(this.ref);

  final Ref ref;

  /// Envoie de la marchandise vers une autre boutique.
  ///
  /// Le stock local baisse tout de suite : la marchandise a quitté l'étagère,
  /// attendre la confirmation de l'autre côté ferait mentir le stock affiché
  /// pendant tout le trajet.
  Future<void> envoyer({
    required String productId,
    required String toShopId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('La quantité transférée doit être supérieure à zéro.');
    }

    final shopId = await requireShopId(ref);
    if (toShopId == shopId) {
      throw ArgumentError('Choisis une autre boutique que celle-ci.');
    }

    final db = ref.read(localDbProvider);
    final produit =
        await (db.select(db.localProducts)
              ..where((row) => row.id.equals(productId)))
            .getSingleOrNull();
    if (produit == null) {
      throw Exception('Produit introuvable.');
    }
    if (quantity > produit.quantity) {
      throw ArgumentError(
        'Tu ne peux pas envoyer plus de ${produit.quantity} ${produit.name}.',
      );
    }

    final id = const Uuid().v4();
    final quand = DateTime.now();

    await db.transaction(() async {
      await db
          .into(db.localStockTransfers)
          .insert(
            LocalStockTransfer(
              id: id,
              fromShopId: shopId,
              toShopId: toShopId,
              productId: productId,
              quantity: quantity,
              transferredAt: quand,
              note: (note ?? '').trim().isEmpty ? null : note!.trim(),
            ),
          );

      await db.addToQueue(
        'ADD_STOCK_TRANSFER',
        jsonEncode({
          'id': id,
          'from_shop_id': shopId,
          'to_shop_id': toShopId,
          'product_id': productId,
          'quantity': quantity,
          'transferred_at': quand.toUtc().toIso8601String(),
          'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
        }),
      );

      // Le stock part d'ici. Type `transfer_out` et non `recharge` : le
      // rapport ne compte que les `recharge` comme approvisionnement, un
      // transfert ne doit jamais être pris pour un achat.
      await (db.update(
        db.localProducts,
      )..where((row) => row.id.equals(productId))).write(
        LocalProductsCompanion(
          quantity: Value(produit.quantity - quantity),
        ),
      );
      await db.addToQueue(
        'ADD_STOCK',
        jsonEncode({
          'movement_id': const Uuid().v4(),
          'product_id': productId,
          'shop_id': shopId,
          'quantity': -quantity,
          'type': 'transfer_out',
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    _rafraichir();
  }

  /// Confirme ce qui est réellement arrivé.
  ///
  /// L'écart avec la quantité envoyée devient une perte de transport chez
  /// l'expéditeur — la marchandise était la sienne. Sans cette imputation, le
  /// manquant deviendrait un écart inexpliqué chez lui, donc un vol présumé.
  Future<void> confirmerReception({
    required String transferId,
    required int receivedQuantity,
  }) async {
    if (receivedQuantity < 0) {
      throw ArgumentError('La quantité reçue ne peut pas être négative.');
    }

    final shopId = await requireShopId(ref);
    final db = ref.read(localDbProvider);
    final transfert =
        await (db.select(db.localStockTransfers)
              ..where((row) => row.id.equals(transferId)))
            .getSingleOrNull();
    if (transfert == null) throw Exception('Transfert introuvable.');
    if (transfert.toShopId != shopId) {
      throw Exception('Seule la boutique qui reçoit peut confirmer.');
    }
    if (receivedQuantity > transfert.quantity) {
      throw ArgumentError(
        'Tu ne peux pas recevoir plus que les ${transfert.quantity} envoyés.',
      );
    }

    final quand = DateTime.now();
    await db.transaction(() async {
      await (db.update(
        db.localStockTransfers,
      )..where((row) => row.id.equals(transferId))).write(
        LocalStockTransfersCompanion(
          receivedQuantity: Value(receivedQuantity),
          receivedAt: Value(quand),
        ),
      );

      await db.addToQueue(
        'CONFIRM_STOCK_TRANSFER',
        jsonEncode({
          'id': transferId,
          'received_quantity': receivedQuantity,
          'received_at': quand.toUtc().toIso8601String(),
        }),
      );

      // Le produit de la boutique qui reçoit — pas celui de l'expéditeur.
      //
      // Chaque boutique a ses propres lignes de produits. Créditer celle de
      // l'expéditeur lui rendait le stock qu'il venait d'envoyer, et le
      // serveur refusait le mouvement (`apply_stock_movement` exige que le
      // produit appartienne à la boutique) — ce qui bloquait toute la file.
      final envoye =
          await (db.select(db.localProducts)
                ..where((row) => row.id.equals(transfert.productId)))
              .getSingleOrNull();
      if (envoye == null || receivedQuantity <= 0) return;

      var destination =
          await (db.select(db.localProducts)..where(
                (row) =>
                    row.shopId.equals(shopId) & row.name.equals(envoye.name),
              ))
              .getSingleOrNull();

      if (destination == null) {
        // Première réception de cet article ici : on le crée en reprenant sa
        // fiche. C'est ce qu'attend le commerçant — envoyer du riz vers une
        // boutique qui n'en vendait pas, c'est l'y introduire.
        final nouvelId = const Uuid().v4();
        destination = LocalProduct(
          id: nouvelId,
          shopId: shopId,
          name: envoye.name,
          buyPrice: envoye.buyPrice,
          sellPrice: envoye.sellPrice,
          quantity: 0,
          minQuantity: envoye.minQuantity,
          unit: envoye.unit,
        );
        await db.into(db.localProducts).insert(destination);
        await db.addToQueue(
          'ADD_PRODUCT',
          jsonEncode({
            'id': nouvelId,
            'shop_id': shopId,
            'name': envoye.name,
            'buy_price': envoye.buyPrice,
            'sell_price': envoye.sellPrice,
            'quantity': 0,
            'min_quantity': envoye.minQuantity,
            'barcode': null,
            'photo_url': null,
            if (envoye.unit != null) 'unit': envoye.unit,
          }),
        );
      }

      await (db.update(
        db.localProducts,
      )..where((row) => row.id.equals(destination!.id))).write(
        LocalProductsCompanion(
          quantity: Value(destination.quantity + receivedQuantity),
        ),
      );
      await db.addToQueue(
        'ADD_STOCK',
        jsonEncode({
          'movement_id': const Uuid().v4(),
          'product_id': destination.id,
          'shop_id': shopId,
          'quantity': receivedQuantity,
          'type': 'transfer_in',
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    _rafraichir();
  }

  void _rafraichir() {
    ref.invalidate(stockTransfersProvider);
    ref.invalidate(productProvider);
    ref.invalidate(inventoryReportProvider);
  }
}

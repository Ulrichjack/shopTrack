import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/providers/user_shops_provider.dart';
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

  /// Identifiant de l'autre boutique. Sert de repli quand son nom n'a pas été
  /// recopié sur le transfert (envois d'avant cette colonne).
  final String autreBoutique;

  /// Le nom de l'autre boutique, figé au moment de l'envoi.
  ///
  /// Un vendeur n'est membre que de sa propre boutique : les RLS lui
  /// interdisent de lire la fiche de celle d'en face, et il voyait « Autre
  /// boutique » sur toute sa marchandise reçue. Nul pour les transferts
  /// antérieurs à cette colonne.
  String? get nomAutreBoutique =>
      estEnvoi ? transfer.toShopName : transfer.fromShopName;

  bool get estConfirme => transfer.receivedQuantity != null;

  bool get estAnnule => transfer.cancelledAt != null;

  /// Annulable : il faut l'avoir envoyé, et que personne n'ait encore rien
  /// confirmé de l'autre côté.
  bool get estAnnulable => estEnvoi && !estConfirme && !estAnnule;

  /// Ce qui s'est perdu en route, une fois la réception confirmée.
  int get manquant => estConfirme
      ? (transfer.quantity - transfer.receivedQuantity!).clamp(0, 1 << 31)
      : 0;

  /// Valeur au prix d'achat retenu au moment de l'envoi — ce que cette
  /// marchandise a coûté, pas ce qu'elle coûterait aujourd'hui si le produit
  /// a changé de prix depuis.
  double get valeurAchat => (transfer.buyPrice ?? 0) * transfer.quantity;
}

final stockTransfersProvider = FutureProvider<List<TransferEntry>>((ref) async {
  final shopId = await watchShopId(ref);
  final db = ref.watch(localDbProvider);

  final lignes =
      await (db.select(db.localStockTransfers)
            ..where(
              (row) =>
                  row.fromShopId.equals(shopId) | row.toShopId.equals(shopId),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.transferredAt)]))
          .get();

  final produits = await db.select(db.localProducts).get();
  final parId = {for (final produit in produits) produit.id: produit};

  return lignes
      .map(
        (ligne) => TransferEntry(
          transfer: ligne,
          // Le nom recopié sur le transfert d'abord : c'est le seul que le
          // destinataire possède. La fiche locale ne sert plus qu'aux
          // transferts enregistrés avant que cette colonne existe.
          productName:
              ligne.productName ??
              parId[ligne.productId]?.name ??
              'Produit inconnu',
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
      throw ArgumentError(
        'La quantité transférée doit être supérieure à zéro.',
      );
    }

    final shopId = await requireShopId(ref);
    if (toShopId == shopId) {
      throw ArgumentError('Choisis une autre boutique que celle-ci.');
    }

    final db = ref.read(localDbProvider);
    final produit = await (db.select(
      db.localProducts,
    )..where((row) => row.id.equals(productId))).getSingleOrNull();
    if (produit == null) {
      throw Exception('Produit introuvable.');
    }
    if (quantity > produit.quantity) {
      throw ArgumentError(
        'Tu ne peux pas envoyer plus de ${produit.quantity} ${produit.name}.',
      );
    }

    // Les noms des deux boutiques, résolus ICI et recopiés sur le transfert.
    //
    // Celui qui envoie est membre des deux : il peut les lire. Le
    // destinataire, lui, ne le pourra jamais si c'est un vendeur — les RLS
    // lui interdisent la boutique d'en face, et il voyait « Autre boutique »
    // sur toute sa marchandise reçue.
    final boutiques = await ref.read(userShopsProvider.future);
    final nomDe = {for (final b in boutiques) b.id: b.name};

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
              // L'identité voyage AVEC la marchandise. `productId` désigne la
              // fiche de cette boutique-ci ; la boutique qui reçoit ne l'aura
              // jamais en base. Sans ces quatre champs, elle affiche
              // « Produit inconnu » et sa réception ne sait pas quoi créditer.
              productName: produit.name,
              buyPrice: produit.buyPrice,
              sellPrice: produit.sellPrice,
              unit: produit.unit,
              fromShopName: nomDe[shopId],
              toShopName: nomDe[toShopId],
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
          'product_name': produit.name,
          'buy_price': produit.buyPrice,
          'sell_price': produit.sellPrice,
          'unit': produit.unit,
          'from_shop_name': nomDe[shopId],
          'to_shop_name': nomDe[toShopId],
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
        LocalProductsCompanion(quantity: Value(produit.quantity - quantity)),
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
    final transfert = await (db.select(
      db.localStockTransfers,
    )..where((row) => row.id.equals(transferId))).getSingleOrNull();
    if (transfert == null) throw Exception('Transfert introuvable.');
    if (transfert.toShopId != shopId) {
      throw Exception('Seule la boutique qui reçoit peut confirmer.');
    }
    if (receivedQuantity > transfert.quantity) {
      throw ArgumentError(
        'Tu ne peux pas recevoir plus que les ${transfert.quantity} envoyés.',
      );
    }
    // Confirmer deux fois créditait le stock deux fois.
    //
    // La méthode réécrivait simplement `received_quantity` — donc la ligne de
    // transfert restait juste — mais elle ajoutait la quantité au produit à
    // CHAQUE appel. Vu en vrai le 20/08/2026 : 6 bidons d'huile envoyés, 6
    // confirmés, 12 sur l'étagère. Invisible dans la table des transferts, qui
    // affichait sagement « 6 reçus ». Un double appui, un écran resté ouvert
    // sur deux appareils, et le stock d'une vraie boutique est faux.
    //
    // `annuler()` avait déjà cette garde ; la réception ne l'avait pas.
    if (transfert.receivedAt != null) {
      throw Exception(
        'Ce transfert a déjà été reçu le '
        '${transfert.receivedAt!.day.toString().padLeft(2, '0')}/'
        '${transfert.receivedAt!.month.toString().padLeft(2, '0')}. '
        'Le confirmer encore ajouterait la marchandise une deuxième fois.',
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
      if (receivedQuantity <= 0) return;

      // L'identité de l'article vient du TRANSFERT, plus de la fiche de
      // l'expéditeur.
      //
      // Cette fiche n'existe que dans la base de la boutique émettrice : le
      // destinataire ne l'a jamais téléchargée, puisque le pull filtre par
      // boutique active. La réception faisait donc `return` en silence dès
      // qu'on recevait depuis une boutique jamais ouverte sur cet appareil —
      // c'est-à-dire le cas normal du multi-boutique, deux téléphones. La
      // marchandise n'arrivait pas, et rien ne le disait.
      //
      // La fiche locale reste une roue de secours pour les transferts
      // enregistrés avant que ces colonnes existent.
      final envoye = await (db.select(
        db.localProducts,
      )..where((row) => row.id.equals(transfert.productId))).getSingleOrNull();

      final nom = transfert.productName ?? envoye?.name;
      if (nom == null) {
        throw Exception(
          'Ce transfert ne dit pas quel article il transporte : il a été '
          'envoyé par une version trop ancienne de l\'application. '
          'Demande à la boutique expéditrice de le refaire.',
        );
      }
      final prixAchat = transfert.buyPrice ?? envoye?.buyPrice ?? 0;
      final prixVente = transfert.sellPrice ?? envoye?.sellPrice ?? 0;
      final unite = transfert.unit ?? envoye?.unit;

      // Comparaison insensible à la casse et aux espaces.
      //
      // Une correspondance exacte fait déjà foi entre deux boutiques tenues
      // par la même personne — mais un commerçant qui a tapé « pain » ici et
      // « Pain » là-bas est le cas normal, pas l'exception : deux vendeurs
      // sur deux téléphones ne s'accordent jamais sur la casse d'un nom. Sans
      // ce nettoyage, la réception ne trouvait pas le jumeau, en créait un
      // second, et le stock se retrouvait scindé en deux fiches distinctes
      // du même article. Constaté le 19/08/2026 : « pain » (10) à côté de
      // « Pain » (110) dans la même boutique.
      final nomNormalise = nom.trim().toLowerCase();
      final produitsDeLaBoutique = await (db.select(
        db.localProducts,
      )..where((row) => row.shopId.equals(shopId))).get();
      var destination = produitsDeLaBoutique
          .where((p) => p.name.trim().toLowerCase() == nomNormalise)
          .firstOrNull;

      if (destination == null) {
        // Première réception de cet article ici : on le crée. C'est ce
        // qu'attend le commerçant — envoyer du riz vers une boutique qui n'en
        // vendait pas, c'est l'y introduire.
        final nouvelId = const Uuid().v4();
        destination = LocalProduct(
          id: nouvelId,
          shopId: shopId,
          name: nom,
          buyPrice: prixAchat,
          sellPrice: prixVente,
          quantity: 0,
          minQuantity: envoye?.minQuantity ?? 0,
          unit: unite,
        );
        await db.into(db.localProducts).insert(destination);
        await db.addToQueue(
          'ADD_PRODUCT',
          jsonEncode({
            'id': nouvelId,
            'shop_id': shopId,
            'name': nom,
            'buy_price': prixAchat,
            'sell_price': prixVente,
            'quantity': 0,
            'min_quantity': envoye?.minQuantity ?? 0,
            'barcode': null,
            'photo_url': null,
            if (unite != null) 'unit': unite,
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

  /// Annule un transfert envoyé par erreur — le seul cas sûr, celui où rien
  /// n'a encore bougé de l'autre côté.
  ///
  /// Restreint à l'EXPÉDITEUR et à l'AVANT réception : une fois que le
  /// destinataire a confirmé, la marchandise a déjà pu repartir de sa
  /// boutique à lui — annuler créditerait un stock qui n'existe plus chez
  /// lui. Le stock est rendu à l'expéditeur exactement comme il avait été
  /// retiré à l'envoi.
  Future<void> annuler(TransferEntry entree) async {
    final shopId = await requireShopId(ref);
    final transfert = entree.transfer;

    if (transfert.fromShopId != shopId) {
      throw Exception('Seule la boutique qui a envoyé peut annuler.');
    }
    if (transfert.receivedQuantity != null) {
      throw Exception(
        'Ce transfert a déjà été reçu, il ne peut plus être annulé.',
      );
    }
    if (transfert.cancelledAt != null) return;

    final db = ref.read(localDbProvider);
    final quand = DateTime.now();

    await db.transaction(() async {
      await (db.update(db.localStockTransfers)
            ..where((row) => row.id.equals(transfert.id)))
          .write(LocalStockTransfersCompanion(cancelledAt: Value(quand)));
      await db.addToQueue(
        'CANCEL_STOCK_TRANSFER',
        jsonEncode({
          'id': transfert.id,
          'cancelled_at': quand.toUtc().toIso8601String(),
        }),
      );

      final produit = await (db.select(
        db.localProducts,
      )..where((row) => row.id.equals(transfert.productId))).getSingleOrNull();
      // Le produit peut avoir été archivé ou supprimé entre-temps : le stock
      // local ne peut alors plus être rendu, mais le transfert doit rester
      // annulable — sinon un produit disparu bloquerait l'annulation pour de
      // bon.
      if (produit == null) return;

      await (db.update(
        db.localProducts,
      )..where((row) => row.id.equals(transfert.productId))).write(
        LocalProductsCompanion(
          quantity: Value(produit.quantity + transfert.quantity),
        ),
      );
      await db.addToQueue(
        'ADD_STOCK',
        jsonEncode({
          'movement_id': const Uuid().v4(),
          'product_id': transfert.productId,
          'shop_id': shopId,
          'quantity': transfert.quantity,
          'type': 'transfer_cancelled',
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

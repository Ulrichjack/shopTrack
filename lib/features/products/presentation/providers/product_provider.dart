// lib/features/products/presentation/providers/product_provider.dart

import 'dart:convert';
import 'dart:io' as import_io;
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/sync/revision_donnees.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/providers/current_shop_provider.dart';

/// Levée quand on tente de supprimer un produit déjà cité par une vente, un
/// comptage, un mouvement, une perte ou un transfert.
///
/// Typée plutôt que générique : l'écran doit pouvoir proposer l'archivage à la
/// place, ce qu'un message d'erreur ne permet pas.
class ProduitAvecHistoireException implements Exception {
  const ProduitAvecHistoireException();

  @override
  String toString() =>
      'Ce produit a déjà une histoire : ventes, comptages ou transferts. '
      'Le supprimer changerait des bilans déjà consultés.';
}

class ProductNotifier extends AsyncNotifier<List<ProductEntity>> {
  @override
  Future<List<ProductEntity>> build() async {
    // `watch` et non `read` — le piège documenté dans `current_shop_provider`.
    //
    // En `read`, ce provider ne se reconstruisait JAMAIS quand la boutique
    // changeait. Juste après la création d'une boutique, il se construisait
    // avant que celle-ci soit connue, concluait « aucun produit », et restait
    // sur ce vide : l'écran Stock affichait « 0 produit » pendant que le
    // comptage en listait cinq. Il fallait se déconnecter et se reconnecter
    // pour que le stock réapparaisse.
    // Et se relire quand la synchro a rempli la base : sans ça un vendeur
    // qui vient de se connecter garde un stock vide à l'écran pendant que
    // les produits arrivent derrière.
    ref.watch(revisionDonneesLocalesProvider);
    final shopId = await ref.watch(currentShopIdProvider.future);
    return _fetchProducts(shopId);
  }

  /// [shopIdConnu] évite de relire la boutique quand l'appelant la connaît
  /// déjà — et surtout, `watch` est interdit hors du `build` : les actions
  /// passent donc par ici sans observer quoi que ce soit.
  Future<List<ProductEntity>> _fetchProducts([String? shopIdConnu]) async {
    final db = ref.read(localDbProvider);

    // Filtré par boutique : la base locale garde les produits de TOUTES les
    // boutiques du compte. Sans ce filtre, ouvrir une boutique neuve affichait
    // le stock d'une autre — et un arrivage aurait été enregistré au mauvais
    // endroit sans que rien ne le signale.
    final shopId = shopIdConnu ?? await ref.read(currentShopIdProvider.future);
    if (shopId == null || shopId.isEmpty) return const [];

    // Les produits archivés sortent d'ici : ils ne s'affichent plus au stock,
    // au comptage ni à la vente. Leur passé, lui, reste en base — les rapports
    // de périodes closes continuent de les citer.
    final localProducts =
        await (db.select(db.localProducts)..where(
              (row) => row.shopId.equals(shopId) & row.archivedAt.isNull(),
            ))
            .get();

    return localProducts.map(_toEntity).toList();
  }

  /// Les produits mis au placard, pour pouvoir les ressortir.
  Future<List<ProductEntity>> fetchArchivedProducts() async {
    final db = ref.read(localDbProvider);
    final shopId = await ref.read(currentShopIdProvider.future);
    if (shopId == null || shopId.isEmpty) return const [];

    final archives =
        await (db.select(db.localProducts)
              ..where(
                (row) => row.shopId.equals(shopId) & row.archivedAt.isNotNull(),
              )
              ..orderBy([
                (row) => drift.OrderingTerm(
                  expression: row.archivedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ]))
            .get();

    return archives.map(_toEntity).toList();
  }

  ProductEntity _toEntity(LocalProduct p) => ProductEntity(
    id: p.id,
    shopId: p.shopId,
    name: p.name,
    buyPrice: p.buyPrice,
    sellPrice: p.sellPrice,
    quantity: p.quantity,
    minQuantity: p.minQuantity,
    barcode: p.barcode,
    photoUrl: p.photoUrl,
    // Oubli initial : sans cette ligne l'unité existait en base mais
    // disparaissait dès le chargement. Les pastilles d'unités connues
    // restaient vides, et surtout MODIFIER un produit effaçait son unité —
    // l'écran pré-remplissait le champ avec une valeur toujours nulle.
    unit: p.unit,
    archivedAt: p.archivedAt,
  );

  Future<void> _cacheProduct(Map<String, dynamic> data) async {
    final db = ref.read(localDbProvider);
    await db
        .into(db.localProducts)
        .insert(
          LocalProduct(
            id: data['id'] as String,
            shopId: data['shop_id'] as String,
            name: data['name'] as String,
            buyPrice: (data['buy_price'] as num).toDouble(),
            sellPrice: (data['sell_price'] as num).toDouble(),
            quantity: data['quantity'] as int,
            minQuantity: data['min_quantity'] as int,
            barcode: data['barcode'] as String?,
            photoUrl: data['photo_url'] as String?,
            unit: data['unit'] as String?,
            // Sans cette ligne, remettre un produit en cache le sortirait du
            // placard tout seul.
            archivedAt: data['archived_at'] == null
                ? null
                : DateTime.parse(data['archived_at'] as String).toLocal(),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> _ensureBarcodeAvailable({
    required String barcode,
    required String shopId,
    String? excludedProductId,
    required bool isOnline,
  }) async {
    final db = ref.read(localDbProvider);
    final localMatches = await (db.select(
      db.localProducts,
    )..where((product) => product.barcode.equals(barcode))).get();
    final localConflict = localMatches
        .where((product) => product.id != excludedProductId)
        .firstOrNull;
    if (localConflict != null) {
      throw Exception(
        'Ce QR/code-barres est déjà utilisé par « ${localConflict.name} ». '
        'Chaque produit doit avoir un code différent.',
      );
    }

    if (!isOnline || Supabase.instance.client.auth.currentUser == null) return;

    final remoteMatches = await Supabase.instance.client
        .from('products')
        .select('id,name')
        .eq('shop_id', shopId)
        .eq('barcode', barcode)
        .limit(2);
    final remoteConflict = remoteMatches
        .where((product) => product['id'] != excludedProductId)
        .firstOrNull;
    if (remoteConflict != null) {
      throw Exception(
        'Ce QR/code-barres est déjà utilisé par '
        '« ${remoteConflict['name']} » dans Supabase.',
      );
    }
  }

  /// Recherche fiable pour le scanner : cache local, puis Supabase.
  Future<ProductEntity?> findByBarcode(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return null;

    final db = ref.read(localDbProvider);
    // Un produit archivé garde son code — c'est ce qui évite qu'on réattribue
    // le même à un autre — mais il ne doit plus se vendre au scan.
    final local =
        await (db.select(db.localProducts)
              ..where(
                (product) =>
                    product.barcode.equals(barcode) &
                    product.archivedAt.isNull(),
              )
              ..orderBy([(product) => drift.OrderingTerm.asc(product.name)])
              ..limit(1))
            .getSingleOrNull();
    if (local != null) return _toEntity(local);

    final isOnline = ref.read(connectivityProvider).value ?? false;
    if (!isOnline || Supabase.instance.client.auth.currentUser == null) {
      return null;
    }

    // Envoie d'abord un produit éventuellement créé sur cet appareil.
    await ref.read(syncServiceProvider).processQueue();

    final shopId = await ref.read(currentShopIdProvider.future);
    if (shopId == null || shopId.isEmpty) return null;

    final remote = await Supabase.instance.client
        .from('products')
        .select()
        .eq('shop_id', shopId)
        .eq('barcode', barcode)
        .order('name')
        .limit(1)
        .maybeSingle();
    if (remote == null) return null;

    await _cacheProduct(remote);
    final products = await _fetchProducts();
    state = AsyncValue.data(products);
    return products.where((product) => product.id == remote['id']).firstOrNull;
  }

  Future<void> addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required int minQuantity,
    String? barcode,
    String? unit,
    import_io.File? imageFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? true;
      final db = ref.read(localDbProvider);

      // La boutique ACTIVE, via la source unique.
      //
      // Ce bloc demandait au serveur « la » boutique du compte, avec un
      // `.single()` sur `shop_members`. Deux défauts d'un coup : dès la
      // deuxième boutique, le serveur renvoyait plusieurs lignes et la
      // création échouait sur un `PGRST116` incompréhensible (« The result
      // contains 3 rows ») ; et même à une seule ligne, rien ne garantissait
      // que ce soit la boutique ouverte à l'écran — un patron qui bascule sur
      // sa deuxième épicerie aurait créé le produit dans la première.
      //
      // `requireShopId` lit la boutique active et fonctionne hors ligne :
      // l'aller-retour réseau et sa branche de repli disparaissent avec lui.
      final shopId = await requireShopId(ref);

      String? photoUrl;

      final String finalBarcode = (barcode == null || barcode.trim().isEmpty)
          ? 'QR-${DateTime.now().microsecondsSinceEpoch}-${const Uuid().v4()}'
          : barcode.trim();
      await _ensureBarcodeAvailable(
        barcode: finalBarcode,
        shopId: shopId,
        isOnline: isOnline,
      );

      if (isOnline && imageFile != null) {
        final fileName =
            '${shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('product-photos')
            .upload(fileName, imageFile);
        photoUrl = Supabase.instance.client.storage
            .from('product-photos')
            .getPublicUrl(fileName);
      }

      final newId = const Uuid().v4();

      final productData = {
        'id': newId,
        'shop_id': shopId,
        'name': name,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'quantity': quantity,
        'min_quantity': minQuantity,
        'barcode': finalBarcode,
        'photo_url': photoUrl,
        if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
      };

      await db
          .into(db.localProducts)
          .insert(
            LocalProduct(
              id: newId,
              shopId: shopId,
              name: name,
              buyPrice: buyPrice,
              sellPrice: sellPrice,
              quantity: quantity,
              minQuantity: minQuantity,
              barcode: finalBarcode,
              photoUrl: photoUrl,
              unit: (unit == null || unit.trim().isEmpty) ? null : unit.trim(),
            ),
          );

      await db.addToQueue('ADD_PRODUCT', jsonEncode(productData));
      await ref.read(syncServiceProvider).processQueue();
      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      state = AsyncValue.data(await _fetchProducts());
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required int minQuantity,
    String? barcode,
    String? unit,
    String? existingPhotoUrl,
    import_io.File? newImageFile,
  }) async {
    final previousProducts = state.value ?? await _fetchProducts();
    state = const AsyncValue.loading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? true;
      final db = ref.read(localDbProvider);

      // Même source que la création. Déduire la boutique du premier produit
      // de la liste marchait — `_fetchProducts` la filtre déjà sur la
      // boutique active — mais échouait avec « Boutique introuvable » dès que
      // la liste était vide, et reposait sur un détail d'implémentation d'une
      // autre méthode.
      final shopId = await requireShopId(ref);

      String? finalPhotoUrl = existingPhotoUrl;

      final String finalBarcode = (barcode == null || barcode.trim().isEmpty)
          ? 'QR-${DateTime.now().microsecondsSinceEpoch}-${const Uuid().v4()}'
          : barcode.trim();
      await _ensureBarcodeAvailable(
        barcode: finalBarcode,
        shopId: shopId,
        excludedProductId: id,
        isOnline: isOnline,
      );

      if (isOnline && newImageFile != null) {
        final fileName =
            '${shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('product-photos')
            .upload(fileName, newImageFile);
        finalPhotoUrl = Supabase.instance.client.storage
            .from('product-photos')
            .getPublicUrl(fileName);
      }

      final productData = {
        'id': id,
        'shop_id': shopId,
        'name': name,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'quantity': quantity,
        'min_quantity': minQuantity,
        'barcode': finalBarcode,
        'photo_url': finalPhotoUrl,
        if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
      };

      await (db.update(db.localProducts)..where((t) => t.id.equals(id))).write(
        LocalProductsCompanion(
          name: drift.Value(name),
          buyPrice: drift.Value(buyPrice),
          sellPrice: drift.Value(sellPrice),
          quantity: drift.Value(quantity),
          minQuantity: drift.Value(minQuantity),
          barcode: drift.Value(finalBarcode),
          photoUrl: drift.Value(finalPhotoUrl),
          unit: drift.Value(
            (unit == null || unit.trim().isEmpty) ? null : unit.trim(),
          ),
        ),
      );

      await db.addToQueue('UPDATE_PRODUCT', jsonEncode(productData));

      // Modifier les prix depuis la fiche trace aussi le tarif : sinon un
      // changement fait ici échapperait à l'historique et réévaluerait les
      // périodes closes, exactement ce que cet historique évite.
      final ancien = previousProducts.where((p) => p.id == id).firstOrNull;
      if (ancien != null) {
        await _recordPriceChange(
          db,
          productId: id,
          shopId: ancien.shopId,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          previousBuyPrice: ancien.buyPrice,
          previousSellPrice: ancien.sellPrice,
        );
      }

      await ref.read(syncServiceProvider).processQueue();

      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      state = AsyncValue.data(await _fetchProducts());
      rethrow;
    }
  }

  /// Enregistre le tarif du jour si l'un des deux prix a changé.
  ///
  /// Une ligne par changement, avec sa date : le rapport de période valorise
  /// ensuite au prix réellement pratiqué. Sans cet historique, remonter un
  /// prix réévalue tout seul les périodes déjà closes.
  Future<void> _recordPriceChange(
    AppDatabase db, {
    required String productId,
    required String shopId,
    required double buyPrice,
    required double sellPrice,
    required double previousBuyPrice,
    required double previousSellPrice,
  }) async {
    if (buyPrice == previousBuyPrice && sellPrice == previousSellPrice) return;

    final id = const Uuid().v4();
    final effectiveAt = DateTime.now();
    await db
        .into(db.localProductPrices)
        .insert(
          LocalProductPrice(
            id: id,
            shopId: shopId,
            productId: productId,
            buyPrice: buyPrice,
            sellPrice: sellPrice,
            effectiveAt: effectiveAt,
          ),
        );
    await db.addToQueue(
      'ADD_PRODUCT_PRICE',
      jsonEncode({
        'id': id,
        'shop_id': shopId,
        'product_id': productId,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'effective_at': effectiveAt.toUtc().toIso8601String(),
      }),
    );
  }

  /// Supprime un produit — seulement s'il n'a **aucune histoire**.
  ///
  /// Un produit déjà vendu, compté, transféré ou racheté est cité par des
  /// périodes closes. L'effacer réécrirait des bilans déjà consultés : un
  /// rapport de mars perdrait une ligne et changerait de bénéfice, sans que
  /// personne comprenne pourquoi.
  ///
  /// On ne supprime donc que ce qui a été créé par erreur, et on explique le
  /// refus dans les autres cas plutôt que de le faire à moitié.
  Future<void> deleteProduct(String productId) async {
    final db = ref.read(localDbProvider);

    final comptages = await (db.select(
      db.localInventoryCounts,
    )..where((row) => row.productId.equals(productId))).get();
    final ventes = await (db.select(
      db.localSaleItems,
    )..where((row) => row.productId.equals(productId))).get();
    final mouvements = await (db.select(
      db.localStockMovements,
    )..where((row) => row.productId.equals(productId))).get();
    final pertes = await (db.select(
      db.localInventoryLosses,
    )..where((row) => row.productId.equals(productId))).get();
    final transferts = await (db.select(
      db.localStockTransfers,
    )..where((row) => row.productId.equals(productId))).get();

    if (comptages.isNotEmpty ||
        ventes.isNotEmpty ||
        mouvements.isNotEmpty ||
        pertes.isNotEmpty ||
        transferts.isNotEmpty) {
      throw const ProduitAvecHistoireException();
    }

    await db.transaction(() async {
      await (db.delete(
        db.localProducts,
      )..where((row) => row.id.equals(productId))).go();
      await db.addToQueue('DELETE_PRODUCT', jsonEncode({'id': productId}));
    });

    await ref.read(syncServiceProvider).processQueue();
    state = AsyncValue.data(await _fetchProducts());
  }

  /// Met un produit au placard : il quitte le stock, le comptage et la vente,
  /// et garde tout son passé.
  ///
  /// C'est la sortie pour un produit qu'on arrête de vendre. La suppression
  /// n'est possible que sur un produit qui n'a jamais servi ; l'archivage,
  /// lui, n'a aucune condition parce qu'il ne réécrit rien.
  Future<void> archiveProduct(String productId) async {
    await _definirArchivage(productId, DateTime.now());
  }

  /// Ressort un produit du placard, tel qu'il y est entré.
  Future<void> unarchiveProduct(String productId) async {
    await _definirArchivage(productId, null);
  }

  Future<void> _definirArchivage(String productId, DateTime? moment) async {
    final db = ref.read(localDbProvider);

    await db.transaction(() async {
      await (db.update(db.localProducts)
            ..where((row) => row.id.equals(productId)))
          .write(LocalProductsCompanion(archivedAt: drift.Value(moment)));
      await db.addToQueue(
        'UPDATE_PRODUCT',
        jsonEncode({
          'id': productId,
          'archived_at': moment?.toUtc().toIso8601String(),
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    state = AsyncValue.data(await _fetchProducts());
  }

  // 👇 NOUVEAU : Fonction pour ajouter du stock (100% Local + File d'attente)
  ///
  /// [unitCost] est le prix payé pour CET arrivage. Fourni, il crée une ligne
  /// d'achat qui fige le coût : revaloriser le produit plus tard ne réécrira
  /// plus les périodes déjà closes. Absent, le comportement est inchangé.
  Future<void> addStock(
    ProductEntity product,
    int addedQuantity, {
    double? unitCost,
    double? sellPrice,

    /// Le jour où la marchandise est ARRIVÉE, pas celui de la saisie.
    ///
    /// En mode inventaire, le rapport découpe par période : un arrivage
    /// enregistré après le comptage de clôture tombe dans la période suivante
    /// et n'explique donc rien du bilan qu'on est en train de lire. Le
    /// commerçant qui note sa livraison de lundi le mercredi soir verrait ses
    /// ventes présumées s'effondrer sans comprendre pourquoi.
    DateTime? recuLe,
  }) async {
    try {
      final db = ref.read(localDbProvider);
      final newQty = product.quantity + addedQuantity;

      // 1. Mettre à jour la quantité en local
      await (db.update(db.localProducts)..where((t) => t.id.equals(product.id)))
          .write(LocalProductsCompanion(quantity: drift.Value(newQty)));

      // 2. Ajouter l'historique de recharge en local
      final movementId = const Uuid().v4();
      await db
          .into(db.localStockMovements)
          .insert(
            LocalStockMovement(
              id: movementId,
              shopId: product.shopId,
              productId: product.id,
              quantity: addedQuantity,
              type: 'recharge',
              // La date de RÉCEPTION, pas celle de la saisie : c'est elle que
              // l'historique du produit affiche, et le serveur la reçoit dans
              // le message ci-dessous pour que le deuxième téléphone voie la
              // même chose après téléchargement.
              createdAt: recuLe ?? DateTime.now(),
            ),
          );

      // 3. Mettre dans la salle d'attente pour Supabase
      final payload = {
        'movement_id': movementId,
        'product_id': product.id,
        'shop_id': product.shopId,
        'quantity': addedQuantity,
        'type': 'recharge',
        if (recuLe != null) 'created_at': recuLe.toUtc().toIso8601String(),
      };
      await db.addToQueue('ADD_STOCK', jsonEncode(payload));

      if (unitCost != null) {
        // Le prix affiché sur la fiche suit le dernier prix payé : sinon le
        // commerçant lit 22 000 alors qu'il vient d'en payer 24 000, et il
        // fixe son prix de vente sur un coût périmé. L'historique, lui, est
        // protégé par les lignes d'achat qui gardent chacune leur prix.
        final nouveauPrixVente = sellPrice ?? product.sellPrice;
        if (unitCost != product.buyPrice ||
            nouveauPrixVente != product.sellPrice) {
          await (db.update(
            db.localProducts,
          )..where((t) => t.id.equals(product.id))).write(
            LocalProductsCompanion(
              buyPrice: drift.Value(unitCost),
              sellPrice: drift.Value(nouveauPrixVente),
            ),
          );
          await db.addToQueue(
            'UPDATE_PRODUCT',
            jsonEncode({
              'id': product.id,
              'buy_price': unitCost,
              'sell_price': nouveauPrixVente,
            }),
          );
          await _recordPriceChange(
            db,
            productId: product.id,
            shopId: product.shopId,
            buyPrice: unitCost,
            sellPrice: nouveauPrixVente,
            previousBuyPrice: product.buyPrice,
            previousSellPrice: product.sellPrice,
          );
        }

        final purchaseId = const Uuid().v4();
        final purchasedAt = recuLe ?? DateTime.now();
        await db
            .into(db.localStockPurchases)
            .insert(
              LocalStockPurchase(
                id: purchaseId,
                shopId: product.shopId,
                productId: product.id,
                quantity: addedQuantity,
                unitCost: unitCost,
                purchasedAt: purchasedAt,
              ),
            );
        await db.addToQueue(
          'ADD_STOCK_PURCHASE',
          jsonEncode({
            'id': purchaseId,
            'shop_id': product.shopId,
            'product_id': product.id,
            'quantity': addedQuantity,
            'unit_cost': unitCost,
            'purchased_at': purchasedAt.toUtc().toIso8601String(),
          }),
        );
      }

      await ref.read(syncServiceProvider).processQueue();

      // 4. Rafraîchir l'écran
      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      rethrow;
    }
  }
}

/// Unités déjà utilisées dans cette boutique, les plus fréquentes d'abord.
/// Propre à la boutique par construction (les produits le sont), donc un
/// dépôt de boissons et une épicerie n'auront jamais les mêmes suggestions.
final knownUnitsProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productProvider).value ?? const [];
  final counts = <String, int>{};
  for (final product in products) {
    final unit = product.unit?.trim();
    if (unit == null || unit.isEmpty) continue;
    counts[unit] = (counts[unit] ?? 0) + 1;
  }
  final units = counts.keys.toList()
    ..sort((a, b) {
      final byUse = counts[b]!.compareTo(counts[a]!);
      return byUse != 0 ? byUse : a.compareTo(b);
    });
  return units;
});

final productProvider =
    AsyncNotifierProvider<ProductNotifier, List<ProductEntity>>(() {
      return ProductNotifier();
    });

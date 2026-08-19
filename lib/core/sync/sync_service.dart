import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../providers/current_shop_provider.dart';
import 'pull_registry.dart';

final localDbProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref.read(localDbProvider), ref);
  ref.onDispose(service.dispose);
  return service;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.statusStream;
});

/// Les opérations que le serveur refuse. Se recalcule à chaque changement
/// d'état de synchro, pour que l'écran suive une reprise ou un abandon.
final blockedSyncItemsProvider = FutureProvider<List<SyncQueueItem>>((
  ref,
) async {
  ref.watch(syncStatusProvider);
  return ref.read(syncServiceProvider).blockedItems();
});

enum SyncPhase { idle, sending, downloading, success, error }

class SyncStatus {
  const SyncStatus({
    required this.phase,
    required this.pendingCount,
    this.blockedCount = 0,
    this.lastSyncAt,
    this.lastError,
  });

  const SyncStatus.initial()
    : phase = SyncPhase.idle,
      pendingCount = 0,
      blockedCount = 0,
      lastSyncAt = null,
      lastError = null;

  final SyncPhase phase;
  final int pendingCount;

  /// Opérations mises de côté, que le serveur refuse et qui ne repartiront
  /// pas seules. Compté à part : le reste de la file continue d'avancer, et
  /// un compteur qui descend ne doit pas laisser croire que tout est passé.
  final int blockedCount;

  final DateTime? lastSyncAt;
  final String? lastError;
}

class SyncService {
  SyncService(this.db, this.ref);

  final AppDatabase db;

  /// Sert à connaître la boutique active. La synchro ne la décide pas : elle
  /// travaille sur celle que le commerçant a choisie.
  final Ref ref;
  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = const SyncStatus.initial();
  bool _isSyncing = false;
  bool _isPulling = false;

  Stream<SyncStatus> get statusStream async* {
    yield _status;
    yield* _statusController.stream;
  }

  void _emit({
    required SyncPhase phase,
    int? pendingCount,
    int? blockedCount,
    DateTime? lastSyncAt,
    String? lastError,
  }) {
    _status = SyncStatus(
      phase: phase,
      pendingCount: pendingCount ?? _status.pendingCount,
      blockedCount: blockedCount ?? _status.blockedCount,
      lastSyncAt: lastSyncAt ?? _status.lastSyncAt,
      lastError: lastError,
    );
    if (!_statusController.isClosed) _statusController.add(_status);
  }

  Future<void> refreshStatus() async {
    _emit(
      phase: _isSyncing
          ? SyncPhase.sending
          : _isPulling
          ? SyncPhase.downloading
          : SyncPhase.idle,
      pendingCount: await db.getPendingCount(),
      blockedCount: await db.getSetAsideCount(),
      lastError: _status.lastError,
    );
  }

  Future<void> synchronize() async {
    await processQueue();
    await pullDataFromSupabase();
  }

  Future<void> pullDataFromSupabase() async {
    // Ne JAMAIS écraser les données locales tant qu'une écriture n'est pas
    // partie : le serveur ignore encore cette vente, donc son stock est
    // périmé. La garde vit ici et pas chez l'appelant, sinon un appel direct
    // (dashboard, bilan) la contourne et fait « remonter » le stock vendu.
    // Les opérations mises de côté comptent aussi. Les ignorer débloquerait
    // le téléchargement, mais écraserait le stock local avec un stock serveur
    // qui ignore l'opération refusée — la vente disparaîtrait des deux côtés.
    // On préfère un téléchargement à l'arrêt et un bandeau qui réclame une
    // décision, plutôt qu'un chiffre faux que personne ne remarque.
    if (_isPulling || await db.getPendingCount() > 0) return;

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isPulling = true;
    _emit(
      phase: SyncPhase.downloading,
      pendingCount: await db.getPendingCount(),
    );

    try {
      // La boutique active, pas « la » boutique du compte : `.single()`
      // supposait un seul rattachement et levait une exception dès le
      // deuxième. Le patron en a trois.
      final shopId = await ref.read(currentShopIdProvider.future);
      if (shopId == null || shopId.isEmpty) {
        // Rien à télécharger tant qu'aucune boutique n'est choisie : la
        // première connexion la renseigne, la synchro suivra.
        _emit(phase: SyncPhase.idle, pendingCount: await db.getPendingCount());
        return;
      }

      // Une table absente côté serveur ne doit pas emporter tout le
      // téléchargement. Vu en vrai : la migration `product_prices` pas encore
      // appliquée, et plus aucun produit ni comptage ne descendait. Le pull
      // fusionne sans jamais vider, donc une table vide est sans danger — on
      // note l'échec et on continue avec les autres.
      final tablesEnEchec = <String>[];
      Future<List<dynamic>> tirer(String nom, Future<dynamic> requete) async {
        try {
          return (await requete) as List<dynamic>;
        } catch (erreur) {
          // Bruyant dans les logs : depuis que le pull survit à une table
          // absente, un échec ne casse plus rien de visible — l'app affiche
          // juste des données manquantes sans dire pourquoi. Sans cette trace,
          // le diagnostic redevient de la devinette.
          debugPrint('[SYNC] échec du téléchargement de $nom : $erreur');
          tablesEnEchec.add(nom);
          return const [];
        }
      }

      final resultats = await Future.wait([
        for (final table in tablesTirees)
          tirer(table.nom, table.tirer(supabase, shopId)),
      ]);

      // Fusionner au lieu de vider les tables protège les écritures faites
      // hors ligne qui ne sont pas encore parties.
      await db.transaction(() async {
        await db.batch((batch) {
          for (var i = 0; i < tablesTirees.length; i++) {
            tablesTirees[i].appliquer(db, batch, resultats[i]);
          }
        });
      });

      int compte(String nom) {
        final index = tablesTirees.indexWhere((table) => table.nom == nom);
        return index < 0 ? 0 : resultats[index].length;
      }

      debugPrint(
        '[SYNC] téléchargement terminé — '
        '${compte('products')} produits, ${compte('inventory_counts')} '
        'comptages, ${compte('shop_takings')} recettes'
        '${tablesEnEchec.isEmpty ? '' : ' — ÉCHECS : ${tablesEnEchec.join(', ')}'}',
      );
      _emit(
        phase: tablesEnEchec.isEmpty ? SyncPhase.success : SyncPhase.error,
        pendingCount: await db.getPendingCount(),
        lastSyncAt: tablesEnEchec.isEmpty ? DateTime.now() : null,
        lastError: tablesEnEchec.isEmpty
            ? null
            : 'Tables non téléchargées : ${tablesEnEchec.join(', ')}. '
                  'Une migration Supabase n\'a probablement pas été appliquée.',
      );
    } catch (error) {
      _emit(
        phase: SyncPhase.error,
        pendingCount: await db.getPendingCount(),
        lastError: error.toString(),
      );
      rethrow;
    } finally {
      _isPulling = false;
    }
  }

  /// Refus consécutifs avant qu'une opération soit mise de côté. Assez haut
  /// pour absorber un incident serveur passager, assez bas pour qu'une
  /// opération définitivement refusée ne gèle pas la file une semaine.
  static const int maxRefusAvantMiseDeCote = 5;

  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _emit(phase: SyncPhase.sending, pendingCount: await db.getPendingCount());

    String? lastError;
    try {
      final pendingItems = await db.getPendingItems();

      // Ce qui est en attente d'une opération coincée. La file reste ordonnée
      // là où l'ordre compte — on ne crée pas le stock d'un produit dont la
      // création n'est pas passée — mais une vente de riz n'a aucune raison
      // d'attendre qu'un transfert de sucre soit débloqué.
      final porteesBloquees = <String>{};

      for (final item in pendingItems) {
        Map<String, dynamic>? payload;
        try {
          payload = jsonDecode(item.payload) as Map<String, dynamic>;
        } catch (error) {
          // Charge illisible : impossible de savoir ce qu'elle touche, donc
          // impossible de laisser passer la suite sans risque. On arrête tout.
          debugPrint('[SYNC] charge illisible sur ${item.action} : $error');
          lastError = error.toString();
          await _noterRefus(item, error);
          break;
        }

        final portees = _porteesDe(item.action, payload);
        if (item.setAside) {
          // Mise de côté : elle ne repart pas seule, et tout ce qui dépend
          // d'elle attend avec elle.
          porteesBloquees.addAll(portees);
          continue;
        }
        if (portees.any(porteesBloquees.contains)) continue;

        try {
          await _processItem(item.action, payload);
          await db.removeFromQueue(item.id);
        } catch (error) {
          // Bruyant : sans trace on ne voit qu'un compteur d'opérations qui
          // ne descend plus. Le nom de l'action dit laquelle coince.
          debugPrint('[SYNC] échec de l\'envoi ${item.action} : $error');
          lastError = error.toString();
          porteesBloquees.addAll(portees);

          if (!estUnRefusDuServeur(error)) {
            // Le serveur n'a rien dit — réseau coupé, session à rafraîchir.
            // Rien ne sert d'essayer les suivantes, et surtout : on ne compte
            // pas ce coup-là, sinon une semaine hors ligne mettrait de côté
            // tout le travail d'un commerçant.
            break;
          }
          await _noterRefus(item, error);
        }
      }
    } finally {
      _isSyncing = false;
      final pendingCount = await db.getPendingCount();
      final blockedCount = await db.getSetAsideCount();
      _emit(
        phase: lastError == null ? SyncPhase.success : SyncPhase.error,
        pendingCount: pendingCount,
        blockedCount: blockedCount,
        lastSyncAt: lastError == null ? DateTime.now() : null,
        lastError: lastError,
      );
    }
  }

  Future<void> _noterRefus(SyncQueueItem item, Object error) async {
    final tentatives = item.attempts + 1;
    await db.noteQueueFailure(
      item.id,
      attempts: tentatives,
      error: error.toString(),
      setAside: tentatives >= maxRefusAvantMiseDeCote,
    );
    if (tentatives >= maxRefusAvantMiseDeCote) {
      debugPrint(
        '[SYNC] ${item.action} mise de côté après $tentatives refus',
      );
    }
  }

  /// Distingue un refus du serveur d'une panne de transport.
  ///
  /// Un refus est une réponse : la donnée est rejetée, la réessayer mille
  /// fois ne changera rien. Une panne de réseau n'est pas une réponse — le
  /// message n'est jamais arrivé. Confondre les deux ferait mettre de côté du
  /// travail valide simplement parce que la boutique était hors couverture.
  bool estUnRefusDuServeur(Object erreur) {
    if (erreur is SocketException || erreur is TimeoutException) return false;
    // Session expirée : il faut rafraîchir le jeton, pas jeter l'opération.
    if (erreur is AuthException) return false;
    if (erreur is PostgrestException) return true;

    final texte = erreur.toString();
    const pannesDeTransport = [
      'ClientException',
      'Failed host lookup',
      'Connection closed',
      'Connection refused',
      'Connection reset',
      'Software caused connection abort',
    ];
    if (pannesDeTransport.any(texte.contains)) return false;
    return true;
  }

  /// Ce qu'une opération touche. Deux opérations sans portée commune ne
  /// s'attendent pas.
  ///
  /// La dépendance réelle du projet est le produit : sa création doit passer
  /// avant son stock, son prix, son unité, son comptage, sa perte. Une vente
  /// dépend de tous les produits qu'elle contient.
  Set<String> _porteesDe(String action, Map<String, dynamic> payload) {
    String produit(Object? id) => 'produit:$id';

    switch (action) {
      case 'CREATE_SALE':
        final items = payload['items'];
        if (items is List) {
          return {
            for (final item in items)
              if (item is Map) produit(item['product_id']),
          };
        }
        return {'vente:${payload['sale']}'};
      case 'ADD_PRODUCT':
      case 'UPDATE_PRODUCT':
      case 'DELETE_PRODUCT':
        return {produit(payload['id'])};
      case 'ADD_STOCK':
      case 'ADD_INVENTORY_COUNT':
      case 'ADD_INVENTORY_LOSS':
      case 'ADD_STOCK_PURCHASE':
      case 'ADD_PRODUCT_PRICE':
      case 'ADD_CYCLE_LOSS':
        return {produit(payload['product_id'])};
      case 'ADD_PRODUCT_UNIT':
        return {produit(payload['product_id']), 'unite:${payload['id']}'};
      case 'DELETE_PRODUCT_UNIT':
        return {'unite:${payload['id']}'};
      case 'ADD_STOCK_TRANSFER':
      case 'CONFIRM_STOCK_TRANSFER':
      case 'CANCEL_STOCK_TRANSFER':
        return {
          'transfert:${payload['id']}',
          if (payload['product_id'] != null) produit(payload['product_id']),
        };
      case 'ADD_SUPPLY_CYCLE':
      case 'CLOSE_SUPPLY_CYCLE':
        return {'cycle:${payload['id']}'};
      case 'ADD_CASH_MOVEMENT':
        return {'caisse:${payload['id']}'};
      case 'ADD_CLOSING':
        return {'cloture:${payload['shop_id']}:${payload['closing_date']}'};
      case 'SET_SHOP_SETTINGS':
        return {'reglages:${payload['shop_id']}'};
      case 'ADD_SHOP_TAKINGS':
        return {'recette:${payload['shop_id']}:${payload['date']}'};
      default:
        // Action inconnue : on ne sait pas ce qu'elle touche, donc on la
        // traite comme touchant tout. Prudence volontaire.
        return {'inconnu'};
    }
  }

  /// Les opérations mises de côté, pour les montrer et les décider.
  Future<List<SyncQueueItem>> blockedItems() => db.getSetAsideItems();

  /// Remet tout ce qui est de côté dans le circuit et relance un envoi.
  Future<void> retryBlocked() async {
    await db.requeueAllSetAside();
    await processQueue();
  }

  /// Abandonne définitivement une opération refusée. La donnée locale reste :
  /// seul son envoi est annulé.
  Future<void> discardBlocked(int id) async {
    await db.removeFromQueue(id);
    await refreshStatus();
  }

  Future<void> _processItem(String action, Map<String, dynamic> payload) async {
    final supabase = Supabase.instance.client;
    switch (action) {
      case 'CREATE_SALE':
        await _syncSale(payload);
      case 'ADD_CASH_MOVEMENT':
        await supabase.from('cash_movements').upsert(payload);
      case 'ADD_PRODUCT':
        await supabase.from('products').upsert(payload);
      case 'UPDATE_PRODUCT':
        await supabase.from('products').update(payload).eq('id', payload['id']);
      case 'ADD_STOCK':
        await supabase.rpc(
          'apply_stock_movement',
          params: {
            'p_movement_id': payload['movement_id'],
            'p_shop_id': payload['shop_id'],
            'p_product_id': payload['product_id'],
            'p_quantity_delta': payload['quantity'],
            'p_type': payload['type'],
          },
        );
      case 'ADD_CLOSING':
        await supabase
            .from('daily_closings')
            .upsert(payload, onConflict: 'shop_id,closing_date');
      case 'SET_SHOP_SETTINGS':
        await supabase
            .from('shop_settings')
            .upsert(payload, onConflict: 'shop_id');
      case 'ADD_SHOP_TAKINGS':
        await supabase
            .from('shop_takings')
            .upsert(payload, onConflict: 'shop_id,date');
      case 'ADD_INVENTORY_COUNT':
        await supabase.from('inventory_counts').upsert(payload);
      case 'ADD_INVENTORY_LOSS':
        await supabase.from('inventory_losses').upsert(payload);
      case 'ADD_STOCK_PURCHASE':
        await supabase.from('stock_purchases').upsert(payload);
      case 'ADD_PRODUCT_PRICE':
        await supabase.from('product_prices').upsert(payload);
      case 'DELETE_PRODUCT':
        await supabase.from('products').delete().eq('id', payload['id']);
      case 'ADD_STOCK_TRANSFER':
        await supabase.from('stock_transfers').upsert(payload);
      case 'CONFIRM_STOCK_TRANSFER':
        await supabase
            .from('stock_transfers')
            .update({
              'received_quantity': payload['received_quantity'],
              'received_at': payload['received_at'],
            })
            .eq('id', payload['id']);
      case 'CANCEL_STOCK_TRANSFER':
        await supabase
            .from('stock_transfers')
            .update({'cancelled_at': payload['cancelled_at']})
            .eq('id', payload['id']);
      case 'ADD_SUPPLY_CYCLE':
        await supabase.from('supply_cycles').upsert(payload);
      case 'CLOSE_SUPPLY_CYCLE':
        await supabase
            .from('supply_cycles')
            .update({
              'status': payload['status'],
              'closed_at': payload['closed_at'],
            })
            .eq('id', payload['id']);
      case 'ADD_PRODUCT_UNIT':
        await supabase.from('product_units').upsert(payload);
      case 'DELETE_PRODUCT_UNIT':
        await supabase.from('product_units').delete().eq('id', payload['id']);
      case 'ADD_CYCLE_LOSS':
        await supabase.from('cycle_losses').upsert(payload);
      default:
        throw StateError('Action de synchronisation inconnue : $action');
    }
  }

  Future<void> _syncSale(Map<String, dynamic> payload) async {
    final supabase = Supabase.instance.client;
    final saleData = Map<String, dynamic>.from(
      payload['sale'] as Map<String, dynamic>,
    );
    final itemsData = List<Map<String, dynamic>>.from(payload['items']);

    await supabase.from('sales').upsert(saleData);
    final rowsToInsert = itemsData.map((item) {
      final row = Map<String, dynamic>.from(item);
      row.remove('stock_movement_id');
      return row;
    }).toList();
    await supabase.from('sale_items').upsert(rowsToInsert);

    for (final item in itemsData) {
      await supabase.rpc(
        'apply_stock_movement',
        params: {
          'p_movement_id': item['stock_movement_id'],
          'p_shop_id': saleData['shop_id'],
          'p_product_id': item['product_id'],
          'p_quantity_delta': -(item['quantity'] as int),
          'p_type': 'sale',
        },
      );
    }
  }

  void dispose() {
    _statusController.close();
  }
}

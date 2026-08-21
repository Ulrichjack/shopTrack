import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce que la file doit garantir : une opération que le serveur refuse pour
/// toujours ne doit pas geler tout le reste, et une coupure réseau ne doit
/// jamais faire passer du travail valide pour un refus.
///
/// Sans Supabase initialisé, tout envoi échoue par assertion — ce qui est
/// exactement le cas « le serveur refuse ». C'est ce qui rend ces tests
/// déterministes sans réseau.
void main() {
  late AppDatabase db;
  late SyncService sync;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    sync = container.read(syncServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<SyncQueueItem> ligne(String action) async {
    final file = await db.getPendingItems();
    return file.firstWhere((item) => item.action == action);
  }

  test('une opération refusée sans fin finit mise de côté, sans être jetée', () async {
    await db.addToQueue('ADD_PRODUCT', jsonEncode({'id': 'p1'}));

    for (var i = 0; i < SyncService.maxRefusAvantMiseDeCote; i++) {
      await sync.processQueue();
    }

    final item = await ligne('ADD_PRODUCT');
    expect(item.attempts, SyncService.maxRefusAvantMiseDeCote);
    expect(item.setAside, isTrue);
    expect(item.lastError, isNotNull);

    // Mise de côté, pas supprimée : le travail du commerçant reste là, et
    // c'est lui qui décide de réessayer ou d'abandonner.
    expect(await db.getPendingCount(), 1);
    expect(await db.getSetAsideCount(), 1);
  });

  test('une opération mise de côté n’arrête pas ce qui n’a rien à voir', () async {
    await db.addToQueue('ADD_PRODUCT', jsonEncode({'id': 'riz'}));
    for (var i = 0; i < SyncService.maxRefusAvantMiseDeCote; i++) {
      await sync.processQueue();
    }
    expect((await ligne('ADD_PRODUCT')).setAside, isTrue);

    // Un autre produit, aucune dépendance avec le riz.
    await db.addToQueue('ADD_PRODUCT_PRICE', jsonEncode({'product_id': 'sucre'}));
    await sync.processQueue();

    // Il a bien été tenté : c'est ce qui distingue « la file avance » de
    // « la file est gelée derrière le riz ».
    expect((await ligne('ADD_PRODUCT_PRICE')).attempts, 1);
  });

  test('mais elle arrête bien ce qui dépend d’elle', () async {
    await db.addToQueue('ADD_PRODUCT', jsonEncode({'id': 'riz'}));
    for (var i = 0; i < SyncService.maxRefusAvantMiseDeCote; i++) {
      await sync.processQueue();
    }

    // Le stock du riz n'a aucun sens tant que le riz n'existe pas côté
    // serveur : il doit attendre, pas être tenté ni mis de côté à son tour.
    await db.addToQueue(
      'ADD_STOCK',
      jsonEncode({'product_id': 'riz', 'quantity': 10}),
    );
    await sync.processQueue();

    final stock = await ligne('ADD_STOCK');
    expect(stock.attempts, 0);
    expect(stock.setAside, isFalse);
  });

  test('une vente attend le produit qu’elle contient', () async {
    await db.addToQueue('ADD_PRODUCT', jsonEncode({'id': 'riz'}));
    for (var i = 0; i < SyncService.maxRefusAvantMiseDeCote; i++) {
      await sync.processQueue();
    }

    await db.addToQueue(
      'CREATE_SALE',
      jsonEncode({
        'sale': {'id': 'v1', 'shop_id': 'b1'},
        'items': [
          {'product_id': 'riz', 'quantity': 2},
        ],
      }),
    );
    await sync.processQueue();

    expect((await ligne('CREATE_SALE')).attempts, 0);
  });

  test('réessayer remet tout en circuit, compteur à zéro', () async {
    await db.addToQueue('ADD_PRODUCT', jsonEncode({'id': 'p1'}));
    for (var i = 0; i < SyncService.maxRefusAvantMiseDeCote; i++) {
      await sync.processQueue();
    }
    expect(await db.getSetAsideCount(), 1);

    await db.requeueAllSetAside();

    final item = await ligne('ADD_PRODUCT');
    expect(item.setAside, isFalse);
    expect(item.attempts, 0);
    expect(item.lastError, isNull);
  });

  test('abandonner retire l’opération de la file', () async {
    await db.addToQueue('ADD_PRODUCT', jsonEncode({'id': 'p1'}));
    for (var i = 0; i < SyncService.maxRefusAvantMiseDeCote; i++) {
      await sync.processQueue();
    }

    await sync.discardBlocked((await ligne('ADD_PRODUCT')).id);

    expect(await db.getPendingCount(), 0);
    expect(await db.getSetAsideCount(), 0);
  });

  group('un réseau coupé n’est pas un refus', () {
    test('les pannes de transport ne comptent pas', () {
      expect(sync.estUnRefusDuServeur(const SocketException('pas de route')), isFalse);
      expect(sync.estUnRefusDuServeur(TimeoutException('trop long')), isFalse);
      expect(
        sync.estUnRefusDuServeur(const AuthException('jeton expiré')),
        isFalse,
      );
      expect(
        sync.estUnRefusDuServeur(
          Exception('ClientException: Failed host lookup: supabase.co'),
        ),
        isFalse,
      );
    });

    test('une réponse du serveur, si', () {
      expect(
        sync.estUnRefusDuServeur(
          const PostgrestException(message: 'Stock insuffisant'),
        ),
        isTrue,
      );
      expect(sync.estUnRefusDuServeur(StateError('action inconnue')), isTrue);
      expect(sync.estUnRefusDuServeur(const FormatException('charge illisible')), isTrue);
    });
  });

  test('une charge illisible arrête tout : on ignore ce qu’elle touche', () async {
    await db.addToQueue('ADD_PRODUCT', '{ceci n’est pas du json');
    await db.addToQueue('ADD_PRODUCT', jsonEncode({'id': 'p2'}));

    await sync.processQueue();

    final file = await db.getPendingItems();
    expect(file.length, 2);
    // La seconde n'a même pas été tentée : sans savoir ce que porte la
    // première, la laisser passer casserait l'ordre à l'aveugle.
    expect(file[1].attempts, 0);
  });
}

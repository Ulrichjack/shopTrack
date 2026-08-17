import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../sync/sync_service.dart';
import '../../core/providers/current_shop_provider.dart';

/// Réglages d'activation des modules optionnels d'une boutique
/// (voir docs/ARCHITECTURE_MODULES.md). Absence de ligne côté Supabase/local
/// = valeurs par défaut ci-dessous = comportement actuel de l'app, inchangé.
class ShopSettings {
  final String unitMode;
  final String saleCaptureMode;
  final bool multiPointEnabled;

  /// Le mode a-t-il été **lu quelque part**, ou est-ce encore la valeur par
  /// défaut faute de mieux ?
  ///
  /// Sans cette distinction, « je ne sais pas encore » et « mode simple » se
  /// confondaient : l'accueil simple se construisait une seconde, ouvrait la
  /// boîte « fonds de caisse », et celle-ci restait à l'écran par-dessus
  /// l'inventaire. Une boîte de dialogue est une route : elle survit au widget
  /// qui l'a ouverte.
  final bool connu;

  const ShopSettings({
    this.unitMode = 'simple',
    this.saleCaptureMode = 'realtime',
    this.multiPointEnabled = false,
    this.connu = false,
  });
}

final shopSettingsProvider =
    AsyncNotifierProvider<ShopSettingsNotifier, ShopSettings>(() {
      return ShopSettingsNotifier();
    });

class ShopSettingsNotifier extends AsyncNotifier<ShopSettings> {
  @override
  Future<ShopSettings> build() async {
    final db = ref.read(localDbProvider);
    // `watch` : à la reconnexion la boutique n'est connue qu'après le premier
    // échange réseau. En `read`, ce provider concluait « mode simple » avant
    // qu'elle arrive et n'était plus jamais relancé — le commerçant retrouvait
    // le mode simple alors qu'il s'était déconnecté en mode inventaire.
    final shopId = await ref.watch(currentShopIdProvider.future);

    if (shopId == null || shopId.isEmpty) {
      return const ShopSettings();
    }

    // Le cache local D'ABORD, le réseau ensuite. L'ordre inverse faisait
    // attendre Supabase avant de rendre quoi que ce soit : pendant ce temps
    // les écrans se construisaient sur les valeurs par défaut, donc en mode
    // simple, et basculaient en inventaire une seconde plus tard. Le
    // commerçant voyait ses onglets changer sous ses yeux — et pouvait taper
    // au mauvais endroit.
    final local = await _lireLocal(db, shopId);

    // La mise à jour distante ne bloque pas l'affichage : elle arrive quand
    // elle arrive, et ne change l'état que si le serveur dit autre chose.
    // Après une reconnexion la base locale a été vidée : c'est ce rattrapage
    // qui ramène le mode réel de la boutique.
    unawaited(_rafraichirDepuisSupabase(db, shopId));

    return local;
  }

  Future<ShopSettings> _lireLocal(AppDatabase db, String shopId) async {
    final local = await (db.select(
      db.localShopSettings,
    )..where((t) => t.shopId.equals(shopId))).getSingleOrNull();

    if (local == null) return const ShopSettings();

    return ShopSettings(
      unitMode: local.unitMode,
      saleCaptureMode: local.saleCaptureMode,
      multiPointEnabled: local.multiPointEnabled,
      connu: true,
    );
  }

  Future<void> _rafraichirDepuisSupabase(AppDatabase db, String shopId) async {
    await _syncFromSupabase(db, shopId);
    final frais = await _lireLocal(db, shopId);
    final actuel = state.valueOrNull;
    if (actuel == null ||
        frais.unitMode != actuel.unitMode ||
        frais.saleCaptureMode != actuel.saleCaptureMode ||
        frais.multiPointEnabled != actuel.multiPointEnabled) {
      state = AsyncValue.data(frais);
    }
  }

  /// Active/désactive la vente par unités pour cette boutique.
  /// Purement additif : les produits sans unité continuent de se vendre
  /// normalement, et repasser en simple ne détruit aucune donnée.
  Future<void> setUnitMode(bool hierarchical) async {
    final db = ref.read(localDbProvider);
    final shopId = await requireShopId(ref);

    final mode = hierarchical ? 'hierarchical' : 'simple';

    await db
        .into(db.localShopSettings)
        .insertOnConflictUpdate(
          LocalShopSettingsCompanion.insert(
            shopId: shopId,
            unitMode: drift.Value(mode),
          ),
        );

    await db.addToQueue(
      'SET_SHOP_SETTINGS',
      jsonEncode({'shop_id': shopId, 'unit_mode': mode}),
    );
    await ref.read(syncServiceProvider).processQueue();

    ref.invalidateSelf();
    await future;
  }

  /// Bascule entre vente enregistrée au fil de l'eau et inventaire périodique.
  ///
  /// Contrairement au mode unités, ce n'est **pas** une couche qui s'ajoute :
  /// en périodique on ne saisit plus les ventes, on les déduit du comptage.
  /// Mélanger les deux dans une même boutique recompterait les ventes déjà
  /// enregistrées dans l'estimation — d'où un interrupteur exclusif.
  Future<void> setSaleCaptureMode(bool periodic) async {
    final db = ref.read(localDbProvider);
    final shopId = await requireShopId(ref);

    final mode = periodic ? 'periodic' : 'realtime';

    await db
        .into(db.localShopSettings)
        .insertOnConflictUpdate(
          LocalShopSettingsCompanion.insert(
            shopId: shopId,
            saleCaptureMode: drift.Value(mode),
          ),
        );

    await db.addToQueue(
      'SET_SHOP_SETTINGS',
      jsonEncode({'shop_id': shopId, 'sale_capture_mode': mode}),
    );
    await ref.read(syncServiceProvider).processQueue();

    ref.invalidateSelf();
    await future;
  }

  // Comme _runBackgroundSync dans dashboard_provider.dart : hors ligne ou en
  // erreur, on garde silencieusement le cache local existant.
  Future<void> _syncFromSupabase(AppDatabase db, String shopId) async {
    // Même règle que pullDataFromSupabase : tant qu'une écriture locale n'est
    // pas partie, le serveur est périmé et ne doit rien écraser. Sans cette
    // garde, désactiver un module revenait en arrière tout seul — le serveur
    // renvoyait l'ancien réglage parce que le changement était encore en file.
    if (await db.getPendingCount() > 0) return;

    try {
      final response = await Supabase.instance.client
          .from('shop_settings')
          .select()
          .eq('shop_id', shopId)
          .maybeSingle();

      if (response == null) return;

      await db
          .into(db.localShopSettings)
          .insertOnConflictUpdate(
            LocalShopSettingsCompanion.insert(
              shopId: shopId,
              unitMode: drift.Value(response['unit_mode'] as String),
              saleCaptureMode: drift.Value(
                response['sale_capture_mode'] as String,
              ),
              multiPointEnabled: drift.Value(
                response['multi_point_enabled'] as bool,
              ),
            ),
          );
    } catch (_) {
      return;
    }
  }
}

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../sync/sync_service.dart';

/// Réglages d'activation des modules optionnels d'une boutique
/// (voir docs/ARCHITECTURE_MODULES.md). Absence de ligne côté Supabase/local
/// = valeurs par défaut ci-dessous = comportement actuel de l'app, inchangé.
class ShopSettings {
  final String unitMode;
  final String saleCaptureMode;
  final bool multiPointEnabled;

  const ShopSettings({
    this.unitMode = 'simple',
    this.saleCaptureMode = 'realtime',
    this.multiPointEnabled = false,
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
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('cached_shop_id');

    if (shopId == null || shopId.isEmpty) {
      return const ShopSettings();
    }

    await _syncFromSupabase(db, shopId);

    final local = await (db.select(
      db.localShopSettings,
    )..where((t) => t.shopId.equals(shopId))).getSingleOrNull();

    if (local == null) return const ShopSettings();

    return ShopSettings(
      unitMode: local.unitMode,
      saleCaptureMode: local.saleCaptureMode,
      multiPointEnabled: local.multiPointEnabled,
    );
  }

  /// Active/désactive la vente par unités pour cette boutique.
  /// Purement additif : les produits sans unité continuent de se vendre
  /// normalement, et repasser en simple ne détruit aucune donnée.
  Future<void> setUnitMode(bool hierarchical) async {
    final db = ref.read(localDbProvider);
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('cached_shop_id');
    if (shopId == null || shopId.isEmpty) {
      throw Exception('Boutique introuvable.');
    }

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

  // Comme _runBackgroundSync dans dashboard_provider.dart : hors ligne ou en
  // erreur, on garde silencieusement le cache local existant.
  Future<void> _syncFromSupabase(AppDatabase db, String shopId) async {
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Toute table métier stockée en local doit être retéléchargée par
/// `pullDataFromSupabase()`.
///
/// Une table poussée mais jamais tirée ne casse rien de visible : le téléphone
/// qui a écrit la donnée continue de l'afficher correctement. Le trou
/// n'apparaît que sur un second téléphone ou après réinstallation — et il ment
/// au lieu de planter. Vu en vrai sur `stock_movements` : le rapport de période
/// y lit ses recharges, et sans elles il annonçait un bénéfice surévalué.
///
/// Ce test lit le code source plutôt que d'appeler Supabase : il n'a pas besoin
/// de réseau et échoue à l'ajout d'une table, pas des mois plus tard en
/// production.
void main() {
  test('chaque table locale est téléchargée par le pull', () {
    final schema = File('lib/core/database/app_database.dart').readAsStringSync();
    final sync = File('lib/core/sync/sync_service.dart').readAsStringSync();

    // Le corps du pull uniquement : `.from('x')` ailleurs dans le fichier sert
    // à pousser, pas à télécharger.
    final pullStart = sync.indexOf('Future<void> pullDataFromSupabase()');
    expect(pullStart, isNot(-1), reason: 'pullDataFromSupabase() introuvable');
    final pullBody = sync.substring(pullStart, sync.indexOf('} catch', pullStart));

    final pulled = RegExp(r"\.from\('([a-z_]+)'\)")
        .allMatches(pullBody)
        .map((m) => m.group(1)!)
        .toSet();

    // Tables volontairement hors du pull, avec la raison.
    const exceptions = <String, String>{
      'sync_queue_items': 'file d\'attente purement locale, jamais distante',
      'shop_settings':
          'téléchargée par shop_settings_provider, avec la même garde de file',
    };

    final manquantes = <String>[];
    for (final match
        in RegExp(r'class (\w+) extends Table').allMatches(schema)) {
      final remote = _remoteTableName(match.group(1)!);
      if (exceptions.containsKey(remote)) continue;
      if (!pulled.contains(remote)) manquantes.add(remote);
    }

    expect(
      manquantes,
      isEmpty,
      reason:
          'Ces tables sont stockées en local mais jamais retéléchargées : '
          '${manquantes.join(', ')}. Ajoute-les des DEUX côtés de '
          'pullDataFromSupabase() (le select distant ET le mapping vers Drift), '
          'ou documente l\'exception dans ce test.',
    );
  });
}

/// `LocalStockMovements` → `stock_movements`.
String _remoteTableName(String driftClass) {
  final sansPrefixe = driftClass.startsWith('Local')
      ? driftClass.substring(5)
      : driftClass;
  return sansPrefixe
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (m) => '${m.group(1)}_${m.group(2)}',
      )
      .toLowerCase();
}

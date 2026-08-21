import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Toute colonne de `LocalProducts` doit être recopiée dans `ProductEntity`.
///
/// Un champ oublié dans ce mapping ne casse rien de visible : la donnée reste
/// en base, elle disparaît juste de l'app. Puis un écran d'édition pré-remplit
/// son champ avec la valeur manquante — donc vide — et l'enregistrement
/// **efface la donnée** pour de bon. Vu sur `unit` : les produits gardaient
/// « sac » ou « carton » en base, mais modifier un prix suffisait à le perdre.
///
/// Même famille que `sync_pull_coverage_test` : on lit le code source plutôt
/// que d'exécuter l'app, et on échoue à l'ajout d'un champ, pas des mois plus
/// tard en production.
void main() {
  test('chaque colonne produit est recopiée dans l\'entité', () {
    final schema = File(
      'lib/core/database/app_database.dart',
    ).readAsStringSync();
    final provider = File(
      'lib/features/products/presentation/providers/product_provider.dart',
    ).readAsStringSync();

    final debut = schema.indexOf('class LocalProducts extends Table');
    expect(debut, isNot(-1), reason: 'table LocalProducts introuvable');
    final corpsTable = schema.substring(debut, schema.indexOf('}', debut));

    // Les vraies colonnes seulement : `primaryKey` est un getter de Drift,
    // pas une donnée à recopier.
    final colonnes = RegExp(r'(?:Text|Int|Real|DateTime|Bool)Column get (\w+)')
        .allMatches(corpsTable)
        .map((m) => m.group(1)!)
        .toSet();

    final debutMapping = provider.indexOf('ProductEntity _toEntity(');
    expect(debutMapping, isNot(-1), reason: '_toEntity introuvable');
    final corpsMapping = provider.substring(
      debutMapping,
      provider.indexOf(');', debutMapping),
    );

    final manquantes = colonnes
        .where((c) => !RegExp('\\b$c:').hasMatch(corpsMapping))
        .toList();

    expect(
      manquantes,
      isEmpty,
      reason:
          'Ces colonnes existent en base mais ne sont pas recopiées dans '
          'ProductEntity : ${manquantes.join(', ')}. L\'app ne les verra pas, '
          'et tout écran qui pré-remplit un champ avec l\'une d\'elles '
          'l\'effacera à l\'enregistrement.',
    );
  });
}

// `isNotNull` existe des deux côtés : celui de Drift construit du SQL, pas une
// assertion. On garde le matcher de test et on préfixe Drift.
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/pull_registry.dart';

/// Les deux oublis qui ont coûté le plus cher au projet, tenus par un test.
///
/// **Oublier une table** : elle est poussée mais jamais retéléchargée. Rien ne
/// casse sur le téléphone qui a écrit la donnée ; le trou n'apparaît que sur
/// un second téléphone, et il ment au lieu de planter. Vu sur
/// `stock_movements` — le rapport de période y lit ses recharges, et sans
/// elles il annonçait un bénéfice surévalué.
///
/// **Oublier une colonne** : le téléchargement réécrit la ligne locale sans le
/// champ et l'efface quelques secondes après sa création. Vu sur
/// `sale_items.cycle_id` — le rapport du module A retombait à 0 F, invisible
/// sur un seul téléphone.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  // Tables volontairement hors du téléchargement, avec la raison.
  const exceptions = <String, String>{
    'sync_queue_items': 'file d\'attente purement locale, jamais distante',
    'shop_settings':
        'téléchargée par shop_settings_provider, avec la même garde de file',
  };

  test('chaque table locale est déclarée dans le registre', () {
    final declarees = {
      for (final table in tablesTirees) _nomDistant(table.cible(db)),
    };

    final manquantes = <String>[];
    for (final table in db.allTables) {
      final nom = _nomDistant(table);
      if (exceptions.containsKey(nom)) continue;
      if (!declarees.contains(nom)) manquantes.add(nom);
    }

    expect(
      manquantes,
      isEmpty,
      reason:
          'Ces tables sont stockées en local mais jamais retéléchargées : '
          '${manquantes.join(', ')}. Ajoute une entrée dans `tablesTirees` '
          '(lib/core/sync/pull_registry.dart), ou documente l\'exception ici.',
    );
  });

  test('aucune colonne locale n\'est perdue en chemin', () {
    for (final table in tablesTirees) {
      final cible = table.cible(db);
      final colonnes = cible.$columns
          .where((colonne) => !table.colonnesLocales.contains(colonne.name))
          .toList();

      // Une ligne distante qui porte *toutes* les colonnes. Si le mapping en
      // laisse une de côté, elle ressort nulle — exactement ce qui s'est
      // passé en production.
      final ligneDistante = {
        for (final colonne in colonnes) colonne.name: _valeurFactice(colonne),
      };

      final produites = mapperLigne(table, ligneDistante).toColumns(false);

      for (final colonne in colonnes) {
        expect(
          produites.containsKey(colonne.name),
          isTrue,
          reason:
              '${table.nom}.${colonne.name} n\'est jamais recopiée par le '
              'mapping : le téléchargement l\'effacera à chaque passage.',
        );
        final valeur = produites[colonne.name];
        expect(
          valeur is drift.Variable ? valeur.value : valeur,
          isNotNull,
          reason:
              '${table.nom}.${colonne.name} ressort nulle alors que la ligne '
              'distante la portait. Le mapping l\'a oubliée.',
        );
      }
    }
  });

  test('le registre ne déclare pas deux fois la même table', () {
    final noms = tablesTirees.map((table) => table.nom).toList();
    expect(noms.toSet().length, noms.length, reason: 'doublon dans le registre');
  });
}

/// `local_stock_movements` → `stock_movements`.
String _nomDistant(drift.TableInfo<drift.Table, dynamic> table) {
  final nom = table.actualTableName;
  return nom.startsWith('local_') ? nom.substring(6) : nom;
}

Object _valeurFactice(drift.GeneratedColumn<Object> colonne) {
  final type = colonne.type;
  if (type == drift.DriftSqlType.string) return 'x-${colonne.name}';
  if (type == drift.DriftSqlType.int) return 7;
  if (type == drift.DriftSqlType.double) return 3.5;
  if (type == drift.DriftSqlType.bool) return true;
  // Le serveur envoie les dates en texte ISO, jamais en objet.
  if (type == drift.DriftSqlType.dateTime) return '2026-01-02T03:04:05.000Z';
  throw UnsupportedError(
    'Type de colonne non couvert par le test : ${colonne.name} ($type). '
    'Ajoute-le à _valeurFactice.',
  );
}

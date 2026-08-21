import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Personne ne lit `cached_shop_id` en dehors de `current_shop_provider.dart`.
///
/// Vingt lectures manuelles existaient dans dix fichiers. Tant qu'un compte n'a
/// qu'une boutique, ça marche. Dès qu'il en a plusieurs, chaque lecture directe
/// est un endroit qui peut rester sur l'ancienne boutique après un changement —
/// et un vendeur enregistrerait une perte dans la mauvaise épicerie sans que
/// rien ne le signale.
///
/// Ce test échoue à la première nouvelle lecture directe, plutôt que le jour où
/// un patron découvre ses chiffres mélangés.
void main() {
  test('la boutique active a une source unique', () {
    final fautifs = <String>[];

    for (final fichier in Directory('lib').listSync(recursive: true)) {
      if (fichier is! File || !fichier.path.endsWith('.dart')) continue;
      if (fichier.path.endsWith('current_shop_provider.dart')) continue;

      for (final ligne in fichier.readAsLinesSync()) {
        final nue = ligne.trim();
        // Les commentaires ont le droit d'en parler.
        if (nue.startsWith('//') || nue.startsWith('///')) continue;
        if (nue.contains("'cached_shop_id'")) {
          fautifs.add(fichier.path);
          break;
        }
      }
    }

    expect(
      fautifs,
      isEmpty,
      reason:
          'Ces fichiers lisent la boutique dans les préférences au lieu de '
          'passer par currentShopIdProvider : ${fautifs.join(', ')}. '
          'Utilise requireShopId(ref).',
    );
  });
}

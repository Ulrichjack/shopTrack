import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_shops_provider.dart';

/// Clé historique, conservée : elle est déjà écrite sur tous les téléphones
/// installés, la changer perdrait la boutique de chacun à la mise à jour.
const cachedShopIdKey = 'cached_shop_id';

/// La boutique active — **source unique**.
///
/// Dix providers lisaient `cached_shop_id` dans les préférences chacun de leur
/// côté, vingt fois au total. Tant qu'un compte n'a qu'une boutique, ça marche.
/// Dès qu'il en a plusieurs, changer de boutique demanderait de prévenir dix
/// endroits — et il suffirait d'en oublier un pour qu'un écran continue
/// d'écrire dans l'ancienne : un vendeur enregistrerait une perte dans la
/// mauvaise épicerie sans que rien ne le signale.
///
/// Null tant qu'aucune boutique n'est connue (avant la première connexion).
final currentShopIdProvider =
    AsyncNotifierProvider<CurrentShopNotifier, String?>(
      CurrentShopNotifier.new,
    );

class CurrentShopNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(cachedShopIdKey);
    final boutiques = await ref.read(userShopsProvider.future);

    // Hors ligne : on garde ce qu'on avait, faute de pouvoir vérifier.
    if (boutiques.isEmpty) {
      return (id == null || id.isEmpty) ? null : id;
    }

    // La boutique mémorisée appartient-elle vraiment à ce compte ?
    //
    // Un vendeur qui se connecte sur un téléphone déjà utilisé par son patron
    // héritait de la boutique active de celui-ci. Elle n'était pas dans SA
    // liste, donc son rôle restait introuvable — et l'app, faute de savoir,
    // lui ouvrait tout. Vider les préférences ne suffisait pas : ce nettoyage
    // ne se déclenche qu'au changement de compte, et le même vendeur qui se
    // reconnecte n'y passe jamais.
    if (id != null && boutiques.any((boutique) => boutique.id == id)) {
      return id;
    }

    // Sinon on ouvre sa boutique par défaut. Le tableau de bord s'en chargeait
    // autrefois, mais le routeur attend désormais de connaître la boutique
    // avant de construire quoi que ce soit : il ne se construisait donc jamais
    // et l'app tournait en rond à la connexion.
    final defaut = boutiqueParDefaut(boutiques);
    if (defaut == null) return null;

    await prefs.setString(cachedShopIdKey, defaut.id);
    await prefs.setString('cached_shop_name', defaut.name);
    return defaut.id;
  }

  /// Change la boutique active et le retient pour les prochains démarrages.
  ///
  /// Les données ne sont pas rechargées ici : c'est l'appelant qui décide quoi
  /// invalider, parce que lui seul sait ce qui est affiché à l'écran.
  Future<void> select(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cachedShopIdKey, shopId);
    state = AsyncValue.data(shopId);
  }
}

/// La boutique active, **observée** : à utiliser dans le corps d'un provider.
///
/// `watch` et non `read`, sinon le provider ne se reconstruit jamais quand la
/// boutique change. Deux cas réels : à la reconnexion, la boutique n'est connue
/// qu'après le premier échange réseau — un provider qui l'a lue trop tôt reste
/// bloqué sur « aucune boutique » ; et au changement de boutique, il continue
/// d'afficher l'ancienne.
Future<String> watchShopId(Ref ref) async {
  final shopId = await ref.watch(currentShopIdProvider.future);
  if (shopId == null || shopId.isEmpty) {
    throw Exception('Boutique introuvable.');
  }
  return shopId;
}

/// La boutique active à l'instant présent : à utiliser dans une **action**
/// (méthode de notifier), où `watch` est interdit hors du build.
Future<String> requireShopId(Ref ref) async {
  final shopId = await ref.read(currentShopIdProvider.future);
  if (shopId == null || shopId.isEmpty) {
    throw Exception('Boutique introuvable.');
  }
  return shopId;
}

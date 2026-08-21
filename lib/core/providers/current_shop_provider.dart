import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sync/revision_donnees.dart';
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
  /// Faux dès que le provider est jeté : la vérification de fond ne doit plus
  /// toucher `state` après, Riverpod lève sinon.
  bool _vivant = true;

  @override
  Future<String?> build() async {
    _vivant = true;
    ref.onDispose(() => _vivant = false);

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(cachedShopIdKey);

    // Une boutique déjà mémorisée s'affiche TOUT DE SUITE.
    //
    // Avant, cette méthode attendait la liste des boutiques du serveur avant
    // de rendre quoi que ce soit — et tout l'accueil attend cette valeur.
    // Chaque démarrage payait donc un aller-retour réseau devant un rond qui
    // tourne, plusieurs secondes sur une connexion ordinaire, et l'éternité
    // hors couverture le temps que la requête abandonne.
    //
    // Le sauter ne montre pas la boutique d'autrui : au changement de compte,
    // la connexion efface `cached_shop_id` (voir `_nettoyerSiAutreCompte`).
    // Ce qui reste ici a donc été écrit pour le compte connecté. Le seul cas
    // restant — un vendeur retiré de la boutique depuis sa dernière session —
    // est rattrapé par la vérification de fond, en une seconde et sans
    // bloquer l'affichage.
    if (id != null && id.isNotEmpty) {
      unawaited(_verifierEnFond(id, prefs));
      return id;
    }

    // Aucune boutique mémorisée : première connexion sur ce téléphone. Là, il
    // n'y a rien à afficher tant que le serveur n'a pas répondu.
    return _choisirParDefaut(prefs);
  }

  /// La boutique mémorisée appartient-elle vraiment à ce compte ?
  ///
  /// Un vendeur qui se connecte sur un téléphone déjà utilisé par son patron
  /// héritait de la boutique active de celui-ci. Elle n'était pas dans SA
  /// liste, donc son rôle restait introuvable — et l'app, faute de savoir,
  /// lui ouvrait tout.
  Future<void> _verifierEnFond(String id, SharedPreferences prefs) async {
    final boutiques = await ref.read(userShopsProvider.future);

    // Hors ligne : on garde ce qu'on avait, faute de pouvoir vérifier.
    if (boutiques.isEmpty) return;
    if (boutiques.any((boutique) => boutique.id == id)) return;

    final remplacante = await _choisirParDefaut(prefs);
    if (!_vivant || remplacante == null) return;
    state = AsyncValue.data(remplacante);
  }

  /// La boutique la plus ancienne du compte, mémorisée pour la prochaine fois.
  ///
  /// Le tableau de bord s'en chargeait autrefois, mais le routeur attend
  /// désormais de connaître la boutique avant de construire quoi que ce soit :
  /// il ne se construisait donc jamais et l'app tournait en rond.
  Future<String?> _choisirParDefaut(SharedPreferences prefs) async {
    final boutiques = await ref.read(userShopsProvider.future);
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
  // Se relire quand un téléchargement a réécrit la base locale. C'est le seul
  // passage commun à toutes les lectures liées à une boutique — produits,
  // comptages, recettes, pertes, transferts — donc le seul endroit où poser
  // cette surveillance une fois pour toutes.
  ref.watch(revisionDonneesLocalesProvider);
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

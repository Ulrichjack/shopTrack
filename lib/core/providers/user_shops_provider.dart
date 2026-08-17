import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shop_settings_provider.dart';

/// Une boutique à laquelle le compte connecté a accès.
class UserShop {
  const UserShop({
    required this.id,
    required this.name,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String name;

  /// Date de création de la boutique. Sert à retrouver la boutique d'origine
  /// du commerçant, pas à l'afficher.
  final DateTime? createdAt;

  /// `owner` ou `seller`, tel que stocké dans `shop_members`.
  final String role;

  bool get isOwner => role == 'owner';
}

/// La boutique à ouvrir quand aucune n'a encore été choisie.
///
/// La **plus ancienne**, pas la première par ordre alphabétique : c'est celle
/// que le commerçant a créée en s'inscrivant, celle où vivent ses données.
/// Trier par nom faisait atterrir sur « Boutique 2 » plutôt que sur son
/// épicerie principale, simplement parce que B vient avant m.
UserShop? boutiqueParDefaut(List<UserShop> boutiques) {
  if (boutiques.isEmpty) return null;
  final triees = [...boutiques]
    ..sort((a, b) {
      final da = a.createdAt;
      final db = b.createdAt;
      if (da == null || db == null) return 0;
      return da.compareTo(db);
    });
  return triees.first;
}

/// Les boutiques du compte connecté.
///
/// Remplace les `.from('shop_members')...single()` disséminés dans quatre
/// fichiers : chacun supposait **une seule** boutique par compte et levait une
/// exception dès la deuxième. Le client type en a trois.
///
/// Renvoie une liste vide hors ligne ou en erreur : l'app garde alors la
/// boutique déjà mémorisée localement, elle ne doit pas s'arrêter parce que le
/// réseau manque.
final userShopsProvider = FutureProvider<List<UserShop>>((ref) async {
  // L'accès à `Supabase.instance` est DANS le try : il lève une assertion tant
  // que l'initialisation n'a pas eu lieu, et ce provider est désormais lu très
  // tôt — au démarrage, et dans les tests où Supabase n'existe pas.
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const [];

    final reponse = await Supabase.instance.client
        .from('shop_members')
        .select('shop_id, role, shops(name, created_at)')
        .eq('user_id', userId);

    // Trace de diagnostic : le nom et le rôle remontent-ils réellement du
    // serveur ? « Ma boutique » et « vendeur » sont des valeurs de repli, on
    // ne peut pas distinguer « absent » de « mal lu » sans voir la réponse.
    debugPrint('[SHOPS] réponse brute : $reponse');

    return (reponse as List)
        .map((ligne) {
          final shop = ligne['shops'] as Map<String, dynamic>?;
          final creation = shop?['created_at'] as String?;
          return UserShop(
            id: ligne['shop_id'] as String,
            name: (shop?['name'] as String?) ?? 'Ma boutique',
            role: (ligne['role'] as String?) ?? 'seller',
            createdAt: creation == null ? null : DateTime.parse(creation),
          );
        })
        .toList()
      // Ordre stable : le sélecteur ne doit pas changer d'ordre à chaque
      // chargement, sinon on tape sur la mauvaise boutique par habitude.
      ..sort((a, b) => a.name.compareTo(b.name));
  } catch (erreur) {
    debugPrint('[SHOPS] échec de la lecture des boutiques : $erreur');
    return const [];
  }
});

final shopCreationProvider = Provider((ref) => ShopCreation(ref));

class ShopCreation {
  ShopCreation(this.ref);

  final Ref ref;

  /// Crée une boutique de plus pour le compte connecté.
  ///
  /// Jusqu'ici seule l'inscription créait une boutique : un patron qui en
  /// ouvrait une deuxième n'avait aucun moyen de la déclarer, et le sélecteur
  /// n'avait rien à proposer.
  ///
  /// Réservé au propriétaire : `shops.owner_id` porte l'utilisateur courant,
  /// et la ligne `shop_members` lui donne le rôle `owner`. Un vendeur ne
  /// pourrait de toute façon pas atteindre cet écran.
  Future<String> creer(String nom) async {
    final nomPropre = nom.trim();
    if (nomPropre.isEmpty) {
      throw ArgumentError('Donne un nom à la boutique.');
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Connecte-toi pour créer une boutique.');
    }

    // Création en ligne uniquement : une boutique n'existe que si le serveur
    // lui a donné un identifiant. En créer une hors ligne obligerait à gérer
    // des collisions d'identifiants entre appareils, pour un geste qui arrive
    // une ou deux fois dans la vie d'un commerce.
    final boutique = await Supabase.instance.client
        .from('shops')
        .insert({'owner_id': userId, 'name': nomPropre})
        .select()
        .single();

    final shopId = boutique['id'] as String;
    await Supabase.instance.client.from('shop_members').insert({
      'shop_id': shopId,
      'user_id': userId,
      'role': 'owner',
    });

    // La nouvelle boutique hérite du mode de celle où l'on se trouve : un
    // patron qui ouvre sa troisième épicerie la gère comme les deux autres.
    // Sans ça elle démarrait en mode simple et il fallait aller le corriger
    // dans les réglages sans savoir pourquoi.
    final reglages = ref.read(shopSettingsProvider).value;
    if (reglages != null) {
      await Supabase.instance.client.from('shop_settings').upsert({
        'shop_id': shopId,
        'unit_mode': reglages.unitMode,
        'sale_capture_mode': reglages.saleCaptureMode,
        'multi_point_enabled': reglages.multiPointEnabled,
      });
    }

    ref.invalidate(userShopsProvider);
    return shopId;
  }
}

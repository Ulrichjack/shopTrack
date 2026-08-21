import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'current_shop_provider.dart';
import 'user_shops_provider.dart';

/// Un compte rattaché à la boutique active.
class ShopMember {
  const ShopMember({required this.userId, required this.role});

  final String userId;
  final String role;

  bool get isOwner => role == 'owner';
}

/// Marqueur posé sur le compte d'un employé tant qu'il n'a pas choisi son
/// propre mot de passe. Vit dans les métadonnées de l'utilisateur : lui seul
/// peut l'effacer, en changeant son mot de passe.
const mustChangePasswordKey = 'must_change_password';

final shopMembersProvider = FutureProvider<List<ShopMember>>((ref) async {
  final shopId = await watchShopId(ref);
  try {
    final reponse = await Supabase.instance.client
        .from('shop_members')
        .select('user_id, role')
        .eq('shop_id', shopId);

    return (reponse as List)
        .map(
          (ligne) => ShopMember(
            userId: ligne['user_id'] as String,
            role: (ligne['role'] as String?) ?? 'seller',
          ),
        )
        .toList();
  } catch (_) {
    return const [];
  }
});

/// Mémorise le rôle pour les démarrages hors ligne. Sans ce cache, un patron
/// sans réseau serait rétrogradé en vendeur au lancement.
const _cleEstProprietaire = 'cached_is_owner';

/// Le compte connecté est-il propriétaire de la boutique active ?
///
/// C'est **le serveur** qui tranche, plus le PIN de l'appareil : un vendeur
/// qui apprend le PIN du patron ne doit pas pouvoir ouvrir le bilan.
///
/// L'ordre des replis compte : la réponse du serveur d'abord, le dernier rôle
/// connu ensuite, et seulement à défaut de tout le comportement historique.
/// Répondre « oui » trop vite donnait le mode Patron à un vendeur qui vient
/// d'installer l'app — son téléphone n'a aucun PIN, et sans PIN l'app
/// concluait « patron ».
final estProprietaireProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final active = await ref.watch(currentShopIdProvider.future);
  final boutiques = await ref.watch(userShopsProvider.future);

  if (boutiques.isNotEmpty && active != null) {
    final courante = boutiques.where((b) => b.id == active).firstOrNull;
    if (courante != null) {
      await prefs.setBool(_cleEstProprietaire, courante.isOwner);
      // Le nom est rafraîchi ICI, à chaque lecture des boutiques. Il n'était
      // écrit qu'au moment de choisir une boutique : une valeur de repli
      // enregistrée une fois — « Ma boutique », quand la liste n'était pas
      // encore arrivée — restait affichée pour toujours.
      await prefs.setString('cached_shop_name', courante.name);
      debugPrint('[ROLE] boutique ${courante.name} — rôle ${courante.role}');
      return courante.isOwner;
    }
    // La boutique active n'est pas dans la liste : incohérence, pas une
    // rétrogradation. Rétrograder ici enfermerait le patron en mode vendeur
    // sur sa propre boutique.
    debugPrint('[ROLE] boutique active $active absente de la liste');
  }

  return prefs.getBool(_cleEstProprietaire) ?? true;
});

final employeeCreationProvider = Provider((ref) => EmployeeCreation(ref));

class EmployeeCreation {
  EmployeeCreation(this.ref);

  final Ref ref;

  /// Crée un compte vendeur rattaché à la boutique active.
  ///
  /// Aujourd'hui patron et vendeur partagent le compte de la boutique : le
  /// vendeur en connaît le mot de passe et repart avec l'accès à toutes les
  /// boutiques du patron. Un compte par employé borne les dégâts à une seule
  /// boutique, et le retirer devient : supprimer sa ligne.
  ///
  /// Le mot de passe saisi ici est **provisoire** : l'employé doit en choisir
  /// un autre à sa première connexion, et le patron ne le connaît plus.
  Future<String> creerVendeur({
    required String telephone,
    required String motDePasseProvisoire,
  }) async {
    final numero = telephone.replaceAll(' ', '').trim();
    if (numero.isEmpty) throw Exception('Saisis le numéro de l\'employé.');
    if (motDePasseProvisoire.trim().length < 6) {
      throw Exception('Le mot de passe doit faire au moins 6 caractères.');
    }

    final shopId = await requireShopId(ref);

    // Tout se passe côté serveur, dans la fonction `creer-vendeur`.
    //
    // Créer un compte demande la clé d'administration, qui n'a rien à faire
    // dans un téléphone : quelqu'un qui décompilerait l'APK pourrait supprimer
    // n'importe quel compte. Et depuis l'app, la création réussissait puis le
    // rattachement échouait — trois comptes orphelins en une matinée de test.
    // Le serveur fait les deux ou aucun.
    final reponse = await Supabase.instance.client.functions.invoke(
      'creer-vendeur',
      body: {
        'telephone': numero,
        'motDePasse': motDePasseProvisoire.trim(),
        'shopId': shopId,
      },
    );

    final corps = reponse.data;
    if (corps is Map && corps['erreur'] != null) {
      throw Exception('${corps['erreur']}');
    }
    if (corps is! Map || corps['rattache'] != true) {
      throw Exception('Vendeur non créé. Vérifie ta connexion.');
    }

    ref.invalidate(shopMembersProvider);
    ref.invalidate(userShopsProvider);

    return corps['compteExistant'] == true
        ? 'Ce compte existait déjà : il est maintenant rattaché à cette '
              'boutique. Il garde son mot de passe habituel.'
        : 'Vendeur créé. Il se connecte avec $numero et le mot de passe '
              'provisoire.';
  }

  /// Retire un employé de la boutique.
  ///
  /// On supprime le rattachement, pas le compte : l'employé peut travailler
  /// dans une autre boutique du patron, et un compte supprimé emporterait
  /// l'historique de qui a fait quoi.
  Future<void> retirer(String userId) async {
    final shopId = await requireShopId(ref);
    await Supabase.instance.client
        .from('shop_members')
        .delete()
        .eq('shop_id', shopId)
        .eq('user_id', userId);
    ref.invalidate(shopMembersProvider);
  }
}

/// Vrai tant que l'employé utilise le mot de passe donné par son patron.
bool doitChangerMotDePasse() {
  final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
  return metadata?[mustChangePasswordKey] == true;
}

/// L'employé choisit son mot de passe : le patron ne le connaît plus.
///
/// [actuel] est vérifié avant tout changement. Supabase ne le réclame pas —
/// une session ouverte suffit à sa `updateUser` — mais un téléphone posé sur
/// un comptoir reste une session ouverte : sans cette vérification, n'importe
/// qui pouvait changer le mot de passe et enfermer dehors le propriétaire du
/// compte. On revalide en se reconnectant avec l'ancien.
Future<void> changerMotDePasse({
  required String actuel,
  required String nouveau,
}) async {
  if (nouveau.trim().length < 6) {
    throw ArgumentError('Le mot de passe doit faire au moins 6 caractères.');
  }
  if (actuel.trim() == nouveau.trim()) {
    throw ArgumentError('Le nouveau mot de passe doit être différent.');
  }

  final client = Supabase.instance.client;
  final email = client.auth.currentUser?.email;
  if (email == null) {
    throw StateError('Aucune session ouverte.');
  }

  try {
    await client.auth.signInWithPassword(
      email: email,
      password: actuel.trim(),
    );
  } on AuthException {
    throw ArgumentError('Mot de passe actuel incorrect.');
  }

  await client.auth.updateUser(
    UserAttributes(
      password: nouveau.trim(),
      data: const {mustChangePasswordKey: false},
    ),
  );
}

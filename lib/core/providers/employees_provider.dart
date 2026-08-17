import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase_config.dart';
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

/// Vrai si le compte connecté est propriétaire de la boutique active.
///
/// C'est **le serveur** qui tranche, plus le PIN de l'appareil : un vendeur
/// qui apprend le PIN du patron ne doit pas pouvoir ouvrir le bilan.
final isOwnerOfCurrentShopProvider = Provider<bool>((ref) {
  final boutiques = ref.watch(userShopsProvider).value ?? const <UserShop>[];
  final active = ref.watch(currentShopIdProvider).value;
  if (boutiques.isEmpty || active == null) {
    // Rien de connu : on garde le comportement historique, où le PIN décide.
    // Refuser ici bloquerait le patron hors ligne.
    return true;
  }
  final courante = boutiques.where((b) => b.id == active).firstOrNull;
  return courante?.isOwner ?? true;
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
  Future<void> creerVendeur({
    required String telephone,
    required String motDePasseProvisoire,
  }) async {
    final numero = telephone.replaceAll(' ', '').trim();
    if (numero.isEmpty) throw ArgumentError('Saisis le numéro de l\'employé.');
    if (motDePasseProvisoire.trim().length < 6) {
      throw ArgumentError('Le mot de passe doit faire au moins 6 caractères.');
    }

    final shopId = await requireShopId(ref);

    // Client séparé, exprès : `Supabase.instance` remplacerait la session en
    // cours par celle du compte créé — le patron serait déconnecté et se
    // retrouverait dans l'app de son propre vendeur.
    final clientTemporaire = SupabaseClient(supabaseUrl, supabaseAnonKey);
    try {
      final creation = await clientTemporaire.auth.signUp(
        email: '$numero@shoptrack.cm',
        password: motDePasseProvisoire.trim(),
        data: const {mustChangePasswordKey: true},
      );

      final nouvelId = creation.user?.id;
      if (nouvelId == null) {
        throw Exception('Compte non créé. Vérifie ta connexion.');
      }

      // Le rattachement passe par la session du PATRON : la policy exige
      // d'être membre de la boutique, ce que le compte tout juste créé n'est
      // pas encore.
      await Supabase.instance.client.from('shop_members').insert({
        'shop_id': shopId,
        'user_id': nouvelId,
        'role': 'seller',
      });

      ref.invalidate(shopMembersProvider);
      ref.invalidate(userShopsProvider);
    } finally {
      await clientTemporaire.dispose();
    }
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
Future<void> changerMotDePasse(String nouveau) async {
  if (nouveau.trim().length < 6) {
    throw ArgumentError('Le mot de passe doit faire au moins 6 caractères.');
  }
  await Supabase.instance.client.auth.updateUser(
    UserAttributes(
      password: nouveau.trim(),
      data: const {mustChangePasswordKey: false},
    ),
  );
}

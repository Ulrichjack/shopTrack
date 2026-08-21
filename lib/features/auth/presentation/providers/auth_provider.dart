

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/auth_error_message.dart';

class AuthNotifier extends Notifier<bool> {


  @override
  bool build() {
    return false;
  }

  Future<void> login(String phone, String password) async {
    state = true;
    try{

      final cleanPhone = phone.replaceAll(' ', '');
      final fakeEmail = '$cleanPhone@shoptrack.cm';

      // `trim()` comme partout ailleurs : la création d'un vendeur et le
      // changement de mot de passe nettoient déjà. Sans lui ici, un clavier
      // qui ajoute une espace après le mot — celui de Samsung le fait —
      // envoyait « 123456 » pour un compte enregistré avec « 123456 », et le
      // serveur refusait un mot de passe pourtant juste.
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: fakeEmail,
        password: password.trim(),
      );

      if(response.user != null){
        state = false;
      }
    } catch (e){
      state = false;
      // Le motif exact remonte à l'écran. Auparavant tout devenait « Erreur de
      // connexion » : le commerçant ne savait pas s'il avait tapé le mauvais
      // numéro, le mauvais mot de passe, ou s'il manquait simplement de réseau.
      debugPrint('[AUTH] échec de la connexion : $e');
      throw Exception(messageDErreurAuth(e));
    }
  }

  Future<void> register(String phone, String password, String shopName) async {
    state = true;
    try {
      final cleanPhone = phone.replaceAll(' ', '');
      final fakeEmail = '$cleanPhone@shoptrack.cm';

      // 1. Création de l'utilisateur dans Supabase Auth
      // Nettoyé à l'inscription aussi : un mot de passe enregistré avec une
      // espace finale ne serait plus jamais retapé à l'identique.
      final response = await Supabase.instance.client.auth.signUp(
        email: fakeEmail,
        password: password.trim(),
      );

      final userId = response.user?.id;
      if (userId != null) {

        // 2. Création de la boutique dans la table 'shops'
        // On utilise .select().single() pour récupérer l'ID de la boutique fraîchement créée
        final shopResponse = await Supabase.instance.client.from('shops').insert({
          'owner_id': userId,
          'name': shopName,
        }).select().single();

        final shopId = shopResponse['id'];

        // 3. Liaison de l'utilisateur à sa boutique en tant que 'owner'
        await Supabase.instance.client.from('shop_members').insert({
          'shop_id': shopId,
          'user_id': userId,
          'role': 'owner',
        });

        state = false;
      }
    } catch (e) {
      state = false;
      debugPrint('[AUTH] échec de l\'inscription : $e');
      throw Exception(messageDErreurAuth(e));
    }
  }

}





final authProvider = NotifierProvider<AuthNotifier, bool>((){
  return AuthNotifier();
});


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: fakeEmail,
        password: password,
      );

      if(response.user != null){
        state = false;
      }
    } on AuthException catch (e){
      state = false;
      print('Erreur supabase: ${e.message}');
      throw Exception('Erreur de connexion');
    } catch (e){
      state = false;
      print('Erreur inattendue: $e');
      throw Exception('Erreur réseau');
    }
  }

  Future<void> register(String phone, String password, String shopName) async {
    state = true;
    try {
      final cleanPhone = phone.replaceAll(' ', '');
      final fakeEmail = '$cleanPhone@shoptrack.cm';

      // 1. Création de l'utilisateur dans Supabase Auth
      final response = await Supabase.instance.client.auth.signUp(
        email: fakeEmail,
        password: password,
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
    } on AuthException catch (e) {
      state = false;
      print('Erreur Auth: ${e.message}');
      throw Exception('Erreur lors de la création du compte');
    } catch (e) {
      state = false;
      print('Erreur inattendue: $e');
      throw Exception('Erreur réseau ou base de données');
    }
  }

}





final authProvider = NotifierProvider<AuthNotifier, bool>((){
  return AuthNotifier();
});
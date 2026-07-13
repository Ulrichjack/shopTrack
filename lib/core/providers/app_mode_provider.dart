import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Clé utilisée dans SharedPreferences
const String kBossPinKey = 'boss_pin';

class AppModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(kBossPinKey);

    // Initialisation au démarrage de l'application :
    // S'il n'y a pas de PIN configuré du tout -> Le patron n'a pas encore setup la sécurité -> true (Boss Mode)
    // S'il y a un PIN configuré -> Par sécurité, on démarre toujours en mode Vendeur -> false (Vendor Mode)
    if (pin == null) {
      return true;
    } else {
      return false;
    }
  }

  /// Vérifie si un PIN existe dans la mémoire locale
  Future<bool> hasPinConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kBossPinKey) != null;
  }

  /// Le Patron crée son code PIN pour la première fois
  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBossPinKey, pin);

    // Une fois le PIN créé, on bascule en mode Vendeur pour que la protection soit active
    state = const AsyncValue.data(false);
  }

  /// Le Patron supprime son code PIN (Désactive la protection)
  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kBossPinKey);

    // Sans PIN, tout est déverrouillé
    state = const AsyncValue.data(true);
  }

  /// Tente de déverrouiller le mode Patron (Saisie du code par l'utilisateur)
  Future<bool> unlockBossMode(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(kBossPinKey);

    if (savedPin == enteredPin) {
      state = const AsyncValue.data(true); // Succès : Accès total accordé
      return true;
    }
    return false; // Échec : Mauvais code
  }

  /// Le Patron verrouille manuellement l'application avant de donner le tel au vendeur
  void lockApp() {
    state = const AsyncValue.data(false);
  }
}

// Le Provider que l'on va écouter partout dans l'UI
final appModeProvider = AsyncNotifierProvider<AppModeNotifier, bool>(() {
  return AppModeNotifier();
});
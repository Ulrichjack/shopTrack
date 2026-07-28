import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBossPinKey = 'boss_pin'; // Ancienne clé, utilisée pour migration.
const String kBossPinHashKey = 'boss_pin_hash';
const String kBossPinSaltKey = 'boss_pin_salt';
const String kBossModeActiveKey = 'boss_mode_active';

/// Utilisé par le routeur pour interdire l'accès direct aux écrans Patron.
final bossModeAccess = ValueNotifier<bool>(false);

class AppModeNotifier extends AsyncNotifier<bool> {
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPin =
        prefs.containsKey(kBossPinHashKey) || prefs.containsKey(kBossPinKey);
    final isBoss = !hasPin || (prefs.getBool(kBossModeActiveKey) ?? false);
    bossModeAccess.value = isBoss;
    return isBoss;
  }

  Future<bool> hasPinConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(kBossPinHashKey) || prefs.containsKey(kBossPinKey);
  }

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError('Le PIN doit contenir exactement 4 chiffres.');
    }

    final prefs = await SharedPreferences.getInstance();
    final random = Random.secure();
    final saltBytes = List<int>.generate(24, (_) => random.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    await prefs.setString(kBossPinSaltKey, salt);
    await prefs.setString(kBossPinHashKey, _hash(pin, salt));
    await prefs.remove(kBossPinKey);
    await prefs.setBool(kBossModeActiveKey, false);

    bossModeAccess.value = false;
    state = const AsyncValue.data(false);
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kBossPinKey);
    await prefs.remove(kBossPinHashKey);
    await prefs.remove(kBossPinSaltKey);
    await prefs.remove(kBossModeActiveKey);
    bossModeAccess.value = true;
    state = const AsyncValue.data(true);
  }

  Future<bool> unlockBossMode(String enteredPin) async {
    final now = DateTime.now();
    if (_lockedUntil?.isAfter(now) ?? false) return false;

    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(kBossPinHashKey);
    final salt = prefs.getString(kBossPinSaltKey);
    bool matches =
        savedHash != null &&
        salt != null &&
        _constantTimeEquals(savedHash, _hash(enteredPin, salt));

    // Migration transparente de l'ancien PIN enregistré en clair.
    final legacyPin = prefs.getString(kBossPinKey);
    if (!matches && legacyPin != null && legacyPin == enteredPin) {
      await setPin(enteredPin);
      matches = true;
    }

    if (matches) {
      _failedAttempts = 0;
      _lockedUntil = null;
      await prefs.setBool(kBossModeActiveKey, true);
      bossModeAccess.value = true;
      state = const AsyncValue.data(true);
      return true;
    }

    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _failedAttempts = 0;
      _lockedUntil = now.add(const Duration(seconds: 30));
    }
    return false;
  }

  Future<void> lockApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kBossModeActiveKey, false);
    bossModeAccess.value = false;
    state = const AsyncValue.data(false);
  }

  String _hash(String pin, String salt) {
    List<int> bytes = utf8.encode('$salt:$pin');
    // Ralentit les essais automatisés tout en restant acceptable pour 4 chiffres.
    for (var i = 0; i < 10000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64UrlEncode(bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}

final appModeProvider = AsyncNotifierProvider<AppModeNotifier, bool>(() {
  return AppModeNotifier();
});

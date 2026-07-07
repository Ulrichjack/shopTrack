

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends Notifier<bool> {


  @override
  bool build() {
    return false;
  }

  Future<void> login(String phone, String password) async {
    state = true;
    await Future.delayed(const Duration(seconds: 2));
    state = false;
  }

}

final authProvider = NotifierProvider<AuthNotifier, bool>((){
  return AuthNotifier();
});
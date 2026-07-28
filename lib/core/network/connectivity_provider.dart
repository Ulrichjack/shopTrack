import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_service.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  final initialResult = await connectivity.checkConnectivity();
  bool isOnline = !initialResult.contains(ConnectivityResult.none);

  // 👇 NOUVEAU : Au démarrage, si on a internet, on lance le Grand Téléchargement !
  if (isOnline) {
    await ref.read(syncServiceProvider).synchronize();
  }

  yield isOnline;

  await for (final result in connectivity.onConnectivityChanged) {
    final currentlyOnline = !result.contains(ConnectivityResult.none);

    if (currentlyOnline) {
      print('🌐 Internet est de retour !');
      // 👇 NOUVEAU : Quand internet revient, on envoie la salle d'attente ET on met à jour le téléphone
      final syncService = ref.read(syncServiceProvider);
      await syncService.synchronize();
    }

    yield currentlyOnline;
  }
});

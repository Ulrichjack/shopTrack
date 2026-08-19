import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Ajoute cet import
import 'package:shoptrack/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shoptrack/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/connectivity_provider.dart';
import 'core/sync/sync_service.dart';

void main() async {
  // Obligatoire quand on fait de l'async avant runApp
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);

  // Initialisation de Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: ShopTrackApp()));
}

class ShopTrackApp extends ConsumerStatefulWidget {
  const ShopTrackApp({super.key});

  @override
  ConsumerState<ShopTrackApp> createState() => _ShopTrackAppState();
}

/// `WidgetsBindingObserver` pour retélécharger au retour au premier plan.
///
/// `connectivityProvider` ne relance un téléchargement qu'au tout premier
/// démarrage du processus et sur un vrai CHANGEMENT d'état réseau. Un
/// commerçant qui verrouille son téléphone puis le déverrouille des heures
/// plus tard — le geste le plus courant de sa journée — ne déclenche ni l'un
/// ni l'autre : le processus n'a jamais été tué, le réseau n'a jamais varié.
/// Il retrouve alors les données de la veille, y compris pour un transfert
/// que l'autre boutique vient d'envoyer. Constaté le 19/08/2026 : un vendeur
/// reconnecté depuis le matin ne voyait pas un transfert reçu la veille au
/// soir, faute d'avoir jamais retéléchargé depuis.
class _ShopTrackAppState extends ConsumerState<ShopTrackApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    // Best-effort : hors ligne au moment du retour, `connectivityProvider`
    // rattrapera au vrai retour du réseau. Bloquer l'affichage serait pire
    // qu'une donnée d'une minute de retard.
    unawaited(ref.read(syncServiceProvider).synchronize().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(connectivityProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
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
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

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
  /// Rafraîchissement de fond pendant que l'app est ouverte.
  ///
  /// La synchro n'était déclenchée que par un ÉVÉNEMENT : reprise de l'app,
  /// retour du réseau, connexion, changement de boutique. Un deuxième
  /// téléphone posé sur le comptoir, écran allumé sur le stock, ne recevait
  /// donc jamais rien — le patron ajoutait un produit, le vendeur ne le voyait
  /// pas tant qu'il ne quittait pas l'app.
  ///
  /// Deux minutes : assez court pour qu'une boutique à deux téléphones se
  /// tienne, assez long pour ne pas manger le forfait. Sans coût d'affichage —
  /// `pullDataFromSupabase` ne réveille les écrans que si le serveur a
  /// réellement renvoyé autre chose (cf. `_empreinteDernierPull`).
  static const _intervalleRafraichissement = Duration(minutes: 2);
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _minuteur = Timer.periodic(
      _intervalleRafraichissement,
      (_) => _synchroniserSansBloquer(),
    );
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _synchroniserSansBloquer() {
    if (Supabase.instance.client.auth.currentSession == null) return;
    // Best-effort : hors ligne, `connectivityProvider` rattrapera au vrai
    // retour du réseau.
    unawaited(ref.read(syncServiceProvider).synchronize().catchError((_) {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Bloquer l'affichage serait pire qu'une donnée d'une minute de retard.
    _synchroniserSansBloquer();
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

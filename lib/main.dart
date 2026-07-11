import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Ajoute cet import
import 'package:shoptrack/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shoptrack/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/connectivity_provider.dart';

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

class ShopTrackApp extends ConsumerWidget {
  const ShopTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivityProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
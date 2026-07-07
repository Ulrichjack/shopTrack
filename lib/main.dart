import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Ajoute cet import
import 'package:shoptrack/features/auth/presentation/screens/login_screen.dart';
import 'package:shoptrack/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shoptrack/supabase_config.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Obligatoire quand on fait de l'async avant runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: ShopTrackApp()));
}

class ShopTrackApp extends StatelessWidget {
  const ShopTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_environment.dart';
import 'web_app.dart';

/// Première entrée web : staging uniquement, sans base locale Android.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  final backend = SupabaseEnvironment.resolve(
    flavor: null,
    isWeb: true,
    backend: 'staging',
    stagingAnonKey: const String.fromEnvironment('SHOPTRACK_STAGING_ANON_KEY'),
  );
  await Supabase.initialize(url: backend.url, publishableKey: backend.anonKey);
  runApp(const ShopTrackWebApp());
}

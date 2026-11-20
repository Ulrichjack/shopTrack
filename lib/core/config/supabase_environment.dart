import 'package:shoptrack/supabase_config.dart';

/// Choisit le backend au démarrage, avant d'ouvrir Auth ou la base locale.
/// Une variante Android staging ne doit jamais utiliser la production (ni
/// l'inverse) : le cache local pourrait sinon être synchronisé au mauvais endroit.
class SupabaseEnvironment {
  const SupabaseEnvironment({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  static const stagingProjectRef = 'bjrmapcwfzrrvutozyfx';
  static const stagingUrl = 'https://$stagingProjectRef.supabase.co';

  static SupabaseEnvironment resolve({
    required String? flavor,
    required bool isWeb,
    required String backend,
    required String stagingAnonKey,
  }) {
    if (backend != 'production' && backend != 'staging') {
      throw StateError('Backend ShopTrack inconnu : $backend');
    }

    // Sur Android, applicationIdSuffix de staging isole aussi SQLite et Auth.
    // Le web de test devra être servi depuis une origine distincte.
    if (!isWeb && ((flavor == 'staging') != (backend == 'staging'))) {
      throw StateError('Variante et backend ShopTrack incompatibles');
    }

    if (backend == 'staging') {
      if (stagingAnonKey.isEmpty) {
        throw StateError('Clé publique Supabase staging manquante');
      }
      return SupabaseEnvironment(url: stagingUrl, anonKey: stagingAnonKey);
    }

    return const SupabaseEnvironment(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}

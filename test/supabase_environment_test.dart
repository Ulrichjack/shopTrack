import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/config/supabase_environment.dart';
import 'package:shoptrack/supabase_config.dart';

void main() {
  test('la variante production garde le backend actuel', () {
    final backend = SupabaseEnvironment.resolve(
      flavor: 'production',
      isWeb: false,
      backend: 'production',
      stagingAnonKey: '',
    );
    expect(backend.url, supabaseUrl);
    expect(backend.anonKey, supabaseAnonKey);
  });

  test('la variante staging utilise son projet et sa clé publique', () {
    final backend = SupabaseEnvironment.resolve(
      flavor: 'staging',
      isWeb: false,
      backend: 'staging',
      stagingAnonKey: 'clé-publique-fictive',
    );
    expect(backend.url, SupabaseEnvironment.stagingUrl);
    expect(backend.anonKey, 'clé-publique-fictive');
  });

  test('une variante staging ne démarre pas sur la production', () {
    expect(
      () => SupabaseEnvironment.resolve(
        flavor: 'staging',
        isWeb: false,
        backend: 'production',
        stagingAnonKey: '',
      ),
      throwsStateError,
    );
  });

  test('un APK de production ne démarre pas sur staging', () {
    expect(
      () => SupabaseEnvironment.resolve(
        flavor: 'production',
        isWeb: false,
        backend: 'staging',
        stagingAnonKey: 'clé-publique-fictive',
      ),
      throwsStateError,
    );
  });

  test('staging exige sa clé publique', () {
    expect(
      () => SupabaseEnvironment.resolve(
        flavor: 'staging',
        isWeb: false,
        backend: 'staging',
        stagingAnonKey: '',
      ),
      throwsStateError,
    );
  });

  test('le web de test peut utiliser staging depuis une origine distincte', () {
    final backend = SupabaseEnvironment.resolve(
      flavor: null,
      isWeb: true,
      backend: 'staging',
      stagingAnonKey: 'clé-publique-fictive',
    );
    expect(backend.url, SupabaseEnvironment.stagingUrl);
  });
}

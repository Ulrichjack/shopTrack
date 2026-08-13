import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/providers/app_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bossModeAccess.value = false;
  });

  test('le mode Patron reste actif après un redémarrage', () async {
    final firstSession = ProviderContainer();
    await firstSession.read(appModeProvider.future);
    await firstSession.read(appModeProvider.notifier).setPin('1234');
    expect(
      await firstSession.read(appModeProvider.notifier).unlockBossMode('1234'),
      isTrue,
    );
    firstSession.dispose();

    final restartedSession = ProviderContainer();
    expect(await restartedSession.read(appModeProvider.future), isTrue);
    restartedSession.dispose();
  });

  test('le verrouillage manuel persiste après un redémarrage', () async {
    final firstSession = ProviderContainer();
    await firstSession.read(appModeProvider.future);
    await firstSession.read(appModeProvider.notifier).setPin('1234');
    await firstSession.read(appModeProvider.notifier).unlockBossMode('1234');
    await firstSession.read(appModeProvider.notifier).lockApp();
    firstSession.dispose();

    final restartedSession = ProviderContainer();
    expect(await restartedSession.read(appModeProvider.future), isFalse);
    restartedSession.dispose();
  });

  test('changer de compte ne transmet pas le mode du précédent', () async {
    // Le patron A pose un PIN et verrouille en mode Vendeur, puis se
    // déconnecte. Le compte B, sur sa propre boutique neuve, ne doit ni
    // rester bloqué en Vendeur ni hériter d'un PIN qu'il ne connaît pas.
    final compteA = ProviderContainer();
    await compteA.read(appModeProvider.future);
    await compteA.read(appModeProvider.notifier).setPin('1234');
    expect(compteA.read(appModeProvider).value, isFalse);
    compteA.dispose();

    // Ce que fait la déconnexion : effacer les préférences puis relire l'état.
    SharedPreferences.setMockInitialValues({});
    final compteB = ProviderContainer();

    expect(
      await compteB.read(appModeProvider.future),
      isTrue,
      reason: 'une boutique sans PIN configuré donne l\'accès Patron',
    );
    expect(bossModeAccess.value, isTrue);
    expect(
      await compteB.read(appModeProvider.notifier).hasPinConfigured(),
      isFalse,
      reason: 'le PIN du compte précédent ne doit pas survivre',
    );
    compteB.dispose();
  });
}

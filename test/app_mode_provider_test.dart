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
}

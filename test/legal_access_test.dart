import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/features/legal/legal_content.dart';
import 'package:shoptrack/features/legal/legal_screen.dart';
import 'package:shoptrack/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'les droits restent accessibles pour toutes les situations de compte',
    () {
      for (final connected in [false, true]) {
        for (final temporaryPassword in [false, true]) {
          for (final boss in [false, true]) {
            for (final path in publicLegalRoutes) {
              expect(
                routeImposee(
                  connecte: connected,
                  doitChangerMotDePasse: temporaryPassword,
                  accesPatron: boss,
                  emplacement: path,
                ),
                isNull,
                reason: '$path / $connected / $temporaryPassword / $boss',
              );
            }
          }
        }
      }
      // L'exception publique ne doit pas devenir une ouverture par préfixe.
      expect(
        routeImposee(
          connecte: false,
          doitChangerMotDePasse: false,
          accesPatron: false,
          emplacement: '/privacy/bilan',
        ),
        '/login',
      );
      expect(
        routeImposee(
          connecte: true,
          doitChangerMotDePasse: true,
          accesPatron: true,
          emplacement: '/bilan',
        ),
        routePremierMotDePasse,
      );
    },
  );

  test(
    'les textes sont embarqués et les demandes ne lisent pas de compte',
    () async {
      final content = await LegalContent.load();
      expect(content.document('confidentialite').sections, isNotEmpty);
      expect(content.document('suppression-compte').sections, isNotEmpty);
      for (final request in DataRequest.values) {
        final uri = request.emailUri(content.contact);
        expect(uri.scheme, 'mailto');
        expect(uri.path, content.contact);
        expect(uri.queryParameters['body'], request.body);
        expect(uri.queryParameters['subject'], contains(request.subject));
        expect(uri.toString(), isNot(contains('+')));
        expect(request.body, contains('[à compléter]'));
      }
    },
  );

  for (final documentId in [
    'editeur',
    'confidentialite',
    'suppression-compte',
  ]) {
    testWidgets('$documentId se lit hors session sur petit écran', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // La lecture réelle du bundle doit sortir de l'horloge simulée du test.
      final content = (await tester.runAsync(LegalContent.load))!;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: LegalScreen(
            documentId: documentId,
            loadContent: () async => content,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Version préparatoire'), findsOneWidget);
      // Défile jusqu'aux actions du bas, y compris avec une police agrandie.
      await tester.scrollUntilVisible(
        find.widgetWithText(TextButton, 'Informations légales'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 50,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final result in ['opened', 'missing', 'error']) {
    testWidgets('messagerie $result : jamais de confirmation mensongère', (
      tester,
    ) async {
      Uri? received;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataRequestActions(
              contact: 'support@example.test',
              request: DataRequest.deletion,
              openEmail: (uri) async {
                received = uri;
                if (result == 'error') {
                  throw PlatformException(code: 'unavailable');
                }
                return result == 'opened';
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Préparer un e-mail'));
      await tester.pumpAndSettle();
      expect(received?.path, 'support@example.test');
      expect(
        find.textContaining(
          result == 'opened'
              ? 'ne confirme pas son envoi'
              : 'La messagerie n’a pas pu s’ouvrir',
        ),
        findsOneWidget,
      );
      expect(find.text('Demande envoyée'), findsNothing);
      expect(find.text('Compte supprimé'), findsNothing);
    });
  }

  testWidgets('copie explicite de la demande sans envoi', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DataRequestActions(
            contact: 'support@example.test',
            request: DataRequest.deletion,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Copier la demande'));
    await tester.pumpAndSettle();
    expect(copied, contains('À : support@example.test'));
    expect(copied, contains(DataRequest.deletion.body));
    expect(find.textContaining('pas encore envoyée'), findsOneWidget);
  });
}

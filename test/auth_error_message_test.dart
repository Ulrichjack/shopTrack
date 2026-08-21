import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/features/auth/domain/auth_error_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce que le commerçant lit quand quelque chose échoue.
///
/// Tout tombait dans « Erreur de connexion » : impossible de savoir s'il
/// fallait corriger une saisie ou attendre le réseau.
void main() {
  group('refus du serveur', () {
    test('mauvais identifiants : on nomme les deux champs possibles', () {
      expect(
        messageDErreurAuth(const AuthException('Invalid login credentials')),
        'Numéro ou mot de passe incorrect.',
      );
    });

    test('numéro déjà pris : on oriente vers la connexion', () {
      expect(
        messageDErreurAuth(const AuthException('User already registered')),
        contains('déjà un compte'),
      );
    });

    test('mot de passe trop court', () {
      expect(
        messageDErreurAuth(
          const AuthException('Password should be at least 6 characters'),
        ),
        contains('au moins 6 caractères'),
      );
    });

    test('mot de passe refusé par le serveur', () {
      expect(
        messageDErreurAuth(
          const AuthException('Password is known to be weak and easy to guess'),
        ),
        contains('trop courant'),
      );
    });

    test('trop de tentatives : attendre, pas corriger', () {
      expect(
        messageDErreurAuth(
          const AuthException('For security purposes, you can only request'),
        ),
        contains('Attends'),
      );
    });

    test("un refus inconnu garde son texte plutôt que de devenir « erreur »", () {
      // L'anglais exact reste exploitable — par nous quand le commerçant nous
      // le lit au téléphone, et par lui s'il reconnaît un mot.
      expect(
        messageDErreurAuth(const AuthException('Signups not allowed')),
        'Signups not allowed',
      );
    });
  });

  group('panne de réseau', () {
    test('coupure DNS : on ne parle pas de mot de passe', () {
      final message = messageDErreurAuth(
        const SocketException('Failed host lookup: supabase.co'),
      );
      expect(message, contains('connexion Internet'));
      expect(message, isNot(contains('mot de passe')));
    });

    test('les pannes de transport sont reconnues', () {
      for (final texte in [
        'ClientException with SocketException',
        'Connection closed before full header was received',
        'Connection refused',
        'Network is unreachable',
      ]) {
        expect(
          estUnePanneDeReseau(Exception(texte)),
          isTrue,
          reason: '$texte est une panne de réseau, pas un refus',
        );
      }
    });

    test('une panne déguisée en AuthException reste une panne', () {
      // `AuthRetryableFetchException` hérite d'`AuthException` tout en
      // n'enveloppant qu'un `SocketException`. Elle tombait dans la branche
      // des refus et ressortait en anglais brut : le commerçant lisait
      // « Software caused connection abort, errno = 103 » et cherchait quoi
      // corriger dans son mot de passe. Vu sur émulateur le 18/08/2026.
      const brut =
          'AuthRetryableFetchException(message: ClientException with '
          'SocketException: Software caused connection abort '
          '(OS Error: Software caused connection abort, errno = 103))';
      final message = messageDErreurAuth(const AuthException(brut));
      expect(message, contains('connexion Internet'));
      expect(message, isNot(contains('mot de passe')));
    });

    test('le réseau passe avant le serveur, sans masquer les vrais refus', () {
      // La garde réseau est en tête de fonction : elle ne doit pas avaler un
      // refus légitime au passage.
      expect(
        messageDErreurAuth(const AuthException('Invalid login credentials')),
        'Numéro ou mot de passe incorrect.',
      );
    });

    test("un refus du serveur n'est pas une panne de réseau", () {
      // Sinon on dirait « vérifie ton réseau » à quelqu'un dont le réseau va
      // très bien et qui a juste tapé le mauvais mot de passe.
      expect(
        estUnePanneDeReseau(const AuthException('Invalid login credentials')),
        isFalse,
      );
    });
  });
}

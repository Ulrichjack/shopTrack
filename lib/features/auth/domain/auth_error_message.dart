import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduit une erreur d'authentification en une phrase sur laquelle le
/// commerçant peut agir.
///
/// Tout tombait auparavant dans « Erreur de connexion » ou « Erreur réseau ».
/// Ces deux phrases ne disent pas s'il faut corriger le numéro, corriger le
/// mot de passe, ou simplement attendre le réseau — alors le commerçant
/// retape exactement la même chose, en boucle, et conclut que l'application
/// est cassée.
///
/// Les messages de Supabase arrivent en anglais : on les reconnaît par
/// fragment plutôt que par égalité, leur formulation exacte changeant d'une
/// version à l'autre. Un message non reconnu est renvoyé tel quel — l'anglais
/// exact reste plus utile qu'un « erreur » qui n'apprend rien, à nous comme au
/// commerçant qui nous le lira au téléphone.
String messageDErreurAuth(Object erreur) {
  // Le réseau AVANT le serveur : une panne de transport arrive déguisée en
  // `AuthException`. `AuthRetryableFetchException` en hérite tout en
  // n'enveloppant qu'un `SocketException` — elle tombait donc dans la branche
  // des refus, n'y trouvait aucun motif connu, et ressortait telle quelle.
  // Le commerçant lisait « ClientException with SocketException: Software
  // caused connection abort, errno = 103 » et cherchait quoi corriger dans
  // son mot de passe.
  if (estUnePanneDeReseau(erreur)) {
    return 'Pas de connexion Internet. Vérifie ton réseau et réessaie.';
  }

  if (erreur is AuthException) {
    final brut = erreur.message.toLowerCase();

    if (brut.contains('invalid login credentials')) {
      return 'Numéro ou mot de passe incorrect.';
    }
    if (brut.contains('already registered') ||
        brut.contains('already been registered') ||
        brut.contains('already exists')) {
      return 'Ce numéro a déjà un compte. Connecte-toi plutôt.';
    }
    if (brut.contains('at least') && brut.contains('characters')) {
      return 'Le mot de passe doit faire au moins 6 caractères.';
    }
    // « Leaked password protection » est réservé au forfait Pro, mais le
    // serveur peut refuser un mot de passe pour d'autres raisons de qualité.
    if (brut.contains('weak') ||
        brut.contains('pwned') ||
        brut.contains('leaked')) {
      return 'Ce mot de passe est trop courant. Choisis-en un autre.';
    }
    if (brut.contains('rate limit') ||
        brut.contains('too many') ||
        brut.contains('for security purposes')) {
      return 'Trop de tentatives. Attends une minute avant de réessayer.';
    }
    if (brut.contains('same as the old') ||
        brut.contains('should be different')) {
      return 'Le nouveau mot de passe doit être différent de l\'ancien.';
    }
    // L'adresse est fabriquée à partir du numéro : si Supabase la rejette,
    // c'est le numéro qui est mal formé.
    if (brut.contains('email') &&
        (brut.contains('invalid') || brut.contains('valid'))) {
      return 'Ce numéro de téléphone n\'est pas valide.';
    }

    return erreur.message;
  }

  return erreur.toString().replaceAll('Exception: ', '');
}

/// Vrai quand rien n'a pu atteindre le serveur.
///
/// Distinct d'un refus : le commerçant n'a rien à corriger, il a seulement à
/// attendre. Lui afficher « mot de passe incorrect » parce que le réseau a
/// coupé le pousserait à changer un mot de passe qui marche très bien.
bool estUnePanneDeReseau(Object erreur) {
  if (erreur is SocketException || erreur is TimeoutException) return true;

  final texte = erreur.toString();
  const pannesDeTransport = [
    'ClientException',
    'Failed host lookup',
    'Connection closed',
    'Connection refused',
    'Connection reset',
    'Software caused connection abort',
    'Network is unreachable',
    // Vu sur émulateur Android le 18/08/2026, enveloppé dans une
    // `AuthRetryableFetchException` : le nom même dit que c'est à réessayer.
    'AuthRetryableFetchException',
  ];
  return pannesDeTransport.any(texte.contains);
}

/// Traduit une erreur technique en message lisible par un commerçant.
///
/// Les erreurs réseau brutes (`SocketException`, `Failed host lookup`,
/// `errno = 7`) sont incompréhensibles et inquiètent inutilement : dans tous
/// ces cas les données sont saines, simplement pas encore envoyées.
String humanSyncError(Object? error) {
  if (error == null) return '';
  final raw = error.toString();
  final text = raw.toLowerCase();

  final isNetwork =
      text.contains('failed host lookup') ||
      text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('no address associated') ||
      text.contains('connection refused') ||
      text.contains('connection closed') ||
      text.contains('network is unreachable') ||
      text.contains('timeout') ||
      text.contains('timed out');
  if (isNetwork) {
    return 'Pas d\'accès à internet pour le moment. '
        'Tes données sont enregistrées sur le téléphone et seront envoyées '
        'automatiquement dès que la connexion revient.';
  }

  // Une colonne absente = migration Supabase non appliquée. Message explicite
  // plutôt que de laisser chercher : c'est arrivé plusieurs fois en bêta.
  if (text.contains('does not exist') || text.contains('schema cache')) {
    return 'La base du serveur n\'est pas à jour (migration manquante). '
        'Contacte le support technique.';
  }

  if (text.contains('permission denied') ||
      text.contains('row-level security') ||
      text.contains('jwt') ||
      text.contains('not authorized')) {
    return 'Accès refusé par le serveur. Déconnecte-toi puis reconnecte-toi.';
  }

  if (text.contains('duplicate key') || text.contains('unique constraint')) {
    return 'Cette opération a déjà été enregistrée.';
  }

  if (text.contains('stock insuffisant')) {
    return raw.replaceAll('Exception: ', '');
  }

  return raw.replaceAll('Exception: ', '');
}

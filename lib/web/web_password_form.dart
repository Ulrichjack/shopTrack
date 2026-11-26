import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_theme.dart';

/// Le compte doit-il remplacer un mot de passe provisoire avant d'entrer ?
///
/// Sorti de l'écran pour être testable : c'est la seule barrière du web, et
/// l'Android a extrait `routeImposee()` de son routeur pour la même raison.
/// Un marqueur absent, nul ou d'un autre type vaut « non » — seule la valeur
/// vraie bloque, pour qu'un compte normal ne se retrouve jamais enfermé.
bool motDePasseProvisoireAChanger(Map<String, dynamic>? metadonnees) =>
    metadonnees?['must_change_password'] == true;

class WebPasswordForm extends StatefulWidget {
  const WebPasswordForm({super.key});

  @override
  State<WebPasswordForm> createState() => _WebPasswordFormState();
}

class _WebPasswordFormState extends State<WebPasswordForm> {
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _actuel.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _changer() async {
    if (_enCours) return;
    if (_nouveau.text != _confirmation.text) {
      setState(() => _erreur = 'Les deux nouveaux mots de passe diffèrent.');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final actuel = _actuel.text.trim();
      final nouveau = _nouveau.text.trim();
      if (nouveau.length < 6 || nouveau == actuel) {
        throw ArgumentError('Choisis un nouveau mot de passe différent de 6 caractères minimum.');
      }
      final client = Supabase.instance.client;
      final email = client.auth.currentUser?.email;
      if (email == null) throw StateError('Aucune session ouverte.');
      try {
        await client.auth.signInWithPassword(email: email, password: actuel);
      } on AuthException {
        throw ArgumentError('Mot de passe actuel incorrect.');
      }
      await client.auth.updateUser(UserAttributes(
        password: nouveau,
        data: const {'must_change_password': false},
      ));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _erreur = e is ArgumentError
          ? '${e.message}' : 'Changement non confirmé. Vérifie le mot de passe actuel et Internet.');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(24, 20, 24,
      MediaQuery.viewInsetsOf(context).bottom + 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Changer mon mot de passe',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 18),
        TextField(controller: _actuel, obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe actuel')),
        const SizedBox(height: 12),
        TextField(controller: _nouveau, obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe',
              helperText: '6 caractères minimum')),
        const SizedBox(height: 12),
        TextField(controller: _confirmation, obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmer le nouveau')),
        if (_erreur != null) ...[
          const SizedBox(height: 10),
          Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _enCours ? null : _changer,
            icon: const Icon(Icons.lock_reset_outlined),
            label: Text(_enCours ? 'Enregistrement…' : 'Changer le mot de passe')),
      ],
    ),
  );
}

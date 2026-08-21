import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/employees_provider.dart';
import '../../domain/auth_error_message.dart';
import '../providers/session_handover.dart';

/// Le vendeur choisit son mot de passe avant d'entrer dans l'application.
///
/// Le patron crée le compte avec un mot de passe provisoire qu'il dit à voix
/// haute, souvent devant d'autres personnes. Tant que le vendeur ne l'a pas
/// changé, le patron — ou qui l'a entendu — peut se connecter à sa place :
/// l'historique « qui a vendu quoi » ne prouve alors plus rien, et c'est
/// justement ce que le journal d'activité est censé établir.
///
/// C'est pour ça que le passage est imposé par `router.dart` et non par un
/// bouton dans le profil : un écran qu'on peut ignorer n'impose rien.
///
/// [motDePasseProvisoire] vient de l'écran de connexion : le vendeur vient de
/// le taper, le redemander à la ligne suivante n'apprendrait rien à personne et
/// ferait trois champs à remplir sur un téléphone. Il est nul quand la session
/// a été retrouvée au démarrage — l'app se rouvre déjà connectée, sans que
/// personne ait tapé quoi que ce soit. Dans ce cas seulement on le redemande,
/// sinon quiconque trouve le téléphone déverrouillé s'approprie le compte et
/// enferme dehors son propriétaire.
class FirstPasswordScreen extends ConsumerStatefulWidget {
  const FirstPasswordScreen({super.key, this.motDePasseProvisoire});

  final String? motDePasseProvisoire;

  @override
  ConsumerState<FirstPasswordScreen> createState() =>
      _FirstPasswordScreenState();
}

class _FirstPasswordScreenState extends ConsumerState<FirstPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _provisoire = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();

  bool _enCours = false;
  String? _erreur;

  /// Vrai quand la session a été retrouvée au démarrage : personne n'a tapé le
  /// mot de passe provisoire, il faut donc le demander.
  bool get _demanderLeProvisoire => widget.motDePasseProvisoire == null;

  @override
  void dispose() {
    _provisoire.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enCours = true;
      _erreur = null;
    });

    try {
      await changerMotDePasse(
        actuel: widget.motDePasseProvisoire ?? _provisoire.text,
        nouveau: _nouveau.text,
      );
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        // Les ArgumentError viennent de nos propres contrôles, déjà en
        // français. Le reste vient de Supabase, en anglais : on le traduit.
        _erreur = erreur is ArgumentError
            ? '${erreur.message}'
            : messageDErreurAuth(erreur);
      });
      return;
    }

    // `changerMotDePasse` a remis `must_change_password` à faux : la garde du
    // routeur laisse désormais passer.
    if (!mounted) return;
    context.go('/home');
  }

  /// La seule sortie possible. Sans elle, un vendeur qui a oublié le mot de
  /// passe que son patron lui a dit resterait bloqué sur cet écran, sans même
  /// pouvoir rendre le téléphone à quelqu'un d'autre.
  Future<void> _seDeconnecter() async {
    // Même raison que dans le profil : ce vendeur rend le téléphone.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cleDernierNumero);
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Aucun retour en arrière : le bouton système ramènerait à l'écran d'où
    // l'on vient, c'est-à-dire dans l'application, mot de passe inchangé.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          // Le clavier réduit la hauteur de moitié sur un petit écran : sans
          // défilement, le bouton de validation passe sous le clavier.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.lock_reset,
                    size: 72,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choisis ton mot de passe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ton patron connaît le mot de passe provisoire qu\'il t\'a '
                    'donné. Choisis-en un que toi seul connais : les ventes '
                    'enregistrées sous ton nom te seront alors bien attribuées.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_demanderLeProvisoire) ...[
                    TextFormField(
                      controller: _provisoire,
                      obscureText: true,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe provisoire',
                        helperText: 'Celui que ton patron t\'a donné',
                        prefixIcon: Icon(Icons.key),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.cardBg,
                      ),
                      validator: (valeur) => (valeur == null || valeur.isEmpty)
                          ? 'Entre le mot de passe provisoire'
                          : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  TextFormField(
                    controller: _nouveau,
                    obscureText: true,
                    autofocus: !_demanderLeProvisoire,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      helperText: 'Au moins 6 caractères',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.cardBg,
                    ),
                    validator: (valeur) {
                      if (valeur == null || valeur.length < 6) {
                        return 'Au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmation,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Répète le nouveau mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.cardBg,
                    ),
                    // Deux champs plutôt qu'un : une faute de frappe dans un
                    // champ masqué ne se voit pas, et le vendeur se retrouverait
                    // dehors avec un mot de passe que personne ne connaît.
                    validator: (valeur) => valeur != _nouveau.text
                        ? 'Les deux mots de passe sont différents'
                        : null,
                  ),

                  if (_erreur != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _erreur!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _enCours ? null : _valider,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _enCours
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Valider et entrer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  TextButton(
                    onPressed: _enCours ? null : _seDeconnecter,
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../../core/providers/employees_provider.dart';
import '../providers/session_handover.dart';
import '../../../../router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rappelerLeDernierNumero();
  }

  /// Le numéro de la dernière connexion, pré-rempli.
  ///
  /// Sur un téléphone de boutique c'est toujours le même compte qui revient.
  /// Le mot de passe, lui, reste à taper : c'est lui qui protège, pas le
  /// numéro — qui est de toute façon écrit sur l'enseigne.
  Future<void> _rappelerLeDernierNumero() async {
    final prefs = await SharedPreferences.getInstance();
    final numero = prefs.getString(cleDernierNumero);
    if (numero == null || numero.isEmpty || !mounted) return;
    if (_phoneController.text.isNotEmpty) return;
    _phoneController.text = numero;
  }

  /// Le geste de connexion — déclenché par le bouton ET par la touche de
  /// validation du clavier, pour ne pas obliger à refermer celui-ci d'abord.
  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authProvider.notifier)
          .login(_phoneController.text, _passwordController.text);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        cleDernierNumero,
        _phoneController.text.replaceAll(' ', '').trim(),
      );

      // Ménage, mémorisation du compte, invalidations et rechargement : tout
      // est dans `prendreEnMainLaSession`, partagé avec l'inscription.
      await prendreEnMainLaSession(ref, inscription: false);
      if (!mounted) return;

      // Sauf si le vendeur utilise encore le mot de passe provisoire que son
      // patron lui a dit. Le routeur l'y renverrait de toute façon ; passer
      // par ici permet de lui transmettre le mot de passe qu'il vient de
      // taper, pour ne pas le lui redemander à la ligne suivante.
      if (doitChangerMotDePasse()) {
        context.go(routePremierMotDePasse, extra: _passwordController.text);
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Très bonne pratique : évite les fuites de mémoire sur le téléphone
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch dit à Flutter : "Dès que l'état de authProvider change, redessine ce build()"
    final isLoading = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        // Ancré en haut, PAS centré.
        //
        // Avec `Center` + une colonne centrée, fermer le clavier agrandit la
        // zone visible et recentre tout : le bouton s'échappe sous le doigt
        // avant que l'appui soit reconnu. D'où le « il faut taper deux fois »
        // — le premier appui ne servait qu'à refermer le clavier.
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.storefront, // Une icône de boutique
                    size: 100,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'ShopTrack',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900, // Très gras
                      color: AppColors.primary,
                      letterSpacing: 1.5, // Espace un peu les lettres
                    ),
                  ),

                  const Text(
                    'Connexion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixText: '+237 ',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le numéro est obligatoire';
                      }
                      // Regex : Commence par 6 ou 2, suivi de 8 chiffres (total 9)
                      final phoneRegex = RegExp(r'^[26]\d{8}$');
                      if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                        return 'Entrez un numéro camerounais valide (9 chiffres)';
                      }
                      return null; // null veut dire "C'est valide !"
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    // Valider depuis le clavier : le chemin le plus court, et
                    // celui qui contourne tout déplacement de mise en page.
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _seConnecter(),
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le mot de passe est obligatoire';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit faire au moins 6 caractères';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: isLoading ? null : _seConnecter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    // TODO 4: Remplacement du texte par un spinner blanc si ça charge
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      '/register',
                    ), // push permet de revenir en arrière
                    child: const Text(
                      "Je n'ai pas de compte ? Créer ma boutique",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _shopNameController = TextEditingController();

  @override
  void dispose() {
    // Très bonne pratique : évite les fuites de mémoire sur le téléphone
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch dit à Flutter : "Dès que l'état de authProvider change, redessine ce build()"
    final isLoading = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    'Créer ma boutique',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la boutique',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom de la boutique est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16), // Espace avec le champ précédent

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer le mot de passe';
                      }
                      // 👇 LA MAGIE EST ICI : On compare avec le premier champ 👇
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                      // 👇 1. ON VÉRIFIE LE FORMULAIRE ICI 👇
                      if (_formKey.currentState!.validate()) {

                        // 2. Si c'est valide, on lance l'inscription
                        try {
                          await ref.read(authProvider.notifier).register(
                            _phoneController.text,
                            _passwordController.text,
                            _shopNameController.text,
                          );

                          if (context.mounted) {
                            context.go('/home');
                          }
                        } catch (e) {
                          // Afficher l'erreur (comme on l'a vu précédemment)
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }

                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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
                      'Créer mon compte',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(), // pop ferme l'écran actuel et revient au login
                    child: const Text(
                      "J'ai déjà un compte ? Me connecter",
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
// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
// TODO 1: Import de ton auth_provider.dart
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Très bonne pratique : évite les fuites de mémoire sur le téléphone
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO 2: Écoute de l'état de chargement (true/false) du provider
    // ref.watch dit à Flutter : "Dès que l'état de authProvider change, redessine ce build()"
    final isLoading = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                  'Connexion',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  // TODO 3: Si isLoading est true, on met onPressed à null, ce qui désactive le bouton gris automatiquement
                  onPressed: isLoading
                      ? null
                      : () {
                    // ref.read (sans watch) pour déclencher l'action unique du login au clic
                    ref.read(authProvider.notifier).login(
                      _phoneController.text,
                      _passwordController.text,
                    );
                  },
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
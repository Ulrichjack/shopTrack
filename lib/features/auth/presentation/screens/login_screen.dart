// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/providers/shop_settings_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/sync/sync_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Efface les données locales quand ce n'est pas le même compte qu'avant.
Future<void> _nettoyerSiAutreCompte(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final precedent = prefs.getString('cached_user_id');
  final actuel = Supabase.instance.client.auth.currentUser?.id;
  if (actuel == null || precedent == null || precedent == actuel) return;

  await ref.read(localDbProvider).clearAllData();
  await prefs.remove(cachedShopIdKey);
  await prefs.remove('cached_shop_name');
  await prefs.remove('cached_is_owner');
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
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
                    onPressed: isLoading
                        ? null
                        : () async {
                            // <-- Ajoute async ici

                            if (_formKey.currentState!.validate()) {
                              try {
                                // 1. On attend que le login se termine
                                await ref
                                    .read(authProvider.notifier)
                                    .login(
                                      _phoneController.text,
                                      _passwordController.text,
                                    );

                                // Une nouvelle session doit repartir avec des données
                                // fraîchement chargées, notamment après une précédente
                                // erreur ou une déconnexion/reconnexion.
                                // Le ménage se fait ICI, et seulement si le
                                // compte a changé. La déconnexion ne vide plus
                                // rien : revenir sur son propre compte doit
                                // être instantané et marcher hors ligne, sans
                                // retélécharger tout l'historique.
                                //
                                // Mais un AUTRE compte ne doit jamais hériter
                                // des données du précédent — sur un téléphone
                                // partagé, ce serait le stock d'une boutique
                                // affiché à quelqu'un qui n'y a pas accès.
                                await _nettoyerSiAutreCompte(ref);

                                ref.invalidate(dashboardProvider);
                                ref.invalidate(productProvider);
                                // Le mode de la boutique aussi : il se lit
                                // depuis `cached_shop_id`, écrit pendant la
                                // connexion. Sans cette invalidation, le
                                // provider gardait les valeurs par défaut
                                // calculées avant que la boutique soit connue
                                // — le commerçant retrouvait le mode simple et
                                // devait réactiver son module à chaque
                                // connexion.
                                ref.invalidate(shopSettingsProvider);

                                // 2. Si l'écran est toujours affiché (bonne pratique Flutter)
                                if (context.mounted) {
                                  // 3. On navigue vers le Dashboard !
                                  context.go('/home');
                                }
                              } catch (e) {
                                // Afficher l'erreur (comme on l'a vu précédemment)
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
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

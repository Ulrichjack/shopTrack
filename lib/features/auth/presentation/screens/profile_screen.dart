import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_mode_provider.dart';
import '../../../../core/sync/sync_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _shopName = "Ma Boutique";
  late Future<bool> _hasPinFuture;

  @override
  void initState() {
    super.initState();
    _hasPinFuture = ref.read(appModeProvider.notifier).hasPinConfigured();
    _loadShopName();
  }

  // 👇 On charge le nom de la boutique sauvegardé
  Future<void> _loadShopName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shopName = prefs.getString('cached_shop_name') ?? "Ma Boutique";
    });
  }

  // --- DÉCONNEXION ---
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ? Assurez-vous d\'avoir internet pour ne pas perdre vos données non synchronisées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = ref.read(localDbProvider);
      await db.clearAllData();

      // On vide aussi les SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // --- CRÉER UN CODE PIN ---
  void _showCreatePinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un Code PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ce code bloquera l\'accès au Bilan et aux Bénéfices pour vos vendeurs.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Code PIN (4 chiffres)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length == 4) {
                await ref.read(appModeProvider.notifier).setPin(pinController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code PIN créé. Mode Vendeur activé !'), backgroundColor: AppColors.primary),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- DÉVERROUILLER (MODE PATRON) ---
  void _showUnlockDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déverrouiller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre code PIN pour accéder au mode Patron.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Code PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(appModeProvider.notifier).unlockBossMode(pinController.text);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mode Patron activé !'), backgroundColor: AppColors.primary),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code PIN incorrect'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- SUPPRIMER LE CODE PIN ---
  void _showRemovePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la protection'),
        content: const Text('Voulez-vous vraiment supprimer le code PIN ? L\'application ne sera plus protégée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(appModeProvider.notifier).removePin();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Protection supprimée.'), backgroundColor: Colors.orange),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final phone = user?.email?.replaceAll('@shoptrack.cm', '') ?? 'Inconnu';

    final isBossMode = ref.watch(appModeProvider).value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- EN-TÊTE PROFIL ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: isBossMode ? AppColors.primaryLight : Colors.orange.shade100,
                    child: Icon(
                        isBossMode ? Icons.admin_panel_settings : Icons.storefront,
                        size: 50,
                        color: isBossMode ? AppColors.primaryDark : Colors.orange.shade800
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _shopName, // 👈 Le vrai nom de la boutique s'affiche ici !
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBossMode ? 'Mode Patron' : 'Mode Vendeur',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isBossMode ? AppColors.primaryDark : Colors.orange.shade800
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                    child: Text('+237 $phone', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- SECTION SÉCURITÉ ---
            const Text('SÉCURITÉ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            // 👇 CORRECTION DE L'ERREUR FLUTTER (Utilisation de Material) 👇
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FutureBuilder<bool>(
                  future: _hasPinFuture,
                  builder: (context, snapshot) {
                    final hasPin = snapshot.data ?? false;

                    return Column(
                      children: [
                        if (!hasPin)
                          ListTile(
                            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                            title: const Text('Protéger l\'application', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Créer un code PIN pour les vendeurs'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: _showCreatePinDialog,
                          ),

                        if (hasPin && !isBossMode)
                          ListTile(
                            leading: const Icon(Icons.lock_open, color: AppColors.primary),
                            title: const Text('Déverrouiller (Patron)', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Entrez le code pour voir les bénéfices'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: _showUnlockDialog,
                          ),

                        if (hasPin && isBossMode) ...[
                          ListTile(
                            leading: const Icon(Icons.lock, color: Colors.orange),
                            title: const Text('Verrouiller l\'application', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Passer en mode vendeur'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              ref.read(appModeProvider.notifier).lockApp();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Application verrouillée. Mode Vendeur actif.'), backgroundColor: Colors.orange),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.delete_outline, color: Colors.red),
                            title: const Text('Supprimer le code PIN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            onTap: _showRemovePinDialog,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- BOUTON DÉCONNEXION ---
            ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 20),
            const Center(child: Text('ShopTrack v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
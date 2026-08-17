import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_mode_provider.dart';
import '../../../../core/providers/shop_settings_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../features/products/presentation/providers/product_provider.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../shared/widgets/shop_switcher.dart';
import '../../../../core/providers/employees_provider.dart';
import '../../../../core/providers/user_shops_provider.dart';
import '../../../../core/providers/current_shop_provider.dart';

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
  Future<void> _changerMotDePasse(BuildContext context, WidgetRef ref) async {
    final champ = TextEditingController();
    final confirmation = TextEditingController();

    final valide = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: champ,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                helperText: '6 caractères minimum',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmation,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Répète-le',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (valide != true) return;
    if (champ.text.trim() != confirmation.text.trim()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les deux mots de passe ne sont pas identiques.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      await changerMotDePasse(champ.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe changé.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ? Assurez-vous d\'avoir internet pour ne pas perdre vos données non synchronisées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = ref.read(localDbProvider);
      if (await db.getPendingCount() > 0) {
        await ref.read(syncServiceProvider).processQueue();
        final remaining = await db.getPendingCount();
        if (remaining > 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Déconnexion annulée : $remaining opération(s) ne sont '
                  'pas encore synchronisées.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }
      await ref.read(backupServiceProvider).createBackup();

      // Quitter l'accueil AVANT de toucher à l'état : sinon l'écran encore
      // affiché se reconstruit sur une app sans boutique.
      if (mounted) context.go('/login');

      // On NE vide plus la base ni les préférences.
      //
      // C'était la sécurité du temps où un compte valait une boutique : le
      // suivant ne devait pas hériter des données du précédent. Mais se
      // déconnecter et revenir obligeait à retélécharger tout le stock, tous
      // les comptages, tout l'historique — long, et impossible hors ligne.
      //
      // Le nettoyage se fait désormais **à la connexion**, et seulement si le
      // compte a changé : voir `login_screen`. Même compte, données gardées.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('boss_mode_active');

      // Le mode Patron/Vendeur et les réglages de boutique vivent en mémoire :
      // vider la base ne les efface pas. Sans ce reset, le compte suivant
      // hérite de l'état du précédent — bloqué en Vendeur sur sa propre
      // boutique neuve, ou pire, Patron sans connaître le moindre PIN.
      bossModeAccess.value = false; // rien n'est ouvert tant qu'on ne sait pas
      ref.invalidate(appModeProvider);
      ref.invalidate(currentShopIdProvider);
      ref.invalidate(userShopsProvider);
      ref.invalidate(estProprietaireProvider);
      ref.invalidate(shopSettingsProvider);
      ref.invalidate(productProvider);
      ref.invalidate(dashboardProvider);

      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
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
            const Text(
              'Ce code bloquera l\'accès au Bilan et aux Bénéfices pour vos vendeurs.',
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length == 4) {
                await ref
                    .read(appModeProvider.notifier)
                    .setPin(pinController.text);
                if (mounted) {
                  setState(() {
                    _hasPinFuture = Future.value(true);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code PIN créé. Mode Vendeur activé !'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref
                  .read(appModeProvider.notifier)
                  .unlockBossMode(pinController.text);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mode Patron activé !'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code PIN incorrect'),
                      backgroundColor: AppColors.error,
                    ),
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
        content: const Text(
          'Voulez-vous vraiment supprimer le code PIN ? L\'application ne sera plus protégée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(appModeProvider.notifier).removePin();
              if (mounted) {
                setState(() {
                  _hasPinFuture = Future.value(false);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Protection supprimée.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
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
      appBar: AppBar(title: const Text('Mon Profil'), elevation: 0),
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
                    backgroundColor: isBossMode
                        ? AppColors.primaryLight
                        : Colors.orange.shade100,
                    child: Icon(
                      isBossMode
                          ? Icons.admin_panel_settings
                          : Icons.storefront,
                      size: 50,
                      color: isBossMode
                          ? AppColors.primaryDark
                          : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _shopName, // 👈 Le vrai nom de la boutique s'affiche ici !
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBossMode ? 'Mode Patron' : 'Mode Vendeur',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isBossMode
                          ? AppColors.primaryDark
                          : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+237 $phone',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- SECTION SÉCURITÉ ---
            const Text(
              'SÉCURITÉ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
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
                        // Pour tout le monde, patron comme vendeur : chacun
                        // doit pouvoir changer son mot de passe, et le vendeur
                        // arrive justement avec un provisoire donné par son
                        // patron — qui le connaît encore.
                        ListTile(
                          leading: const Icon(
                            Icons.password_outlined,
                            color: AppColors.primaryDark,
                          ),
                          title: const Text(
                            'Changer mon mot de passe',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () => _changerMotDePasse(context, ref),
                        ),
                        const Divider(height: 1),

                        // Réservé au patron : un vendeur ne peut rien en faire
                        // — son rôle vient du serveur, et le PIN ne le
                        // déverrouillerait pas. Le lui montrer n'apporte que
                        // du doute.
                        //
                        // Le PIN garde son sens pour le téléphone partagé du
                        // comptoir : le patron y travaille, puis le laisse à
                        // son vendeur sans se déconnecter — la déconnexion
                        // efface les données locales.
                        if (!hasPin && isBossMode)
                          ListTile(
                            leading: const Icon(
                              Icons.lock_outline,
                              color: AppColors.primary,
                            ),
                            title: const Text(
                              'Protéger l\'application',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Créer un code PIN pour les vendeurs',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: _showCreatePinDialog,
                          ),

                        if (hasPin && !isBossMode)
                          ListTile(
                            leading: const Icon(
                              Icons.lock_open,
                              color: AppColors.primary,
                            ),
                            title: const Text(
                              'Déverrouiller (Patron)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Entrez le code pour voir les bénéfices',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: _showUnlockDialog,
                          ),

                        // Gérer ses boutiques et ses employés ne dépend pas
                        // d'un PIN : un patron qui n'en a pas encore posé
                        // reste le patron, et c'est même le premier à qui ces
                        // écrans servent. Le PIN ne protège que le passage en
                        // mode vendeur sur un téléphone partagé.
                        if (isBossMode) ...[
                          ListTile(
                            leading: const Icon(
                              Icons.add_business_outlined,
                              color: AppColors.primaryDark,
                            ),
                            title: const Text(
                              'Ajouter une boutique',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Elle reprendra le mode de celle-ci',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () =>
                                ouvrirCreationBoutique(context, ref),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.people_outline,
                              color: AppColors.primaryDark,
                            ),
                            title: const Text(
                              'Employés',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Un compte par vendeur, limité à cette boutique',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () => context.push('/employees'),
                          ),
                          const Divider(height: 1),
                        ],

                        // Le verrouillage et le retrait du PIN n'ont de sens
                        // que si un PIN existe.
                        if (hasPin && isBossMode) ...[
                          ListTile(
                            leading: const Icon(
                              Icons.lock,
                              color: Colors.orange,
                            ),
                            title: const Text(
                              'Verrouiller l\'application',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('Passer en mode vendeur'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () async {
                              await ref
                                  .read(appModeProvider.notifier)
                                  .lockApp();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Application verrouillée. Mode Vendeur actif.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Supprimer le code PIN',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

            const Text(
              'DONNÉES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sync, color: AppColors.primary),
                    title: const Text('État de synchronisation'),
                    subtitle: const Text(
                      'Opérations en attente et erreurs réseau',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/sync-status'),
                  ),
                  if (isBossMode) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: AppColors.primary,
                      ),
                      title: const Text('Historique d’audit'),
                      subtitle: const Text('Ventes, caisse, stock et clôtures'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/activity-log'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Réglages de la boutique'),
                      subtitle: const Text(
                        'Vente par unités, modules optionnels',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/shop-settings'),
                    ),
                  ],
                ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),
            const Center(
              child: Text(
                'ShopTrack v1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

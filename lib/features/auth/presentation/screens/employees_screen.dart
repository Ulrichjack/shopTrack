import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/providers/employees_provider.dart';

/// Les comptes qui ont accès à la boutique active.
///
/// Un compte par employé au lieu du compte partagé : le vendeur n'atteint
/// qu'une boutique, et le retirer se résume à supprimer sa ligne — alors
/// qu'aujourd'hui il repart avec le mot de passe du patron.
class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membres = ref.watch(shopMembersProvider);
    final moi = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Employés')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ajouter(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Ajouter'),
      ),
      body: SafeArea(
        child: membres.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(humanSyncError(e), textAlign: TextAlign.center),
            ),
          ),
          data: (liste) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              for (final membre in liste)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      membre.isOwner
                          ? Icons.admin_panel_settings_outlined
                          : Icons.person_outline,
                      color: AppColors.primaryDark,
                    ),
                    title: Text(
                      membre.isOwner ? 'Patron' : 'Vendeur',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      membre.userId == moi
                          ? 'Toi'
                          : membre.userId.substring(0, 8),
                    ),
                    trailing: membre.isOwner || membre.userId == moi
                        ? null
                        : IconButton(
                            tooltip: 'Retirer de cette boutique',
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              color: AppColors.error,
                            ),
                            onPressed: () =>
                                _retirer(context, ref, membre.userId),
                          ),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Le mot de passe que tu donnes est provisoire : ton employé '
                  'devra en choisir un autre à sa première connexion.',
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ajouter(BuildContext context, WidgetRef ref) async {
    final telephone = TextEditingController();
    final motDePasse = TextEditingController();

    final valide = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau vendeur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: telephone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motDePasse,
              decoration: const InputDecoration(
                labelText: 'Mot de passe provisoire',
                helperText: '6 caractères minimum',
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (valide != true) return;
    try {
      await ref
          .read(employeeCreationProvider)
          .creerVendeur(
            telephone: telephone.text,
            motDePasseProvisoire: motDePasse.text,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vendeur créé. Il se connecte avec ${telephone.text.trim()} '
              'et le mot de passe provisoire.',
            ),
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

  Future<void> _retirer(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet employé ?'),
        content: const Text(
          'Il n\'aura plus accès à cette boutique. Son compte reste, et son '
          'historique aussi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    try {
      await ref.read(employeeCreationProvider).retirer(userId);
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
}

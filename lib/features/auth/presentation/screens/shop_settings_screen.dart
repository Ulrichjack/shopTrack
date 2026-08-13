import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/providers/shop_settings_provider.dart';

/// Réglages métier de la boutique : le patron active uniquement ce dont il a
/// besoin. Tout est désactivé par défaut — une boutique neuve fonctionne en
/// vente simple, sans jamais voir ces notions.
class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() =>
      _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  bool _saving = false;

  Future<void> _toggleUnitMode(bool value) async {
    setState(() => _saving = true);
    try {
      // Les deux modes s'excluent : en inventaire périodique on n'enregistre
      // plus aucune vente, donc « vendre au plateau » n'a plus d'objet.
      if (value) {
        await ref.read(shopSettingsProvider.notifier).setSaleCaptureMode(false);
      }
      await ref.read(shopSettingsProvider.notifier).setUnitMode(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Vente par unités activée. L\'onglet Cycles est apparu.'
                  : 'Vente par unités désactivée. Tes cycles sont conservés.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanSyncError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleCaptureMode(bool value) async {
    setState(() => _saving = true);
    try {
      if (value) {
        await ref.read(shopSettingsProvider.notifier).setUnitMode(false);
      }
      await ref.read(shopSettingsProvider.notifier).setSaleCaptureMode(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Inventaire périodique activé. L\'onglet Inventaire est '
                        'apparu.'
                  : 'Retour à la saisie des ventes au fil de l\'eau.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanSyncError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(shopSettingsProvider);
    final isHierarchical =
        settingsAsync.value?.unitMode == 'hierarchical';
    final isPeriodic =
        settingsAsync.value?.saleCaptureMode == 'periodic';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Réglages de la boutique')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Active uniquement ce dont ta boutique a besoin. '
              'Tout est désactivé par défaut.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SwitchListTile(
                  value: isHierarchical,
                  onChanged: _saving ? null : _toggleUnitMode,
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    'Vente par unités',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Vendre au plateau, au carton, au casier… avec suivi du '
                    'coût réel de chaque arrivage.',
                  ),
                ),
              ),
            ),

            if (isHierarchical)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Un onglet « Cycles » est disponible en bas de l\'écran. '
                    'Les produits sans unité définie continuent de se vendre '
                    'normalement.',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SwitchListTile(
                  value: isPeriodic,
                  onChanged: _saving ? null : _toggleCaptureMode,
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    'Inventaire périodique',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Ne plus saisir chaque vente : noter la recette du jour, '
                    'compter le stock de temps en temps, et laisser l\'app '
                    'déduire ce qui a été vendu.',
                  ),
                ),
              ),
            ),

            if (isPeriodic)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Dans ce mode, les ventes ne sont plus enregistrées une '
                    'par une : la clôture de caisse quotidienne ne peut donc '
                    'plus être calculée. Ne bascule qu\'entre deux périodes '
                    'terminées, sinon les ventes déjà saisies seraient '
                    'recomptées dans l\'estimation.',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/dashboard_provider.dart';

class ClosingScreen extends ConsumerStatefulWidget {
  const ClosingScreen({super.key});

  @override
  ConsumerState<ClosingScreen> createState() => _ClosingScreenState();
}

class _ClosingScreenState extends ConsumerState<ClosingScreen> {
  int _currentStep = 1; // 1: Résumé, 2: Saisie physique, 3: Résultat
  final _cashController = TextEditingController();
  double? _physicalCash;
  double? _cashGap;
  bool _isSaving = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  /// Avertit sans bloquer si on clôture tôt : les boutiques n'ont pas toutes
  /// le même horaire (jour de marché, fermeture tardive), donc une heure
  /// imposée serait contournée tous les jours. Ce qui protège vraiment de
  /// l'erreur, c'est la possibilité de rouvrir la journée.
  Future<bool> _confirmEarlyClosing() async {
    final now = DateTime.now();
    if (now.hour >= 16) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clôturer maintenant ?'),
        content: Text(
          'Il n\'est que ${DateFormat('HH:mm').format(now)}.\n\n'
          'Après la clôture, tu ne pourras plus vendre aujourd\'hui sans '
          'rouvrir la journée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Clôturer quand même',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider).value;

    if (dashboardState == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clôture de caisse'),
        backgroundColor: _currentStep == 3
            ? (_cashGap == 0
                  ? Colors.green
                  : (_cashGap! < 0 ? Colors.orange : Colors.blue))
            : AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ÉTAPE 1 : LE RÉSUMÉ ---
              if (_currentStep == 1) ...[
                const Text(
                  'Résumé de la journée',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Solde matin', dashboardState.morningBalance),
                      const Divider(),
                      _buildRow('Ventes (+)', dashboardState.totalSales),
                      const Divider(),
                      _buildRow(
                        'Sorties (-)',
                        dashboardState.totalWithdrawals,
                        isNegative: true,
                      ),
                      const Divider(thickness: 2),
                      _buildRow(
                        'Caisse Calculée',
                        dashboardState.calculatedCash,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Compter ma caisse maintenant',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],

              // --- ÉTAPE 2 : LA SAISIE PHYSIQUE ---
              if (_currentStep == 2) ...[
                const Text(
                  'Comptage physique',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ouvre ton tiroir-caisse et compte l\'argent réel qui s\'y trouve.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _cashController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Montant compté (FCFA)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(
                      _cashController.text.trim().replaceAll(',', '.'),
                    );
                    if (amount != null && amount >= 0) {
                      setState(() {
                        _physicalCash = amount;
                        _cashGap = amount - dashboardState.calculatedCash;
                        _currentStep = 3;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Saisissez un montant valide et positif.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Calculer l\'écart',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],

              // --- ÉTAPE 3 : LE RÉSULTAT ET LA SENTENCE ---
              if (_currentStep == 3) ...[
                Icon(
                  _cashGap == 0 ? Icons.check_circle : Icons.warning,
                  size: 80,
                  color: _cashGap == 0
                      ? Colors.green
                      : (_cashGap! < 0 ? Colors.orange : Colors.blue),
                ),
                const SizedBox(height: 20),
                Text(
                  _cashGap == 0
                      ? 'Caisse Parfaite !'
                      : (_cashGap! < 0
                            ? 'Il manque de l\'argent'
                            : 'Surplus en caisse'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _cashGap == 0
                        ? Colors.green
                        : (_cashGap! < 0 ? Colors.orange : Colors.blue),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Écart : ${CurrencyFormatter.format(_cashGap!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _cashGap == 0
                      ? 'Tout correspond parfaitement. Bon travail !'
                      : (_cashGap! < 0
                            ? 'Vérifie si tu n\'as pas oublié de noter une sortie de caisse (repas, transport) ou si tu as mal rendu la monnaie.'
                            : 'Tu as plus d\'argent que prévu. As-tu oublié d\'enregistrer une vente dans l\'application ?'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (!await _confirmEarlyClosing()) return;
                          setState(() => _isSaving = true);
                          await ref
                              .read(dashboardProvider.notifier)
                              // Plus de note saisie : personne ne tape une
                              // explication au clavier en fermant sa caisse.
                              // `closeDay` conserve la note existante — c'est
                              // elle qui porte la trace des recomptages, la
                              // seule chose qui empêche de faire disparaître
                              // un manquant en rouvrant la journée.
                              .closeDay(_physicalCash!, null);
                          if (context.mounted) context.go('/home');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cashGap == 0
                        ? Colors.green
                        : (_cashGap! < 0 ? Colors.orange : Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Confirmer et Clôturer la journée',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isNegative
                ? '- ${CurrencyFormatter.format(amount)}'
                : CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

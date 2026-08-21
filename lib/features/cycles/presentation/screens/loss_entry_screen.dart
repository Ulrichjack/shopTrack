import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/cycle_loss_provider.dart';
import '../providers/cycle_provider.dart';
import '../../../../shared/widgets/product_picker.dart';

const _lossReasons = {
  'casse': 'Casse',
  'rongeurs': 'Rongeurs',
  'deterioration': 'Détérioration',
  'autre': 'Autre',
};

class LossEntryScreen extends ConsumerStatefulWidget {
  const LossEntryScreen({super.key});

  @override
  ConsumerState<LossEntryScreen> createState() => _LossEntryScreenState();
}

class _LossEntryScreenState extends ConsumerState<LossEntryScreen> {
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedProductId;
  String _reason = 'casse';
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(String cycleId) async {
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantité invalide'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(cycleLossActionsProvider)
          .addLoss(
            cycleId: cycleId,
            productId: _selectedProductId!,
            quantity: quantity,
            reason: _reason,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perte enregistrée'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Voir `create_cycle_screen` : le sélecteur observe déjà les produits.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Déclarer une perte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductPicker(
                selectedProductId: _selectedProductId,
                onChanged: (value) =>
                    setState(() => _selectedProductId = value),
              ),

              if (_selectedProductId != null)
                Consumer(
                  builder: (context, ref, _) {
                    final cycleAsync = ref.watch(
                      openCycleForProductProvider(_selectedProductId!),
                    );
                    return cycleAsync.when(
                      data: (cycle) {
                        if (cycle == null) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              "Aucun cycle ouvert pour ce produit — crée d'abord un cycle.",
                              style: TextStyle(color: AppColors.error),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              'Quantité perdue (unité de base)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Motif',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _reason,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: _lossReasons.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _reason = value ?? 'casse'),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Note (optionnel)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _submit(cycle.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Enregistrer la perte',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Erreur : $e'),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

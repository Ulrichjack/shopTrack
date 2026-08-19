import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/cycle_provider.dart';
import '../../../../shared/widgets/product_picker.dart';

class CreateCycleScreen extends ConsumerStatefulWidget {
  const CreateCycleScreen({super.key});

  @override
  ConsumerState<CreateCycleScreen> createState() => _CreateCycleScreenState();
}

class _CreateCycleScreenState extends ConsumerState<CreateCycleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _marginController = TextEditingController();

  String? _selectedProductId;
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProductId == null) {
      if (_selectedProductId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choisis un produit'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final margin = _marginController.text.trim().isEmpty
          ? null
          : double.parse(_marginController.text);

      await ref
          .read(cyclesProvider.notifier)
          .createCycle(
            productId: _selectedProductId!,
            quantityReceived: int.parse(_quantityController.text),
            purchaseCost: double.parse(_costController.text),
            referenceMarginPerUnit: margin,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cycle créé avec succès !'),
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
    // `ProductPicker` observe lui-même la liste des produits : la watcher ici
    // en plus ne servait plus qu'à reconstruire tout l'écran à chaque
    // changement de stock, formulaire compris.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nouveau cycle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProductPicker(
                  selectedProductId: _selectedProductId,
                  onChanged: (value) =>
                      setState(() => _selectedProductId = value),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Quantité reçue (unité de base)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Ex: 360'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Obligatoire';
                    if (int.tryParse(value) == null) return 'Nombre entier';
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const Text(
                  "Coût d'achat total (FCFA)",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Ex: 18000'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Obligatoire';
                    if (double.tryParse(value) == null) return 'Montant invalide';
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const Text(
                  'Gain espéré sur tout cet arrivage (optionnel)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sert uniquement à proposer un prix de vente. '
                  'Le bénéfice réel reste calculé sur les ventes effectives.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _marginController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Ex: 6000'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (double.tryParse(value) == null) return 'Montant invalide';
                    return null;
                  },
                ),

                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Créer le cycle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

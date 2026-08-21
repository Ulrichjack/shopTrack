import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/product_unit_provider.dart';
import '../../../../shared/widgets/product_picker.dart';

class ManageUnitsScreen extends ConsumerStatefulWidget {
  const ManageUnitsScreen({super.key});

  @override
  ConsumerState<ManageUnitsScreen> createState() => _ManageUnitsScreenState();
}

class _ManageUnitsScreenState extends ConsumerState<ManageUnitsScreen> {
  String? _selectedProductId;
  final _nameController = TextEditingController();
  final _ratioController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ratioController.dispose();
    super.dispose();
  }

  Future<void> _addUnit() async {
    final productId = _selectedProductId;
    if (productId == null) return;
    final ratio = int.tryParse(_ratioController.text);
    final name = _nameController.text.trim();
    if (name.isEmpty || ratio == null || ratio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom et quantité (nombre positif) obligatoires'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    // Erreur classique : saisir « 30 » comme nom au lieu de « plateau ».
    // On refuse, sinon la conversion devient incompréhensible à la vente.
    if (int.tryParse(name) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le nom doit être un mot (plateau, carton…), pas un nombre.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await ref
          .read(productUnitActionsProvider)
          .addUnit(
            productId: productId,
            unitName: _nameController.text.trim(),
            ratioToBase: ratio,
          );
      _nameController.clear();
      _ratioController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unité ajoutée'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(LocalProductUnit unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${unit.unitName} » ?'),
        content: Text(
          '1 ${unit.unitName} = ${unit.ratioToBase} unité(s) de base.',
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
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(productUnitActionsProvider)
          .deleteUnit(unitId: unit.id, productId: unit.productId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final nameTyped = _nameController.text.trim();
    final ratioTyped = int.tryParse(_ratioController.text) ?? 0;
    final productName =
        productsAsync.value
            ?.where((p) => p.id == _selectedProductId)
            .map((p) => p.name)
            .firstOrNull ??
        'unités';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Unités des produits')),
      // Tout l'écran défile : sinon le clavier réduit la hauteur disponible
      // et le formulaire du bas devient inaccessible (débordement).
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Le même sélecteur que la vente, l'arrivage et la déclaration de
              // perte. Cet écran-ci était resté sur une liste déroulante
              // native : elle n'affiche ni le stock ni la recherche, et sur un
              // petit écran il faut faire défiler tout le catalogue pour
              // retrouver le produit qu'on manipule tous les jours.
              ProductPicker(
                selectedProductId: _selectedProductId,
                onChanged: (value) =>
                    setState(() => _selectedProductId = value),
              ),
              const SizedBox(height: 20),
              if (_selectedProductId != null) ...[
                Consumer(
                  builder: (context, ref, _) {
                    final unitsAsync = ref.watch(
                      productUnitsProvider(_selectedProductId!),
                    );
                    return unitsAsync.when(
                      data: (units) => units.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Aucune unité. Commence par la plus petite '
                                '— celle que tu vends à l\'unité — avec '
                                'une quantité de 1. Les autres (plateau, '
                                'carton…) s\'ajoutent après.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: units.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final unit = units[index];
                                return ListTile(
                                  title: Text(unit.unitName),
                                  subtitle: Text(
                                    '1 ${unit.unitName} = '
                                    '${unit.ratioToBase} $productName',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () => _confirmDelete(unit),
                                  ),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Erreur : $e'),
                    );
                  },
                ),
                const Divider(height: 32),
                const Text(
                  'Ajouter une unité',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '1. Comment tu appelles ce paquet ?',
                    hintText: 'plateau, carton, casier…',
                    helperText: 'Un mot, pas un nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ratioController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    // Formulé avec le nom réel du produit : « unité de base »
                    // ne veut rien dire pour un commerçant.
                    labelText: nameTyped.isEmpty
                        ? '2. Ça contient combien de « $productName » ?'
                        : '2. 1 $nameTyped contient combien de « $productName » ?',
                    hintText: '30',
                    border: const OutlineInputBorder(),
                  ),
                ),
                // Relecture en français avant validation : c'est ce qui évite
                // de créer une unité « 30 » qui vaut en réalité 360.
                if (nameTyped.isNotEmpty && ratioTyped > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '1 $nameTyped = $ratioTyped $productName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        fontSize: 17,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addUnit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Ajouter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/inventory_loss_provider.dart';

/// Déclarer ce qui est sorti du stock sans être vendu.
///
/// Sans cet écran, la casse tombe dans l'écart inexpliqué du rapport et l'app
/// laisse croire à un vol. C'est la différence entre « il manque 22 500 F » et
/// « tu as cassé 3 bouteilles ».
class DeclareLossScreen extends ConsumerStatefulWidget {
  const DeclareLossScreen({super.key});

  @override
  ConsumerState<DeclareLossScreen> createState() => _DeclareLossScreenState();
}

class _DeclareLossScreenState extends ConsumerState<DeclareLossScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  String? _productId;
  String _reason = 'casse';
  DateTime _occurredAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      // Une perte se déclare souvent le lendemain, jamais à l'avance.
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(inventoryLossActionsProvider)
          .declareLoss(
            productId: _productId!,
            quantity: int.parse(_quantityController.text.trim()),
            reason: _reason,
            occurredAt: _occurredAt,
            note: _noteController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanSyncError(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider).value ?? const [];
    final losses = ref.watch(inventoryLossesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Déclarer une perte')),
      body: SafeArea(
        // Formulaire scrollable : le clavier mange la moitié de la hauteur sur
        // un petit écran, et le bouton doit rester atteignable.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _productId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Produit',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _productId = value),
                    validator: (value) =>
                        value == null ? 'Choisis un produit' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Combien ?',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      final quantity = int.tryParse((value ?? '').trim());
                      if (quantity == null || quantity <= 0) {
                        return 'Saisis un nombre supérieur à zéro';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pourquoi ?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: inventoryLossReasons.entries
                        .map(
                          (entry) => ChoiceChip(
                            label: Text(entry.value),
                            selected: _reason == entry.key,
                            onSelected: (_) =>
                                setState(() => _reason = entry.key),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: Text(DateFormat('dd/MM/yyyy').format(_occurredAt)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _pickDate,
                  ),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (facultatif)',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'DÉJÀ DÉCLARÉ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            losses.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(humanSyncError(error)),
              data: (entries) => entries.isEmpty
                  ? const Text(
                      'Aucune perte déclarée.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < entries.length; i++) ...[
                            ListTile(
                              title: Text(entries[i].productName),
                              subtitle: Text(
                                '${entries[i].reasonLabel} · '
                                '${DateFormat('dd/MM').format(entries[i].loss.occurredAt)}',
                              ),
                              trailing: Text(
                                '${entries[i].loss.quantity}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (i < entries.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

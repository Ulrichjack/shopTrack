import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/inventory_loss_provider.dart';
import '../../../../shared/widgets/product_picker.dart';

/// Ouvre la déclaration de perte en feuille, comme « Nouvel arrivage ».
///
/// Une page entière pour trois champs coupait le commerçant de son écran
/// Inventaire ; la feuille se referme et il est resté où il était.
Future<void> showDeclareLossSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const DeclareLossScreen(),
  );
}

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

  ProductEntity? _product;
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
    // Le sélecteur partagé ne s'intègre pas au FormField : la présence d'un
    // produit se vérifie donc ici, avant le reste du formulaire — comme sur
    // l'écran de cycle qui utilise le même widget.
    if (_product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisis un produit'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(inventoryLossActionsProvider)
          .declareLoss(
            productId: _product!.id,
            quantity: int.parse(_quantityController.text.trim()),
            reason: _reason,
            occurredAt: _occurredAt,
            note: _noteController.text,
          );
      if (!mounted) return;
      // On reste dans la feuille : le commerçant fait son tour et constate
      // plusieurs pertes d'affilée. La perte qui apparaît dans la liste juste
      // en dessous suffit à confirmer l'enregistrement — pas besoin d'un
      // message, comme au comptage.
      setState(() {
        _quantityController.clear();
        _noteController.clear();
        _product = null;
        _formKey.currentState?.reset();
      });
      FocusScope.of(context).unfocus();
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

    return Padding(
      // Le clavier remonte la feuille, sinon il recouvre le bouton.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        // Formulaire scrollable : le clavier mange la moitié de la hauteur sur
        // un petit écran, et le bouton doit rester atteignable.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Déclarer une perte',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Le sélecteur partagé (comptage, cycles, transferts) : une
                  // copie privée vivait ici, avec son propre code de
                  // recherche à maintenir en double pour rien.
                  ProductPicker(
                    selectedProductId: _product?.id,
                    onChanged: (id) => setState(() {
                      _product = products.where((p) => p.id == id).firstOrNull;
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Combien ?',
                      // Dire d'où sort ce nombre. « Maximum 30 » ressemblait
                      // à une limite arbitraire ; c'est le stock que l'app
                      // croit avoir, et en mode inventaire il est TOUJOURS
                      // généreux — les ventes ne le décrémentent pas, seuls un
                      // comptage, une perte ou un transfert le font bouger. Il
                      // ne bloque donc pas une casse réelle : il arrête une
                      // faute de frappe (200 pour 20), qui effacerait des
                      // ventes du rapport et inventerait un excédent de caisse.
                      helperText: _product == null
                          ? null
                          : 'Il en reste ${_product!.quantity} d\'après l\'app',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      final quantity = int.tryParse((value ?? '').trim());
                      if (quantity == null || quantity <= 0) {
                        return 'Saisis un nombre supérieur à zéro';
                      }
                      // Perdre plus que ce qui a pu exister est impossible ;
                      // et une perte gonflée efface des ventes réelles du
                      // rapport, donc invente un excédent de caisse.
                      final max = _product?.quantity;
                      if (max != null && quantity > max) {
                        return 'Tu n\'en as que $max en stock';
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
              loading: () => const Center(child: CircularProgressIndicator()),
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

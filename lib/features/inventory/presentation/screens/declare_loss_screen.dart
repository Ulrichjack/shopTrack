import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/inventory_loss_provider.dart';

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

  /// Liste cherchable en feuille : elle occupe l'écran le temps du choix puis
  /// disparaît, au lieu d'allonger un formulaire déjà long.
  Future<ProductEntity?> _pickProduct(List<ProductEntity> products) {
    return showModalBottomSheet<ProductEntity>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProductPicker(products: products),
    );
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
                  // Un menu déroulant devient inutilisable passé une dizaine
                  // de produits : on ouvre une liste cherchable, comme au
                  // comptage. Le champ reste un champ de formulaire pour
                  // garder la validation.
                  FormField<String>(
                    initialValue: _product?.id,
                    validator: (value) =>
                        value == null ? 'Choisis un produit' : null,
                    builder: (field) => InkWell(
                      onTap: () async {
                        final chosen = await _pickProduct(products);
                        if (chosen == null) return;
                        setState(() => _product = chosen);
                        field.didChange(chosen.id);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Produit',
                          filled: true,
                          fillColor: Colors.white,
                          errorText: field.errorText,
                          suffixIcon: const Icon(Icons.search),
                        ),
                        child: Text(
                          _product?.name ?? 'Choisir un produit',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _product == null
                                ? Colors.grey.shade600
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Combien ?',
                      helperText: _product == null
                          ? null
                          : 'Maximum ${_product!.quantity}',
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
                        return 'Pas plus de $max';
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

/// Sélecteur de produit avec recherche, repris du geste du comptage : on tape
/// les premières lettres plutôt que de faire défiler vingt lignes.
class _ProductPicker extends StatefulWidget {
  const _ProductPicker({required this.products});

  final List<ProductEntity> products;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.products
        .where((p) => _query.isEmpty || p.name.toLowerCase().contains(_query))
        .toList();

    return Padding(
      // Le clavier remonte la feuille : sans ça il masque la liste filtrée.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('Aucun produit ne correspond.'))
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) => ListTile(
                        title: Text(visible[index].name),
                        subtitle: (visible[index].unit ?? '').trim().isEmpty
                            ? null
                            : Text(visible[index].unit!.trim()),
                        onTap: () => Navigator.of(context).pop(visible[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

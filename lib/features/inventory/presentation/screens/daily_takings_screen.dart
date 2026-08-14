import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/takings_provider.dart';

class DailyTakingsScreen extends ConsumerStatefulWidget {
  const DailyTakingsScreen({super.key});

  @override
  ConsumerState<DailyTakingsScreen> createState() => _DailyTakingsScreenState();
}

class _DailyTakingsScreenState extends ConsumerState<DailyTakingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSaving = false;
  bool _amountInitialized = false;

  /// Jour saisi. Modifiable : oublier un soir arrive, et sans possibilité de
  /// rattraper, la journée manquante ressemble à un manquant d'argent dans le
  /// rapport — quelqu'un finirait par être soupçonné pour un simple oubli.
  DateTime? _selectedDate;

  DateTime get _today {
    final now = DateTime.now();
    return _selectedDate ?? DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _today,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Recette de quel jour ?',
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      _amountInitialized = false;
      _amountController.clear();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    setState(() => _isSaving = true);

    try {
      await ref
          .read(takingActionsProvider)
          .saveTaking(date: _today, amount: amount);
      if (!mounted) return;

      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recette du jour enregistrée'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanSyncError(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final takingsAsync = ref.watch(takingsProvider);
    final takings = takingsAsync.value ?? const <LocalShopTaking>[];
    final todayTaking = _takingForDate(takings, _today);

    if (!_amountInitialized && todayTaking != null) {
      _amountInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _amountController.text.isEmpty) {
          _amountController.text = todayTaking.amount.toStringAsFixed(0);
        }
      });
    }

    final previousTakings = takings
        .where((taking) => !_isSameDay(taking.date, _today))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recette journalière')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(takingsProvider);
            await ref.read(takingsProvider.future);
          },
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              _TakingFormCard(
                formKey: _formKey,
                amountController: _amountController,
                date: _today,
                isCorrection: todayTaking != null,
                isSaving: _isSaving,
                onSave: _save,
                onChangeDate: _pickDate,
              ),
              const SizedBox(height: 28),
              const Text(
                'Jours précédents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              takingsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (error, _) => _HistoryError(
                  message: humanSyncError(error),
                  onRetry: () => ref.invalidate(takingsProvider),
                ),
                data: (_) => previousTakings.isEmpty
                    ? const _EmptyHistory()
                    : Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < previousTakings.length;
                              index++
                            ) ...[
                              _TakingHistoryTile(
                                taking: previousTakings[index],
                              ),
                              if (index < previousTakings.length - 1)
                                const Divider(height: 1, indent: 56),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TakingFormCard extends StatelessWidget {
  const _TakingFormCard({
    required this.formKey,
    required this.amountController,
    required this.date,
    required this.isCorrection,
    required this.isSaving,
    required this.onSave,
    required this.onChangeDate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final DateTime date;
  final bool isCorrection;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onChangeDate;

  static bool _estAujourdhui(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estAujourdhui(date)
                              ? 'Combien as-tu encaissé aujourd’hui ?'
                              : 'Recette d’un jour passé',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        InkWell(
                          onTap: onChangeDate,
                          child: Row(
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(date),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit_calendar_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: amountController,
                autofocus: false,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (_) {
                  if (!isSaving) onSave();
                },
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  labelText: 'Recette du jour',
                  suffixText: 'FCFA',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Saisis le montant encaissé aujourd’hui.';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount < 0) {
                    return 'Saisis un montant FCFA valide.';
                  }
                  return null;
                },
              ),
              if (isCorrection) ...[
                const SizedBox(height: 10),
                const Text(
                  'Une recette existe déjà aujourd’hui. Enregistrer remplace '
                  'son montant sans créer de doublon.',
                  style: TextStyle(color: AppColors.warningDark, fontSize: 13),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isCorrection ? Icons.edit_outlined : Icons.save),
                label: Text(
                  isSaving
                      ? 'Enregistrement…'
                      : isCorrection
                      ? 'Corriger la recette'
                      : 'Enregistrer la recette',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TakingHistoryTile extends StatelessWidget {
  const _TakingHistoryTile({required this.taking});

  final LocalShopTaking taking;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(DateFormat('dd/MM/yyyy').format(taking.date)),
      trailing: Text(
        CurrencyFormatter.format(taking.amount),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 34,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'Aucune recette précédente.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Les journées enregistrées apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

LocalShopTaking? _takingForDate(List<LocalShopTaking> takings, DateTime date) {
  for (final taking in takings) {
    if (_isSameDay(taking.date, date)) return taking;
  }
  return null;
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

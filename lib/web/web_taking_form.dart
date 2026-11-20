import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_mode_data.dart';
import 'web_theme.dart';

class WebTakingForm extends StatefulWidget {
  const WebTakingForm({
    super.key,
    required this.shopId,
    this.dateInitiale,
    this.montantInitial,
  });

  final String shopId;
  final DateTime? dateInitiale;
  final int? montantInitial;

  @override
  State<WebTakingForm> createState() => _WebTakingFormState();
}

class _WebTakingFormState extends State<WebTakingForm> {
  late DateTime _date = widget.dateInitiale ?? DateTime.now();
  late final TextEditingController _montant = TextEditingController(
    text: widget.montantInitial?.toString() ?? '',
  );
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _montant.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _enregistrer() async {
    if (_enCours) return;
    final montant = int.tryParse(_montant.text.trim());
    if (montant == null || montant < 0) {
      setState(
        () => _erreur = 'Entre un montant entier en FCFA, positif ou zéro.',
      );
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final client = Supabase.instance.client;
    try {
      await enregistrerRecetteWeb(
        client,
        shopId: widget.shopId,
        date: _date,
        montant: montant,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // La réponse peut être perdue après l'écriture. Relire avant de proposer
      // une nouvelle tentative évite d'annoncer un échec déjà enregistré.
      try {
        final jour = DateFormat('yyyy-MM-dd').format(_date);
        final actuelle = await client
            .from('shop_takings')
            .select('amount')
            .eq('shop_id', widget.shopId)
            .eq('date', jour)
            .maybeSingle();
        if (actuelle != null &&
            (actuelle['amount'] as num).round() == montant) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Réseau encore indisponible : conserver le formulaire pour réessayer.
      }
      if (mounted) {
        setState(
          () => _erreur =
              'Enregistrement non confirmé. Vérifie Internet puis réessaie.',
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24,
      22,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.montantInitial == null
              ? 'Noter une recette'
              : 'Corriger la recette',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Montant réellement encaissé pendant cette journée.',
          style: TextStyle(color: WebPalette.muted),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _enCours ? null : _choisirDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(DateFormat('dd/MM/yyyy').format(_date)),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: _montant,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Recette (FCFA)',
            hintText: 'Ex. 25000',
          ),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 12),
          Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
        ],
        const SizedBox(height: 21),
        FilledButton(
          onPressed: _enCours ? null : _enregistrer,
          child: Text(_enCours ? 'Enregistrement…' : 'Enregistrer la recette'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _enCours ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
      ],
    ),
  );
}

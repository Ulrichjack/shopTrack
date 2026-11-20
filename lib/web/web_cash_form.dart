import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'web_theme.dart';

class WebCashForm extends StatefulWidget {
  const WebCashForm({
    super.key,
    required this.shopId,
    required this.estPatron,
    required this.soldeInitial,
  });

  final String shopId;
  final bool estPatron;
  final bool soldeInitial;

  @override
  State<WebCashForm> createState() => _WebCashFormState();
}

class _WebCashFormState extends State<WebCashForm> {
  final _id = const Uuid().v4();
  final _montant = TextEditingController();
  final _note = TextEditingController();
  String _categorie = 'Repas';
  bool _enCours = false;
  String? _erreur;

  List<String> get _categories => [
    'Repas',
    'Transport',
    'Fournisseur',
    'Personnel',
    'Autre',
    'Versement banque',
    widget.estPatron ? 'Retrait patron' : 'Remise à la patronne',
  ];

  @override
  void dispose() {
    _montant.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_enCours) return;
    final montant = int.tryParse(_montant.text.trim());
    if (montant == null || montant < (widget.soldeInitial ? 0 : 1)) {
      setState(() => _erreur = widget.soldeInitial
          ? 'Entre un montant positif ou zéro.'
          : 'Entre un montant supérieur à zéro.');
      return;
    }
    final client = Supabase.instance.client;
    final utilisateur = client.auth.currentUser;
    if (utilisateur == null) {
      setState(() => _erreur = 'Reconnecte-toi avant d’enregistrer.');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await client.from('cash_movements').insert({
        'id': _id,
        'shop_id': widget.shopId,
        'user_id': utilisateur.id,
        'amount': montant,
        'type': widget.soldeInitial ? 'morning_balance' : 'withdrawal',
        'category': widget.soldeInitial ? 'Solde initial' : _categorie,
        'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      try {
        final ligne = await client
            .from('cash_movements')
            .select('id')
            .eq('id', _id)
            .eq('shop_id', widget.shopId)
            .maybeSingle();
        if (ligne != null) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Réseau encore absent : garder le formulaire et son UUID.
      }
      if (mounted) {
        setState(() => _erreur =
            'Mouvement non confirmé. Vérifie Internet puis réessaie.');
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24,
      20,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.soldeInitial ? 'Solde de départ' : 'Sortie de caisse',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(widget.soldeInitial
            ? 'Montant présent dans le tiroir avant la première opération.'
            : 'Indique pourquoi l’argent sort du tiroir. Le journal garde cette trace.'),
        const SizedBox(height: 18),
        TextField(
          controller: _montant,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
        ),
        if (!widget.soldeInitial) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _categorie,
            decoration: const InputDecoration(labelText: 'Motif'),
            items: [
              for (final categorie in _categories)
                DropdownMenuItem(value: categorie, child: Text(categorie)),
            ],
            onChanged: (valeur) {
              if (valeur != null) setState(() => _categorie = valeur);
            },
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _note,
          maxLength: 250,
          decoration: const InputDecoration(labelText: 'Note (facultatif)'),
        ),
        if (_erreur != null)
          Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _enCours ? null : _enregistrer,
          icon: const Icon(Icons.save_outlined),
          label: Text(_enCours ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ],
    ),
  );
}

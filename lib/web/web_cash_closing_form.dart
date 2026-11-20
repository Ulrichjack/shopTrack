import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'web_theme.dart';
import 'web_cameroun_time.dart';

class WebCashClosingForm extends StatefulWidget {
  const WebCashClosingForm({super.key, required this.shopId,
    required this.soldeCalcule});

  final String shopId;
  final int soldeCalcule;

  @override
  State<WebCashClosingForm> createState() => _WebCashClosingFormState();
}

class _WebCashClosingFormState extends State<WebCashClosingForm> {
  String _id = const Uuid().v4();
  final _montant = TextEditingController();
  final _note = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _montant.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _cloturer() async {
    final reel = int.tryParse(_montant.text.trim());
    if (reel == null || reel < 0) {
      setState(() => _erreur = 'Compte le tiroir et entre un montant valide.');
      return;
    }
    if (_enCours) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final client = Supabase.instance.client;
    try {
      final jour = dateCamerounMaintenant();
      final date = '${jour.year}-${jour.month.toString().padLeft(2, '0')}-${jour.day.toString().padLeft(2, '0')}';
      final existante = await client.from('daily_closings')
          .select('id,is_closed')
          .eq('shop_id', widget.shopId)
          .eq('closing_date', date)
          .maybeSingle();
      if (existante != null) {
        if (existante['is_closed'] == true && existante['id'] != _id) {
          throw StateError('Cette journée est déjà clôturée. Actualise la caisse.');
        }
        _id = existante['id'] as String;
      }
      await client.rpc('web_close_simple_day', params: {
        'p_shop_id': widget.shopId,
        'p_closing_id': _id,
        'p_physical_cash': reel,
        'p_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (erreur) {
      try {
        final confirme = await client.from('daily_closings')
            .select('id,is_closed').eq('id', _id).eq('shop_id', widget.shopId)
            .maybeSingle();
        if (confirme?['is_closed'] == true) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Une nouvelle tentative réutilisera le même identifiant.
      }
      if (mounted) setState(() => _erreur =
          erreur is PostgrestException && erreur.code == '23505'
              ? 'Cette journée est déjà clôturée. Actualise la caisse.'
              : erreur is StateError
              ? erreur.message
              : erreur is PostgrestException &&
                  erreur.message.contains('solde initial')
              ? 'Définis le solde initial dans la caisse avant de clôturer.'
              : 'Clôture non confirmée. Vérifie Internet puis réessaie.');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(24, 20, 24,
      MediaQuery.viewInsetsOf(context).bottom + 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Clôturer la journée', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Compte les espèces réellement présentes dans le tiroir. '
            'Le serveur recalculera le solde théorique et gardera l’écart.'),
        const SizedBox(height: 12),
        Text('Solde affiché avant comptage : ${widget.soldeCalcule} FCFA',
            style: const TextStyle(color: WebPalette.muted)),
        const SizedBox(height: 18),
        TextField(
          controller: _montant,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Montant compté (FCFA)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Note (facultatif)'),
        ),
        if (_erreur != null)
          Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _enCours ? null : _cloturer,
          icon: const Icon(Icons.task_alt_outlined),
          label: Text(_enCours ? 'Clôture…' : 'Enregistrer la clôture'),
        ),
      ],
    ),
  );
}

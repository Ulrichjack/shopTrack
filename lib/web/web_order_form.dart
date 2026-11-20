import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'web_theme.dart';

/// Même geste que sur Android : créer le client, puis le dossier. Les UUID
/// restent fixes pendant les nouvelles tentatives si une réponse se perd.
class WebOrderForm extends StatefulWidget {
  const WebOrderForm({
    super.key,
    required this.shopId,
    required this.estPatron,
  });
  final String shopId;
  final bool estPatron;

  @override
  State<WebOrderForm> createState() => _WebOrderFormState();
}

class _WebOrderFormState extends State<WebOrderForm> {
  final _clientId = const Uuid().v4();
  final _dossierId = const Uuid().v4();
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _description = TextEditingController();
  final _montant = TextEditingController();
  String _categorie = 'gateau';
  DateTime? _datePrevue;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    _description.dispose();
    _montant.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _datePrevue ?? maintenant,
      firstDate: DateTime(maintenant.year, maintenant.month, maintenant.day),
      lastDate: DateTime(maintenant.year + 2),
    );
    if (date != null && mounted) setState(() => _datePrevue = date);
  }

  Future<void> _enregistrer() async {
    if (_enCours || !_form.currentState!.validate()) return;
    final montant = widget.estPatron && _montant.text.trim().isNotEmpty
        ? int.parse(_montant.text.trim())
        : null;
    final client = Supabase.instance.client;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final clientExistant = await client
          .from('clients')
          .select('id')
          .eq('shop_id', widget.shopId)
          .eq('id', _clientId)
          .maybeSingle();
      if (clientExistant == null) {
        await client.from('clients').insert({
          'id': _clientId,
          'shop_id': widget.shopId,
          'nom': _nom.text.trim(),
          'telephone': _telephone.text.trim().isEmpty
              ? null
              : _telephone.text.trim(),
        });
      }
      final dossierExistant = await client
          .from('dossiers_commandes')
          .select('id')
          .eq('shop_id', widget.shopId)
          .eq('id', _dossierId)
          .maybeSingle();
      if (dossierExistant == null) {
        await client.from('dossiers_commandes').insert({
          'id': _dossierId,
          'shop_id': widget.shopId,
          'client_id': _clientId,
          'categorie': _categorie,
          'description': _description.text.trim(),
          'date_prevue': _datePrevue?.toUtc().toIso8601String(),
          'montant_accepte': montant,
          'statut': montant == null ? 'demande' : 'confirmee',
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      // Un client peut déjà avoir été créé. Garder le formulaire et les mêmes
      // IDs permet de terminer la demande en réessayant sans doublon.
      setState(
        () => _erreur =
            'Demande non confirmée. Vérifie Internet puis réessaie ; les informations saisies sont conservées.',
      );
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
    child: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nouvelle commande',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            widget.estPatron
                ? 'Enregistre la demande et fixe le prix si tu le connais.'
                : 'Enregistre la demande ; le propriétaire fixera le prix.',
            style: const TextStyle(color: WebPalette.muted),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nom,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nom du client *'),
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Entre le nom du client.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telephone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone (facultatif)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categorie,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: const [
              DropdownMenuItem(value: 'gateau', child: Text('Gâteau')),
              DropdownMenuItem(
                value: 'objet_decoratif',
                child: Text('Objet décoratif'),
              ),
              DropdownMenuItem(value: 'formation', child: Text('Formation')),
              DropdownMenuItem(
                value: 'decoration_evenementielle',
                child: Text('Décoration événementielle'),
              ),
            ],
            onChanged: _enCours
                ? null
                : (v) {
                    if (v != null) setState(() => _categorie = v);
                  },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Ce que demande le client *',
            ),
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Décris la demande.' : null,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _enCours ? null : _choisirDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _datePrevue == null
                  ? 'Date prévue (facultative)'
                  : DateFormat('dd/MM/yyyy').format(_datePrevue!),
            ),
          ),
          if (widget.estPatron) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _montant,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prix accepté (FCFA, facultatif)',
              ),
              validator: (v) {
                final texte = v?.trim() ?? '';
                if (texte.isEmpty) return null;
                final montant = int.tryParse(texte);
                return montant == null || montant < 0
                    ? 'Entre un montant entier positif ou zéro.'
                    : null;
              },
            ),
          ],
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _enCours ? null : _enregistrer,
            child: Text(
              _enCours ? 'Enregistrement…' : 'Enregistrer la demande',
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _enCours ? null : () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_theme.dart';

/// Le prix accepté est une seule écriture sur le dossier. Les garde-fous du
/// serveur vérifient aussi les paiements déjà enregistrés.
class WebOrderPriceForm extends StatefulWidget {
  const WebOrderPriceForm({
    super.key,
    required this.shopId,
    required this.dossier,
  });

  final String shopId;
  final Map<String, dynamic> dossier;

  @override
  State<WebOrderPriceForm> createState() => _WebOrderPriceFormState();
}

class _WebOrderPriceFormState extends State<WebOrderPriceForm> {
  late final TextEditingController _prix = TextEditingController(
    text: (widget.dossier['montant_accepte'] as num?)?.round().toString() ?? '',
  );
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _prix.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_enCours) return;
    final montant = int.tryParse(_prix.text.trim());
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
    final id = widget.dossier['id'] as String;
    try {
      final actuel = await client
          .from('dossiers_commandes')
          .select('id,montant_accepte,statut')
          .eq('id', id)
          .eq('shop_id', widget.shopId)
          .maybeSingle();
      if (actuel == null ||
          actuel['statut'] == 'annulee' ||
          actuel['statut'] == 'terminee') {
        throw StateError('Cette commande ne peut plus être modifiée.');
      }
      final miseAJour = <String, dynamic>{'montant_accepte': montant};
      if (actuel['statut'] == 'demande' || actuel['statut'] == 'devis') {
        miseAJour['statut'] = 'confirmee';
      }
      final resultat = await client
          .from('dossiers_commandes')
          .update(miseAJour)
          .eq('id', id)
          .eq('shop_id', widget.shopId)
          .select('id')
          .maybeSingle();
      if (resultat == null) throw StateError('Modification non autorisée.');
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // Une réponse perdue n'est pas nécessairement un échec. Le prix relu
      // évite de présenter un échec alors que la nouvelle valeur est stockée.
      try {
        final actuel = await client
            .from('dossiers_commandes')
            .select('montant_accepte')
            .eq('id', id)
            .eq('shop_id', widget.shopId)
            .maybeSingle();
        if ((actuel?['montant_accepte'] as num?)?.round() == montant) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Le réseau n'est pas revenu : garder la valeur saisie.
      }
      if (mounted) {
        setState(
          () => _erreur =
              'Prix non confirmé. Vérifie les paiements et Internet, puis actualise.',
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
      20,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Prix de la commande',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          widget.dossier['description'] as String? ?? 'Commande',
          style: const TextStyle(color: WebPalette.muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _prix,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Prix accepté (FCFA)'),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 12),
          Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
        ],
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _enCours ? null : _enregistrer,
          child: Text(_enCours ? 'Enregistrement…' : 'Enregistrer le prix'),
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

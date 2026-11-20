import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'web_theme.dart';

/// Approvisionnement du mode simple, rejouable avec le même identifiant.
class WebStockRechargeForm extends StatefulWidget {
  const WebStockRechargeForm({
    super.key,
    required this.shopId,
    required this.produit,
  });

  final String shopId;
  final Map<String, dynamic> produit;

  @override
  State<WebStockRechargeForm> createState() => _WebStockRechargeFormState();
}

class _WebStockRechargeFormState extends State<WebStockRechargeForm> {
  final _id = const Uuid().v4();
  final _quantite = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _quantite.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final nombre = int.tryParse(_quantite.text.trim());
    if (nombre == null || nombre <= 0) {
      setState(() => _erreur = 'Entre une quantité supérieure à zéro.');
      return;
    }
    if (_enCours) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await Supabase.instance.client.rpc('apply_stock_movement', params: {
        'p_movement_id': _id,
        'p_shop_id': widget.shopId,
        'p_product_id': widget.produit['id'],
        'p_quantity_delta': nombre,
        'p_type': 'recharge',
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      try {
        final mouvement = await Supabase.instance.client
            .from('stock_movements')
            .select('id')
            .eq('id', _id)
            .eq('shop_id', widget.shopId)
            .maybeSingle();
        if (mouvement != null) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Garder l'identifiant pour une nouvelle tentative sans double stock.
      }
      if (mounted) {
        setState(() => _erreur =
            'Approvisionnement non confirmé. Vérifie Internet puis réessaie.');
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ajouter du stock', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(widget.produit['name'] as String? ?? 'Produit'),
        const SizedBox(height: 18),
        TextField(
          controller: _quantite,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Quantité reçue'),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 12),
          Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _enCours ? null : _enregistrer,
          icon: const Icon(Icons.add_box_outlined),
          label: Text(_enCours ? 'Enregistrement…' : 'Ajouter au stock'),
        ),
      ],
    ),
  );
}

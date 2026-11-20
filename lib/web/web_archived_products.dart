import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_theme.dart';

class WebArchivedProducts extends StatefulWidget {
  const WebArchivedProducts({super.key, required this.shopId});
  final String shopId;

  @override
  State<WebArchivedProducts> createState() => _WebArchivedProductsState();
}

class _WebArchivedProductsState extends State<WebArchivedProducts> {
  List<Map<String, dynamic>> _produits = [];
  bool _charge = false;
  bool _modifie = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    try {
      final produits = await Supabase.instance.client.from('products')
          .select('id,name,quantity,archived_at')
          .eq('shop_id', widget.shopId)
          .not('archived_at', 'is', null)
          .order('name');
      if (mounted) setState(() => _produits = produits);
    } catch (_) {
      if (mounted) setState(() => _erreur = 'Archives indisponibles. Réessaie.');
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _restaurer(Map<String, dynamic> produit) async {
    try {
      final resultat = await Supabase.instance.client.from('products')
          .update({'archived_at': null})
          .eq('shop_id', widget.shopId)
          .eq('id', produit['id'] as String)
          .select('id').maybeSingle();
      if (resultat == null) throw StateError('Restauration non confirmée.');
      _modifie = true;
      await _charger();
    } catch (_) {
      if (mounted) setState(() => _erreur =
          'Restauration non confirmée. Vérifie Internet puis réessaie.');
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: Text('Produits archivés',
              style: Theme.of(context).textTheme.headlineSmall)),
          IconButton(onPressed: () => Navigator.of(context).pop(_modifie),
              tooltip: 'Fermer', icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 8),
        const Text('Une restauration remet le produit dans le catalogue. '
            'Son ancien historique est conservé.'),
        if (_charge) const LinearProgressIndicator(),
        if (_erreur != null) Text(_erreur!,
            style: const TextStyle(color: WebPalette.danger)),
        const SizedBox(height: 12),
        Flexible(child: ListView(
          shrinkWrap: true,
          children: [
            if (!_charge && _produits.isEmpty)
              const ListTile(title: Text('Aucun produit archivé.')),
            for (final produit in _produits)
              ListTile(
                title: Text(produit['name'] as String? ?? 'Produit'),
                subtitle: Text('Stock conservé : ${produit['quantity']}'),
                trailing: TextButton.icon(
                  onPressed: () => _restaurer(produit),
                  icon: const Icon(Icons.unarchive_outlined),
                  label: const Text('Restaurer'),
                ),
              ),
          ],
        )),
      ],
    ),
  );
}

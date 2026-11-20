import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../features/products/presentation/screens/barcode_scanner_screen.dart';
import 'web_product_detail.dart';
import 'web_theme.dart';

class _LignePanier {
  const _LignePanier(this.produit, this.quantite, this.prix);
  final Map<String, dynamic> produit;
  final int quantite;
  final int prix;
}

/// Vente connectée du mode simple. Le serveur calcule seul le coût et le
/// bénéfice, verrouille le stock et écrit les lignes dans une transaction.
class WebSimpleSaleForm extends StatefulWidget {
  const WebSimpleSaleForm({
    super.key,
    required this.shopId,
    required this.produits,
  });

  final String shopId;
  final List<Map<String, dynamic>> produits;

  @override
  State<WebSimpleSaleForm> createState() => _WebSimpleSaleFormState();
}

class _WebSimpleSaleFormState extends State<WebSimpleSaleForm> {
  final _recherche = TextEditingController();
  final _panier = <String, _LignePanier>{};
  final _saleId = const Uuid().v4();
  bool _enCours = false;
  bool _panierVerrouille = false;
  String? _erreur;

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  String _fcfa(int montant) =>
      '${NumberFormat.decimalPattern('fr_FR').format(montant)} FCFA';

  Future<void> _scanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (mounted && code != null && code.trim().isNotEmpty) {
      setState(() => _recherche.text = code.trim());
    }
  }

  Future<void> _choisir(Map<String, dynamic> produit) async {
    if (_panierVerrouille) return;
    final id = produit['id'] as String;
    final disponible = (produit['quantity'] as num?)?.toInt() ?? 0;
    if (disponible <= 0) return;
    final existante = _panier[id];
    final quantite = TextEditingController(
      text: (existante?.quantite ?? 1).toString(),
    );
    final prix = TextEditingController(
      text: (existante?.prix ?? (produit['sell_price'] as num).round())
          .toString(),
    );
    String? erreur;
    final choix = await showDialog<(int, int)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, changer) => AlertDialog(
          title: Text(produit['name'] as String? ?? 'Produit'),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 155,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: WebPalette.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WebPalette.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: WebProductPhoto(
                  url: produit['photo_url'] as String?,
                  fit: BoxFit.contain,
                  iconSize: 50,
                ),
              ),
              const SizedBox(height: 12),
              Text('Disponible : $disponible'),
              const SizedBox(height: 14),
              TextField(
                controller: quantite,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prix,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Prix de vente par unité (FCFA)',
                ),
              ),
              if (erreur != null) ...[
                const SizedBox(height: 8),
                Text(erreur!, style: const TextStyle(color: WebPalette.danger)),
              ],
            ],
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final q = int.tryParse(quantite.text);
                final p = int.tryParse(prix.text);
                if (q == null ||
                    q < 1 ||
                    q > disponible ||
                    p == null ||
                    p < 0) {
                  changer(
                    () => erreur =
                        'Entre une quantité entre 1 et $disponible et un prix valide.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop((q, p));
              },
              child: const Text('Ajouter au panier'),
            ),
          ],
        ),
      ),
    );
    quantite.dispose();
    prix.dispose();
    if (choix != null && mounted) {
      setState(() => _panier[id] = _LignePanier(produit, choix.$1, choix.$2));
    }
  }

  Future<void> _valider() async {
    if (_enCours || _panier.isEmpty) return;
    setState(() {
      _enCours = true;
      _panierVerrouille = true;
      _erreur = null;
    });
    final client = Supabase.instance.client;
    try {
      await client.rpc(
        'web_create_simple_sale',
        params: {
          'p_shop_id': widget.shopId,
          'p_sale_id': _saleId,
          'p_items': [
            for (final ligne in _panier.values)
              {
                'product_id': ligne.produit['id'],
                'quantity': ligne.quantite,
                'sell_price': ligne.prix,
              },
          ],
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (erreur) {
      try {
        final dejaCree = await client
            .from('sales')
            .select('id')
            .eq('id', _saleId)
            .eq('shop_id', widget.shopId)
            .maybeSingle();
        if (dejaCree != null) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
        if (mounted) setState(() => _panierVerrouille = false);
      } catch (_) {
        // Tant que la confirmation est impossible, garder le même panier et ID.
      }
      if (mounted) {
        setState(
          () => _erreur = erreur is PostgrestException && erreur.code == '23514'
              ? 'Stock insuffisant. Actualise les produits avant de réessayer.'
              : 'Vente non confirmée. Vérifie Internet puis réessaie sans changer le panier.',
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texte = _recherche.text.trim().toLowerCase();
    final visibles = widget.produits
        .where((p) {
          final nom = (p['name'] as String? ?? '').toLowerCase();
          final code = (p['barcode'] as String? ?? '').toLowerCase();
          return nom.contains(texte) || code.contains(texte);
        })
        .take(12)
        .toList();
    final total = _panier.values.fold<int>(
      0,
      (somme, ligne) => somme + ligne.quantite * ligne.prix,
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nouvelle vente',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          const Text('Choisis les produits, puis confirme la vente en ligne.'),
          const SizedBox(height: 16),
          TextField(
            controller: _recherche,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Rechercher un produit ou un code',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Scanner un QR ou code-barres',
                onPressed: _scanner,
                icon: const Icon(Icons.qr_code_scanner),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final produit in visibles)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox.square(
                dimension: 44,
                child: WebProductPhoto(url: produit['photo_url'] as String?),
              ),
              title: Text(produit['name'] as String? ?? 'Produit'),
              subtitle: Text(
                '${_fcfa((produit['sell_price'] as num).round())} · '
                '${produit['quantity']} disponibles',
              ),
              trailing: const Icon(Icons.add_circle_outline),
              enabled:
                  !_panierVerrouille &&
                  ((produit['quantity'] as num?)?.toInt() ?? 0) > 0,
              onTap: () => _choisir(produit),
            ),
          if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun produit trouvé. Essaie le nom ou le code.'),
            ),
          const Divider(height: 28),
          Text(
            'Panier · ${_fcfa(total)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          for (final entree in _panier.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entree.value.produit['name'] as String? ?? 'Produit'),
              subtitle: Text(
                '${entree.value.quantite} × ${_fcfa(entree.value.prix)}',
              ),
              trailing: IconButton(
                tooltip: 'Retirer du panier',
                onPressed: _panierVerrouille
                    ? null
                    : () => setState(() => _panier.remove(entree.key)),
                icon: const Icon(Icons.close),
              ),
              onTap: _panierVerrouille
                  ? null
                  : () => _choisir(entree.value.produit),
            ),
          if (_erreur != null) ...[
            const SizedBox(height: 10),
            Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _panier.isEmpty || _enCours ? null : _valider,
            icon: const Icon(Icons.check),
            label: Text(_enCours ? 'Enregistrement…' : 'Confirmer la vente'),
          ),
        ],
      ),
    );
  }
}

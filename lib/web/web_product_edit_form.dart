import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/products/presentation/screens/barcode_scanner_screen.dart';

/// En mode simple, corrige la fiche et ses prix dans une même transaction RPC.
/// Les autres modes gardent leur formulaire de métadonnées sans prix ni stock.
class WebProductEditForm extends StatefulWidget {
  const WebProductEditForm({
    super.key,
    required this.shopId,
    required this.produit,
    required this.autoriserPrix,
  });

  final String shopId;
  final Map<String, dynamic> produit;
  final bool autoriserPrix;

  @override
  State<WebProductEditForm> createState() => _WebProductEditFormState();
}

class _WebProductEditFormState extends State<WebProductEditForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _unite;
  late final TextEditingController _codeBarres;
  late final TextEditingController _alerte;
  late final TextEditingController _prixAchat;
  late final TextEditingController _prixVente;
  bool _enregistrement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _nom = TextEditingController(text: widget.produit['name'] as String? ?? '');
    _unite = TextEditingController(
      text: widget.produit['unit'] as String? ?? '',
    );
    _codeBarres = TextEditingController(
      text: widget.produit['barcode'] as String? ?? '',
    );
    _alerte = TextEditingController(
      text: ((widget.produit['min_quantity'] as num?) ?? 2).toInt().toString(),
    );
    _prixAchat = TextEditingController(
      text: ((widget.produit['buy_price'] as num?) ?? 0).round().toString(),
    );
    _prixVente = TextEditingController(
      text: ((widget.produit['sell_price'] as num?) ?? 0).round().toString(),
    );
  }

  @override
  void dispose() {
    _nom.dispose();
    _unite.dispose();
    _codeBarres.dispose();
    _alerte.dispose();
    _prixAchat.dispose();
    _prixVente.dispose();
    super.dispose();
  }

  Future<void> _scannerCode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (mounted && code != null && code.trim().isNotEmpty) {
      setState(() => _codeBarres.text = code.trim());
    }
  }

  Future<void> _enregistrer() async {
    if (_enregistrement || !_form.currentState!.validate()) return;
    setState(() {
      _enregistrement = true;
      _erreur = null;
    });
    final code = _codeBarres.text.trim();
    try {
      final id = widget.produit['id'] as String;
      final client = Supabase.instance.client;
      if (widget.autoriserPrix) {
        await client.rpc(
          'web_update_simple_product',
          params: {
            'p_shop_id': widget.shopId,
            'p_product_id': id,
            'p_expected_updated_at': widget.produit['updated_at'],
            'p_name': _nom.text.trim(),
            'p_unit': _unite.text.trim().isEmpty ? null : _unite.text.trim(),
            'p_barcode': code.isEmpty ? 'QR-$id' : code,
            'p_min_quantity': int.parse(_alerte.text.trim()),
            'p_buy_price': int.parse(_prixAchat.text.trim()),
            'p_sell_price': int.parse(_prixVente.text.trim()),
          },
        );
      } else {
        final resultat = await client
            .from('products')
            .update({
              'name': _nom.text.trim(),
              'unit': _unite.text.trim().isEmpty ? null : _unite.text.trim(),
              'barcode': code.isEmpty ? 'QR-$id' : code,
              'min_quantity': int.parse(_alerte.text.trim()),
            })
            .eq('id', id)
            .eq('shop_id', widget.shopId)
            .isFilter('archived_at', null)
            .select('id')
            .maybeSingle();
        if (resultat == null) {
          throw StateError(
            'Produit introuvable ou modification non autorisée.',
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (erreur) {
      if (!mounted) return;
      if (widget.autoriserPrix) {
        try {
          final actuel = await Supabase.instance.client
              .from('products')
              .select('name,unit,barcode,min_quantity,buy_price,sell_price')
              .eq('id', widget.produit['id'] as String)
              .eq('shop_id', widget.shopId)
              .maybeSingle();
          if (actuel != null &&
              actuel['name'] == _nom.text.trim() &&
              (actuel['unit'] ?? '') == _unite.text.trim() &&
              actuel['barcode'] ==
                  (code.isEmpty ? 'QR-${widget.produit['id']}' : code) &&
              actuel['min_quantity'] == int.parse(_alerte.text.trim()) &&
              (actuel['buy_price'] as num).round() ==
                  int.parse(_prixAchat.text.trim()) &&
              (actuel['sell_price'] as num).round() ==
                  int.parse(_prixVente.text.trim())) {
            if (mounted) Navigator.of(context).pop(true);
            return;
          }
        } catch (_) {
          // La relecture peut aussi échouer si le réseau est absent.
        }
      }
      if (!mounted) return;
      setState(() {
        _erreur = erreur is PostgrestException && erreur.code == '23505'
            ? 'Ce code-barres existe déjà dans cette boutique.'
            : erreur is PostgrestException && erreur.code == '40001'
            ? 'Cette fiche a changé ailleurs. Actualise le stock, puis rouvre-la.'
            : 'Modification non confirmée. Vérifie Internet puis réessaie.';
      });
    } finally {
      if (mounted) setState(() => _enregistrement = false);
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
            'Modifier le produit',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            widget.autoriserPrix
                ? 'Modifie les informations et les prix. Le stock se change avec une opération de stock.'
                : 'Corrige la fiche du catalogue. Le stock et les prix ne changent pas ici.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nom,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nom du produit *'),
            validator: (valeur) {
              final nom = valeur?.trim() ?? '';
              if (nom.isEmpty) return 'Entre le nom du produit.';
              if (nom.length > 120) return '120 caractères maximum.';
              return null;
            },
          ),
          if (widget.autoriserPrix) ...[
            const SizedBox(height: 12),
            _champPrix('Prix d’achat (FCFA) *', _prixAchat),
            const SizedBox(height: 12),
            _champPrix('Prix de vente (FCFA) *', _prixVente),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _unite,
            decoration: const InputDecoration(
              labelText: 'Unité (facultatif)',
              hintText: 'Ex. pièce, sac, bouteille',
            ),
            validator: (valeur) => (valeur?.trim().length ?? 0) > 30
                ? '30 caractères maximum.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeBarres,
            decoration: const InputDecoration(
              labelText: 'Code-barres (facultatif)',
              hintText: 'Un QR sera créé si ce champ reste vide',
            ),
            validator: (valeur) => (valeur?.trim().length ?? 0) > 100
                ? '100 caractères maximum.'
                : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _scannerCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scanner le code'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _alerte,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Alerte de stock bas *',
            ),
            validator: (valeur) => int.tryParse(valeur?.trim() ?? '') == null
                ? 'Entre un entier positif ou zéro.'
                : null,
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(_erreur!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _enregistrement ? null : _enregistrer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _enregistrement
                    ? 'Enregistrement…'
                    : 'Enregistrer les modifications',
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _enregistrement
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
        ],
      ),
    ),
  );

  Widget _champPrix(String libelle, TextEditingController controleur) =>
      TextFormField(
        controller: controleur,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: libelle),
        validator: (valeur) => int.tryParse(valeur?.trim() ?? '') == null
            ? 'Entre un montant entier en FCFA, positif ou zéro.'
            : null,
      );
}

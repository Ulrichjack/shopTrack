import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../features/products/presentation/screens/barcode_scanner_screen.dart';
import 'web_product_photo_upload.dart';

/// Création en ligne : le succès n'est annoncé qu'après confirmation serveur.
class WebProductForm extends StatefulWidget {
  const WebProductForm({
    super.key,
    required this.shopId,
    required this.estPatron,
    required this.stockInitialAutorise,
  });

  final String shopId;
  final bool estPatron;
  final bool stockInitialAutorise;

  @override
  State<WebProductForm> createState() => _WebProductFormState();
}

class _WebProductFormState extends State<WebProductForm> {
  final String _productId = const Uuid().v4();
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prixAchat = TextEditingController();
  final _prixVente = TextEditingController();
  final _quantite = TextEditingController(text: '0');
  final _alerte = TextEditingController(text: '2');
  final _codeBarres = TextEditingController();
  final _unite = TextEditingController();
  String? _erreur;
  bool _enregistrement = false;
  bool _produitCree = false;

  @override
  void dispose() {
    _nom.dispose();
    _prixAchat.dispose();
    _prixVente.dispose();
    _quantite.dispose();
    _alerte.dispose();
    _codeBarres.dispose();
    _unite.dispose();
    super.dispose();
  }

  String? _validerEntier(String? valeur, {bool obligatoire = true}) {
    final texte = valeur?.trim() ?? '';
    if (texte.isEmpty && !obligatoire) return null;
    final nombre = int.tryParse(texte);
    if (nombre == null || nombre < 0) return 'Entre un entier positif ou zéro.';
    return null;
  }

  Future<void> _scannerCode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (mounted && code != null && code.trim().isNotEmpty) {
      setState(() => _codeBarres.text = code.trim());
    }
  }

  Future<void> _enregistrer({bool avecPhoto = false}) async {
    if ((!_produitCree && !_form.currentState!.validate()) || _enregistrement) return;
    setState(() {
      _enregistrement = true;
      _erreur = null;
    });
    try {
      if (!_produitCree) {
        final barcode = _codeBarres.text.trim();
        await Supabase.instance.client.from('products').insert({
        'id': _productId,
        'shop_id': widget.shopId,
        'name': _nom.text.trim(),
        'buy_price': widget.estPatron
            ? int.tryParse(_prixAchat.text.trim()) ?? 0
            : 0,
        'sell_price': int.parse(_prixVente.text.trim()),
        'quantity': widget.stockInitialAutorise
            ? int.parse(_quantite.text.trim())
            : 0,
        'min_quantity': int.parse(_alerte.text.trim()),
        'barcode': barcode.isEmpty ? 'QR-$_productId' : barcode,
        'unit': _unite.text.trim().isEmpty ? null : _unite.text.trim(),
        'is_ingredient': false,
        });
        _produitCree = true;
      }
      if (avecPhoto && mounted) {
        await choisirEtEnvoyerPhotoWeb(
          context, shopId: widget.shopId, productId: _productId);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (erreur) {
      if (!mounted) return;
      if (_produitCree) {
        setState(() => _erreur = erreur is FormatException
            ? 'Produit créé. ${erreur.message} Tu peux réessayer la photo.'
            : 'Produit créé, mais photo non confirmée. Réessaie ou termine.');
        return;
      }
      // Si l'insertion a réussi mais que la réponse s'est perdue, une
      // nouvelle tentative ne doit pas fabriquer un second produit.
      try {
        final dejaCree = await Supabase.instance.client
            .from('products')
            .select('id')
            .eq('id', _productId)
            .maybeSingle();
        if (dejaCree != null) {
          _produitCree = true;
          if (avecPhoto && mounted) {
            try {
              await choisirEtEnvoyerPhotoWeb(
                context, shopId: widget.shopId, productId: _productId);
            } catch (_) {
              if (mounted) setState(() => _erreur =
                  'Produit créé, mais photo non confirmée. Réessaie ou termine.');
              return;
            }
          }
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Réseau encore indisponible : garder le formulaire et son identifiant.
      }
      if (!mounted) return;
      setState(
        () => _erreur = erreur is PostgrestException && erreur.code == '23505'
            ? 'Ce code-barres existe déjà dans cette boutique.'
            : 'Enregistrement refusé. Vérifie Internet et réessaie.',
      );
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
            'Ajouter un produit',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            widget.stockInitialAutorise
                ? 'Le produit apparaîtra aussi sur ShopTrack TEST Android après synchronisation.'
                : 'Le stock sera initialisé dans le module de ta boutique.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nom,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nom du produit *'),
            validator: (v) {
              final nom = v?.trim() ?? '';
              if (nom.isEmpty) return 'Entre le nom du produit.';
              if (nom.length > 120) return '120 caractères maximum.';
              return null;
            },
          ),
          const SizedBox(height: 12),
          if (widget.estPatron) ...[
            _entier('Prix d’achat (FCFA)', _prixAchat, obligatoire: false),
            const SizedBox(height: 12),
          ],
          _entier('Prix de vente (FCFA) *', _prixVente),
          if (widget.stockInitialAutorise) ...[
            const SizedBox(height: 12),
            _entier('Quantité initiale *', _quantite),
          ],
          const SizedBox(height: 12),
          _entier('Alerte de stock bas *', _alerte),
          const SizedBox(height: 12),
          TextFormField(
            controller: _unite,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(
              labelText: 'Unité (facultatif)',
              hintText: 'Ex. pièce, sac, bouteille',
            ),
            validator: (v) =>
                (v?.trim().length ?? 0) > 30 ? '30 caractères maximum.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeBarres,
            decoration: const InputDecoration(
              labelText: 'Code-barres (facultatif)',
              hintText: 'Un QR sera créé si le champ reste vide',
            ),
            validator: (v) => (v?.trim().length ?? 0) > 100
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
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(_erreur!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _enregistrement ? null : () => _enregistrer(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _enregistrement ? 'Enregistrement…' :
                _produitCree ? 'Terminer' : 'Enregistrer le produit',
              ),
            ),
          ),
          if (widget.estPatron) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _enregistrement
                  ? null : () => _enregistrer(avecPhoto: true),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(_produitCree
                  ? 'Réessayer la photo'
                  : 'Enregistrer et ajouter une photo'),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _enregistrement
                ? null
                : () => Navigator.of(context).pop(_produitCree),
            child: Text(_produitCree ? 'Terminer sans photo' : 'Annuler'),
          ),
        ],
      ),
    ),
  );

  Widget _entier(
    String label,
    TextEditingController controller, {
    bool obligatoire = true,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    validator: (v) => _validerEntier(v, obligatoire: obligatoire),
  );
}

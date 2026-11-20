import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'web_theme.dart';
import 'web_product_photo_upload.dart';

/// Photo distante d'un produit. Le web ne lit jamais les chemins locaux Android.
class WebProductPhoto extends StatelessWidget {
  const WebProductPhoto({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.iconSize = 28,
  });

  final String? url;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: WebPalette.muted,
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: iconSize,
          color: WebPalette.muted,
        ),
      ),
    );
  }
}

/// Fiche de consultation web. Le grand cadre photo est le premier élément,
/// comme sur Android ; une modification éventuelle s'ouvre ensuite à part.
enum WebProductDetailAction { modifier, photo, recharge, archiver }

class WebProductDetail extends StatefulWidget {
  const WebProductDetail({
    super.key,
    required this.produit,
    required this.estPatron,
    required this.stockInitialAutorise,
    required this.shopId,
  });

  final Map<String, dynamic> produit;
  final bool estPatron;
  final bool stockInitialAutorise;
  final String shopId;

  @override
  State<WebProductDetail> createState() => _WebProductDetailState();
}

class _WebProductDetailState extends State<WebProductDetail> {
  bool _envoiPhoto = false;
  String? _erreurPhoto;

  Future<void> _choisirPhoto() async {
    if (_envoiPhoto) return;
    setState(() {
      _envoiPhoto = true;
      _erreurPhoto = null;
    });
    try {
      final ajout = await choisirEtEnvoyerPhotoWeb(
        context,
        shopId: widget.shopId,
        productId: widget.produit['id'] as String,
      );
      if (ajout && mounted) {
        Navigator.of(context).pop(WebProductDetailAction.photo);
      }
    } on FormatException catch (erreur) {
      if (mounted) setState(() => _erreurPhoto = erreur.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreurPhoto =
              'Photo non confirmée. Vérifie Internet et tes droits, puis réessaie.',
        );
      }
    } finally {
      if (mounted) setState(() => _envoiPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nom = widget.produit['name'] as String? ?? 'Produit';
    final code = widget.produit['barcode'] as String?;
    final quantite = (widget.produit['quantity'] as num?)?.toInt() ?? 0;
    final prix = (widget.produit['sell_price'] as num?)?.round() ?? 0;
    final unite = (widget.produit['unit'] as String?)?.trim() ?? '';
    final url = widget.produit['photo_url'] as String?;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'FICHE PRODUIT',
                  style: TextStyle(
                    color: WebPalette.pine,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: WebPalette.canvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WebPalette.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: WebProductPhoto(url: url, fit: BoxFit.contain, iconSize: 64),
          ),
          const SizedBox(height: 20),
          Text(nom, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Information('Prix de vente', '$prix FCFA'),
              if (widget.stockInitialAutorise)
                _Information(
                  'Stock',
                  '$quantite ${unite.isEmpty ? 'article(s)' : unite}',
                ),
            ],
          ),
          if (code != null && code.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Code : $code',
                    style: const TextStyle(color: WebPalette.muted),
                  ),
                ),
                IconButton(
                  tooltip: 'Afficher le QR code',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(nom),
                      content: SizedBox(
                        width: 220,
                        height: 220,
                        child: QrImageView(data: code),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2),
                ),
              ],
            ),
          ],
          if (widget.estPatron) ...[
            const SizedBox(height: 22),
            if (widget.stockInitialAutorise) ...[
              OutlinedButton.icon(
                onPressed: _envoiPhoto
                    ? null
                    : () => Navigator.of(context).pop(WebProductDetailAction.recharge),
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Ajouter du stock'),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _envoiPhoto ? null : _choisirPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                _envoiPhoto
                    ? 'Envoi de la photo…'
                    : 'Prendre ou choisir une photo',
              ),
            ),
            if (_erreurPhoto != null) ...[
              const SizedBox(height: 8),
              Text(
                _erreurPhoto!,
                style: const TextStyle(color: WebPalette.danger),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _envoiPhoto
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop(WebProductDetailAction.modifier),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier la fiche'),
            ),
            if (widget.stockInitialAutorise) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _envoiPhoto
                    ? null
                    : () => Navigator.of(context).pop(WebProductDetailAction.archiver),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archiver le produit'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Information extends StatelessWidget {
  const _Information(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 150),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: WebPalette.canvas,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: WebPalette.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: WebPalette.muted, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

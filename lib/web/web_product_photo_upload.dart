import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sélectionne une photo dans le navigateur, la convertit en JPEG et la lie
/// au produit. Le nom de l'objet suit la règle Storage du propriétaire.
Future<bool> choisirEtEnvoyerPhotoWeb(
  BuildContext context, {
  required String shopId,
  required String productId,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return false;

  // image_picker_for_web ne réduit ni les dimensions ni la qualité : traiter
  // nous-mêmes les octets avant de les envoyer au stockage.
  final fichier = await ImagePicker().pickImage(source: source);
  if (fichier == null) return false;
  final octets = await fichier.readAsBytes();
  if (octets.length > 15 * 1024 * 1024) {
    throw const FormatException('Photo trop grande (15 Mo maximum).');
  }
  final image = img.decodeImage(octets);
  if (image == null) {
    throw const FormatException('Format de photo non reconnu.');
  }
  final reduite = image.width > 1200 || image.height > 1200
      ? img.copyResize(
          image,
          width: image.width >= image.height ? 1200 : null,
          height: image.height > image.width ? 1200 : null,
        )
      : image;
  final jpeg = Uint8List.fromList(img.encodeJpg(reduite, quality: 75));
  if (jpeg.length > 6 * 1024 * 1024) {
    throw const FormatException('Photo trop grande après réduction.');
  }

  final client = Supabase.instance.client;
  final actuel = await client
      .from('products')
      .select('id')
      .eq('id', productId)
      .eq('shop_id', shopId)
      .isFilter('archived_at', null)
      .maybeSingle();
  if (actuel == null) {
    throw StateError('Produit introuvable dans cette boutique.');
  }

  final objet = '${shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final stockage = client.storage.from('product-photos');
  await stockage.uploadBinary(
    objet,
    jpeg,
    fileOptions: const FileOptions(contentType: 'image/jpeg'),
  );
  final url = stockage.getPublicUrl(objet);
  final resultat = await client
      .from('products')
      .update({'photo_url': url})
      .eq('id', productId)
      .eq('shop_id', shopId)
      .select('id')
      .maybeSingle();
  if (resultat == null) {
    throw StateError('Photo envoyée, fiche non mise à jour.');
  }
  return true;
}

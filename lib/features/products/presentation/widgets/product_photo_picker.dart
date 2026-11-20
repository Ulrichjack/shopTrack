import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Laisse le commerçant choisir la source, puis renvoie un fichier utilisable
/// par le flux d'envoi des photos produit existant.
Future<File?> choisirPhotoProduit(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;
  final photo = await ImagePicker().pickImage(
    source: source,
    imageQuality: 50,
    maxWidth: 800,
    maxHeight: 800,
  );
  return photo == null ? null : File(photo.path);
}

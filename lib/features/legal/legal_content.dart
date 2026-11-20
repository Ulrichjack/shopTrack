import 'dart:convert';

import 'package:flutter/services.dart';

/// Source commune aux écrans hors ligne et aux pages HTML à héberger.
class LegalContent {
  LegalContent.fromJson(Map<String, dynamic> json)
    : version = json['version'] as String,
      draft = json['draft'] as bool,
      publisher = json['publisher'] as String,
      contact = json['contact'] as String,
      copyright = json['copyright'] as String,
      draftNotice = json['draftNotice'] as String,
      documents = (json['documents'] as List)
          .map((value) => LegalDocument.fromJson(value as Map<String, dynamic>))
          .toList();

  final String version;
  final bool draft;
  final String publisher;
  final String contact;
  final String copyright;
  final String draftNotice;
  final List<LegalDocument> documents;

  static Future<LegalContent> load() async => LegalContent.fromJson(
    jsonDecode(await rootBundle.loadString('assets/legal/informations_fr.json'))
        as Map<String, dynamic>,
  );

  LegalDocument document(String id) =>
      documents.firstWhere((document) => document.id == id);
}

class LegalDocument {
  LegalDocument.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['title'] as String,
      sections = (json['sections'] as List)
          .map((value) => LegalSection.fromJson(value as Map<String, dynamic>))
          .toList();

  final String id;
  final String title;
  final List<LegalSection> sections;
}

class LegalSection {
  LegalSection.fromJson(Map<String, dynamic> json)
    : title = json['title'] as String,
      paragraphs = List<String>.from(json['paragraphs'] as List);

  final String title;
  final List<String> paragraphs;
}

enum DataRequest {
  access(
    'Accès à mes données',
    'recevoir une copie de mes données personnelles',
  ),
  correction('Rectification de mes données', 'faire rectifier mes données'),
  deletion(
    'Suppression de mon compte',
    'faire supprimer mon compte ShopTrack et les données personnelles associées',
  );

  const DataRequest(this.subject, this.description);

  final String subject;
  final String description;

  String get body =>
      'Bonjour,\n\nJe souhaite $description.\n\n'
      'Numéro utilisé pour me connecter : [à compléter]\n'
      'Précisions utiles : [à compléter si nécessaire]\n\n'
      'Merci de m’indiquer la vérification nécessaire et les suites '
      'données à ma demande.\n\n'
      'Je ne joins aucun mot de passe ni code PIN.';

  // Pas de compte, de données de boutique ou de secrets lus automatiquement.
  // Pour mailto, encoder les espaces avec %20 plutôt qu'avec +.
  Uri emailUri(String contact) => Uri(
    scheme: 'mailto',
    path: contact,
    query:
        'subject=${Uri.encodeComponent('ShopTrack — $subject')}'
        '&body=${Uri.encodeComponent(body)}',
  );
}

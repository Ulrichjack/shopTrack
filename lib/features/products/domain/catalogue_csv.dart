import 'package:csv/csv.dart';

import 'entities/product_entity.dart';

const entetesCatalogueCsv = [
  'nom',
  'prix_achat',
  'prix_vente',
  'quantite',
  'alerte_stock_bas',
  'code_barres',
  'unite',
];

final _debutFormuleTableur = RegExp(r'^[\s]*[=+\-@＝＋－＠]');

bool _estFormuleTableur(String valeur) => _debutFormuleTableur.hasMatch(valeur);

String _texteExportable(String valeur) =>
    _estFormuleTableur(valeur) ? '\t$valeur' : valeur;

class LigneCatalogueCsv {
  const LigneCatalogueCsv({
    required this.numero,
    required this.nom,
    required this.prixAchat,
    required this.prixVente,
    required this.quantite,
    required this.alerteStockBas,
    required this.codeBarres,
    required this.unite,
  });

  final int numero;
  final String nom;
  final int prixAchat;
  final int prixVente;
  final int quantite;
  final int alerteStockBas;
  final String? codeBarres;
  final String? unite;
}

class ResultatImportCatalogueCsv {
  const ResultatImportCatalogueCsv(this.lignes, this.erreurs);

  final List<LigneCatalogueCsv> lignes;
  final List<String> erreurs;

  bool get estValide => erreurs.isEmpty && lignes.isNotEmpty;
}

/// Import de création seulement : aucun produit existant n'est remplacé.
/// Toutes les lignes sont contrôlées avant le premier enregistrement.
ResultatImportCatalogueCsv lireCatalogueCsv(
  String contenu, {
  required bool stockInitialAutorise,
  required Iterable<ProductEntity> produitsExistants,
}) {
  final lignes = <LigneCatalogueCsv>[];
  final erreurs = <String>[];
  final rows = Csv(
    fieldDelimiter: ';',
    autoDetect: false,
  ).decode(contenu.replaceFirst('\uFEFF', ''));

  if (rows.isEmpty) {
    return const ResultatImportCatalogueCsv([], ['Le fichier est vide.']);
  }
  final entetes = rows.first.map((cellule) => '$cellule'.trim()).toList();
  if (entetes.length != entetesCatalogueCsv.length ||
      !List.generate(
        entetes.length,
        (i) => entetes[i] == entetesCatalogueCsv[i],
      ).every((identique) => identique)) {
    return const ResultatImportCatalogueCsv([], [
      'Les colonnes ne correspondent pas au modèle du catalogue.',
    ]);
  }
  if (rows.length == 1) {
    return const ResultatImportCatalogueCsv([], ['Aucun produit à importer.']);
  }
  if (rows.length > 101) {
    return const ResultatImportCatalogueCsv([], [
      'Maximum 100 produits par fichier.',
    ]);
  }

  final noms = produitsExistants
      .map((p) => p.name.trim().toLowerCase())
      .toSet();
  final codes = produitsExistants
      .map((p) => p.barcode?.trim().toLowerCase())
      .whereType<String>()
      .where((code) => code.isNotEmpty)
      .toSet();

  for (var i = 1; i < rows.length; i++) {
    final numero = i + 1;
    final row = rows[i];
    if (row.length != entetesCatalogueCsv.length) {
      erreurs.add(
        'Ligne $numero : ${entetesCatalogueCsv.length} colonnes attendues.',
      );
      continue;
    }
    String cellule(int colonne) => '${row[colonne]}'.trim();
    final nom = cellule(0);
    final prixAchatBrut = cellule(1);
    final prixVenteBrut = cellule(2);
    final quantiteBrute = cellule(3);
    final alerteBrute = cellule(4);
    final code = cellule(5);
    final unite = cellule(6);
    final prixAchat = prixAchatBrut.isEmpty ? 0 : int.tryParse(prixAchatBrut);
    final prixVente = int.tryParse(prixVenteBrut);
    final quantite = quantiteBrute.isEmpty ? null : int.tryParse(quantiteBrute);
    final alerte = alerteBrute.isEmpty ? 2 : int.tryParse(alerteBrute);
    var valide = true;

    if (nom.isEmpty || nom.length > 120) {
      erreurs.add('Ligne $numero : nom obligatoire (120 caractères maximum).');
      valide = false;
    } else if (_estFormuleTableur(nom)) {
      erreurs.add('Ligne $numero : le nom ne peut pas commencer par une formule.');
      valide = false;
    } else if (!noms.add(nom.toLowerCase())) {
      erreurs.add(
        'Ligne $numero : ce nom existe déjà dans la boutique ou le fichier.',
      );
      valide = false;
    }
    if (prixAchat == null ||
        prixAchat < 0 ||
        prixVente == null ||
        prixVente < 0) {
      erreurs.add(
        'Ligne $numero : prix invalides, utiliser des entiers FCFA positifs.',
      );
      valide = false;
    }
    if (stockInitialAutorise) {
      if (quantite == null || quantite < 0) {
        erreurs.add(
          'Ligne $numero : quantité initiale obligatoire (entier positif ou zéro).',
        );
        valide = false;
      }
    } else if (quantiteBrute.isNotEmpty) {
      erreurs.add('Ligne $numero : laisser la quantité vide dans ce mode.');
      valide = false;
    }
    if (alerte == null || alerte < 0) {
      erreurs.add('Ligne $numero : alerte de stock invalide.');
      valide = false;
    }
    if (code.isNotEmpty && !codes.add(code.toLowerCase())) {
      erreurs.add('Ligne $numero : code-barres déjà utilisé.');
      valide = false;
    }
    if (_estFormuleTableur(code) || _estFormuleTableur(unite)) {
      erreurs.add(
        'Ligne $numero : code-barres ou unité ressemblant à une formule.',
      );
      valide = false;
    }
    if (valide) {
      lignes.add(
        LigneCatalogueCsv(
          numero: numero,
          nom: nom,
          prixAchat: prixAchat!,
          prixVente: prixVente!,
          quantite: quantite ?? 0,
          alerteStockBas: alerte!,
          codeBarres: code.isEmpty ? null : code,
          unite: unite.isEmpty ? null : unite,
        ),
      );
    }
  }
  return ResultatImportCatalogueCsv(lignes, erreurs);
}

String ecrireCatalogueCsv(
  Iterable<ProductEntity> produits, {
  required bool stockInitialAutorise,
}) {
  return Csv(
    fieldDelimiter: ';',
    addBom: true,
    autoDetect: false,
    quoteMode: QuoteMode.always,
  ).encode([
    entetesCatalogueCsv,
    for (final produit in produits)
      [
        _texteExportable(produit.name),
        produit.buyPrice.round(),
        produit.sellPrice.round(),
        stockInitialAutorise ? produit.quantity : '',
        produit.minQuantity,
        _texteExportable(produit.barcode ?? ''),
        _texteExportable(produit.unit ?? ''),
      ],
  ]);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/features/products/domain/catalogue_csv.dart';
import 'package:shoptrack/features/products/domain/entities/product_entity.dart';

ProductEntity produitExistant() => ProductEntity(
  id: 'p1',
  shopId: 'b1',
  name: 'Savon',
  buyPrice: 500,
  sellPrice: 750,
  quantity: 12,
  minQuantity: 2,
  barcode: 'SAVON-1',
);

void main() {
  test('l’export Excel se relit avec accents et séparateurs dans le nom', () {
    final contenu = ecrireCatalogueCsv([
      ProductEntity(
        id: 'p2',
        shopId: 'b1',
        name: 'Épices; mélange',
        buyPrice: 500,
        sellPrice: 800,
        quantity: 4,
        minQuantity: 1,
      ),
    ], stockInitialAutorise: true);
    final resultat = lireCatalogueCsv(
      contenu,
      stockInitialAutorise: true,
      produitsExistants: const [],
    );

    expect(resultat.estValide, isTrue);
    expect(resultat.lignes.single.nom, 'Épices; mélange');
    expect(resultat.lignes.single.quantite, 4);
  });

  test('l’import refuse le fichier entier si une ligne est incorrecte', () {
    const contenu =
        'nom;prix_achat;prix_vente;quantite;alerte_stock_bas;code_barres;unite\n'
        'Riz;100;150;5;2;RIZ-1;sac\n'
        'Savon;500;750;-1;2;SAVON-1;piece';
    final resultat = lireCatalogueCsv(
      contenu,
      stockInitialAutorise: true,
      produitsExistants: [produitExistant()],
    );

    expect(resultat.estValide, isFalse);
    expect(resultat.erreurs.join(' '), contains('Ligne 3'));
  });

  test('l’inventaire refuse une quantité importée comme faux comptage', () {
    const contenu =
        'nom;prix_achat;prix_vente;quantite;alerte_stock_bas;code_barres;unite\n'
        'Riz;100;150;5;2;RIZ-1;sac';
    final resultat = lireCatalogueCsv(
      contenu,
      stockInitialAutorise: false,
      produitsExistants: const [],
    );

    expect(resultat.estValide, isFalse);
    expect(resultat.erreurs.single, contains('laisser la quantité vide'));
  });

  test('le code-barres déjà utilisé dans la boutique est rejeté', () {
    const contenu =
        'nom;prix_achat;prix_vente;quantite;alerte_stock_bas;code_barres;unite\n'
        'Autre produit;100;150;5;2;SAVON-1;piece';
    final resultat = lireCatalogueCsv(
      contenu,
      stockInitialAutorise: true,
      produitsExistants: [produitExistant()],
    );

    expect(resultat.estValide, isFalse);
    expect(resultat.erreurs.single, contains('code-barres déjà utilisé'));
  });

  test('une formule est refusée à l’import et neutralisée à l’export', () {
    const contenu =
        'nom;prix_achat;prix_vente;quantite;alerte_stock_bas;code_barres;unite\n'
        '=1+2;100;150;5;2;TEST-3;piece';
    final resultat = lireCatalogueCsv(
      contenu,
      stockInitialAutorise: true,
      produitsExistants: const [],
    );
    expect(resultat.estValide, isFalse);
    expect(resultat.erreurs.join(' '), contains('formule'));

    final export = ecrireCatalogueCsv([
      ProductEntity(
        id: 'p3',
        shopId: 'b1',
        name: '=1+2',
        buyPrice: 100,
        sellPrice: 150,
        quantity: 5,
        minQuantity: 2,
      ),
    ], stockInitialAutorise: true);
    expect(export, contains('"\t=1+2"'));
  });
}

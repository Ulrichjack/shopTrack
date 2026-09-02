// Un ingrédient reste un ingrédient.
//
// La marque existe en base et dans l'entité, mais AUCUN écran ne la pose plus :
// l'interrupteur a été retiré le 01/09, en même temps que la recette. « On est
// là pour simplifier sa vie, pas l'encombrer » — une case que personne ne coche
// est une question posée à chaque produit pour rien.
//
// Ce qui reste est dormant et gratuit : la colonne, le filtre de l'écran de
// vente, et ces tests. Le jour où la recette sera méritée, tout est prêt et
// juste. Ces tests existent pour qu'il le reste.

import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/features/products/domain/entities/product_entity.dart';

void main() {
  ProductEntity produit({bool? ingredient}) => ProductEntity(
    id: 'p1',
    shopId: 'shop-1',
    name: 'Farine',
    buyPrice: 800,
    sellPrice: 0,
    quantity: 25,
    minQuantity: 5,
    isIngredient: ingredient,
  );

  test('nul se lit « non », comme pour l\'archivage', () {
    // Les produits déjà en base valent nul : ils doivent rester vendables.
    expect(produit().estIngredient, isFalse);
    expect(produit(ingredient: false).estIngredient, isFalse);
    expect(produit(ingredient: true).estIngredient, isTrue);
  });

  test('copyWith garde la marque quand on ne la touche pas', () {
    // C'est par là qu'un champ disparaît : une copie faite pour changer le
    // prix, et l'ingrédient redevient vendable sans que personne ne le voie.
    final farine = produit(ingredient: true);
    expect(farine.copyWith(buyPrice: 950).estIngredient, isTrue);
    expect(farine.copyWith(quantity: 3).estIngredient, isTrue);
  });

  test('un ingrédient ne passe pas le filtre de l\'écran de vente', () {
    // Même règle que dans `new_sale_screen` : en stock avec son prix d'achat,
    // absent du comptoir.
    final catalogue = [
      produit(ingredient: true),
      produit(ingredient: false),
      produit(),
    ];
    final vendables = catalogue.where((p) => !p.estIngredient).toList();
    expect(vendables.length, 2);
  });

}

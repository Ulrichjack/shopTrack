import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/features/products/presentation/providers/product_provider.dart';

/// `compareTo` range les majuscules avant TOUTES les minuscules et les lettres
/// accentuées après tout le reste. Sur les 235 produits d'un vrai catalogue
/// saisi à la main, « dolait » atterrissait après « Sucre » et « Éponge »
/// entre les deux — le commerçant en conclut que rien n'est trié.
void main() {
  List<String> trier(List<String> noms) =>
      [...noms]..sort(comparerNomsProduits);

  test('une minuscule ne part pas en fin de liste', () {
    expect(trier(['Sucre Morello', 'dolait', 'Azur']), [
      'Azur',
      'dolait',
      'Sucre Morello',
    ]);
  });

  test('un accent se range à la lettre qu\'il porte', () {
    expect(trier(['Farine', 'Éponge', 'Dudu', 'Fatala']), [
      'Dudu',
      'Éponge',
      'Farine',
      'Fatala',
    ]);
  });

  test(
    'deux noms qui ne diffèrent que par la casse gardent un ordre stable',
    () {
      final ordre = trier(['azur', 'Azur']);
      expect(ordre.toSet(), {'azur', 'Azur'});
      expect(trier(ordre), ordre, reason: 'retrier ne doit rien changer');
    },
  );
}

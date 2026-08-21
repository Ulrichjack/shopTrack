import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/inventory_reconciliation_calculator.dart';

/// Créer un produit n'écrit aucune ligne d'historique : le tarif de départ ne
/// vit que dans la fiche. Au premier changement, l'historique ne contenait donc
/// QUE le nouveau prix — et le calcul, faute de tarif applicable aux jours
/// antérieurs, retombait sur le plus ancien connu, c'est-à-dire le nouveau.
/// Une hausse saisie aujourd'hui revalorisait toute une période close au prix
/// d'aujourd'hui.
void main() {
  final debut = DateTime(2026, 8, 10);
  final fin = DateTime(2026, 8, 21);

  test('sans l\'ancien tarif gravé, la hausse réécrit toute la période', () {
    // Le comportement qu'on refuse : un seul point, daté du dernier jour.
    final prix = weightedSellPrice(
      periodStart: debut,
      periodEnd: fin,
      priceHistory: [PricePoint(effectiveAt: fin, sellPrice: 700)],
      productSellPrice: 700,
    );
    expect(prix, 700, reason: 'les 12 jours valorisés au tarif du dernier');
  });

  test('avec l\'ancien tarif gravé, seuls les jours concernés changent', () {
    final prix = weightedSellPrice(
      periodStart: debut,
      periodEnd: fin,
      priceHistory: [
        PricePoint(effectiveAt: DateTime(2000), sellPrice: 500),
        PricePoint(effectiveAt: fin, sellPrice: 700),
      ],
      productSellPrice: 700,
    );
    // Onze jours à 500, un seul à 700.
    expect(prix, closeTo((11 * 500 + 700) / 12, 0.001));
    expect(prix, lessThan(700), reason: 'la période ne suit pas la hausse');
  });

  test('le coût d\'ouverture reste celui d\'avant la hausse', () {
    final cout = buyPriceAt(debut, [
      PricePoint(effectiveAt: DateTime(2000), buyPrice: 300, sellPrice: 500),
      PricePoint(effectiveAt: fin, buyPrice: 450, sellPrice: 700),
    ], 450);
    expect(cout, 300, reason: 'la période a commencé avant la hausse');
  });
}

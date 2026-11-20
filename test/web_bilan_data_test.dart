import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/web/web_bilan_data.dart';

void main() {
  WebBilanData bilan({required int livrees, required int sansCout}) =>
      WebBilanData(
        nombreVentes: 0,
        totalVentes: 0,
        nombreRecettes: 0,
        totalRecettes: 0,
        commandesLivrees: livrees,
        totalCommandesLivrees: 20000,
        coutCommandesConnu: 7000,
        commandesSansCout: sansCout,
        encoreDuCommandes: 5000,
      );

  test('un coût manquant interdit un bénéfice de commande trompeur', () {
    expect(bilan(livrees: 2, sansCout: 1).beneficeCommandes, isNull);
    expect(bilan(livrees: 2, sansCout: 0).beneficeCommandes, 13000);
    expect(bilan(livrees: 0, sansCout: 0).beneficeCommandes, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/router.dart';

void main() {
  test('le mode périodique ne construit jamais le dashboard de caisse', () {
    expect(afficheDashboardCaisse('periodic'), isFalse);
  });

  test('la vente en temps réel utilise le dashboard de caisse continue', () {
    expect(afficheDashboardCaisse('realtime'), isTrue);
  });
}

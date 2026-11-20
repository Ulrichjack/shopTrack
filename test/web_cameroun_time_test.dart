import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/web/web_cameroun_time.dart';

void main() {
  test('un jour camerounais commence à 23 h UTC la veille', () {
    final jour = DateTime(2026, 7, 1);
    expect(debutJourCamerounUtc(jour), DateTime.utc(2026, 6, 30, 23));
    expect(finJourCamerounUtc(jour), DateTime.utc(2026, 7, 1, 23));
  });

  test('un mois camerounais garde les opérations du dernier soir UTC', () {
    final mois = DateTime(2026, 7);
    expect(debutMoisCamerounUtc(mois), DateTime.utc(2026, 6, 30, 23));
    expect(finMoisCamerounUtc(mois), DateTime.utc(2026, 7, 31, 23));
    expect(heureCameroun(DateTime.utc(2026, 6, 30, 23, 30)).day, 1);
  });
}

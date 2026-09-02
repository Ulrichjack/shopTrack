// Le bilan des commandes ne doit jamais flatter.
//
// Le module tout entier existe pour éviter un chiffre inventé : un devis de
// 150 000 F n'est pas une recette de 150 000 F. Ces tests ferment les trois
// façons dont ce mensonge pourrait revenir par le bilan.

import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/features/commandes/presentation/providers/bilan_commandes_provider.dart';

void main() {
  LocalDossiersCommande dossier({
    required String id,
    int? montant,
    int? cout,
    DateTime? livreeAt,
    String statut = 'terminee',
  }) => LocalDossiersCommande(
    id: id,
    shopId: 'shop-1',
    clientId: 'c1',
    categorie: 'gateau',
    description: 'Gâteau',
    details: '{}',
    montantAccepte: montant,
    coutMatiere: cout,
    livreeAt: livreeAt,
    statut: statut,
    createdAt: DateTime(2026, 8, 1),
  );

  test('les semaines se coupent du lundi au dimanche', () {
    // Une semaine coupée au 1er du mois ne se compare à rien. Le commerçant,
    // lui, compte en semaines entières.
    final semaines = decouperEnSemaines(
      [
        // Mardi 1er septembre 2026
        dossier(id: 'a', montant: 50000, cout: 10000,
            livreeAt: DateTime(2026, 9, 1)),
        // Vendredi 4 — même semaine
        dossier(id: 'b', montant: 30000, cout: 5000,
            livreeAt: DateTime(2026, 9, 4)),
        // Mercredi 9 — la suivante
        dossier(id: 'c', montant: 20000, cout: 8000,
            livreeAt: DateTime(2026, 9, 9)),
      ],
      DateTime(2026, 9, 1),
      DateTime(2026, 10, 1),
    );

    expect(semaines.length, 2);
    expect(semaines.first.nombreLivrees, 2);
    expect(semaines.first.chiffreAffaires, 80000);
    expect(semaines.first.benefice, 65000, reason: '80 000 − 15 000');
    expect(semaines.last.nombreLivrees, 1);
    expect(semaines.last.benefice, 12000);
  });

  test('une semaine sans aucun coût n\'annonce pas de bénéfice', () {
    // Sinon le chiffre d'affaires s'afficherait comme un gain — le mensonge le
    // plus facile à faire dans ce module.
    final semaines = decouperEnSemaines(
      [dossier(id: 'a', montant: 50000, livreeAt: DateTime(2026, 9, 1))],
      DateTime(2026, 9, 1),
      DateTime(2026, 10, 1),
    );

    expect(semaines.single.chiffreAffaires, 50000);
    expect(semaines.single.benefice, isNull);
  });

  test('un mois sans livraison ne fabrique aucune semaine vide', () {
    // Quatre lignes de zéros donnent l'impression d'avoir raté quelque chose.
    expect(
      decouperEnSemaines([], DateTime(2026, 9, 1), DateTime(2026, 10, 1)),
      isEmpty,
    );
  });

  test('le bénéfice global reste inconnu tant qu\'aucun coût n\'est saisi', () {
    final aveugle = BilanCommandes(
      chiffreAffaires: 380000,
      cout: 0,
      nombreLivrees: 3,
      livreesSansCout: 3,
      encoreDu: 110000,
      debitrices: const [],
      semaines: const [],
    );
    expect(aveugle.benefice, isNull);

    // Dès qu'UNE commande est chiffrée, on annonce un bénéfice — accompagné du
    // nombre de manquantes, pour qu'elle sache qu'il est trop beau.
    final partiel = BilanCommandes(
      chiffreAffaires: 380000,
      cout: 95000,
      nombreLivrees: 3,
      livreesSansCout: 2,
      encoreDu: 110000,
      debitrices: const [],
      semaines: const [],
    );
    expect(partiel.benefice, 285000);
    expect(partiel.livreesSansCout, 2);
  });
}

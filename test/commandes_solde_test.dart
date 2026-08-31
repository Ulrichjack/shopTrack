// Un devis n'est pas une recette.
//
// Le piège qu'on a mis une journée à retirer du module inventaire menaçait de
// revenir par la porte d'un module neuf : un montant annoncé compté comme de
// l'argent encaissé. Ici il ne peut pas — le solde n'existe nulle part, il se
// recalcule à chaque lecture.

import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/features/commandes/presentation/providers/commandes_provider.dart';

void main() {
  LocalDossiersCommande dossier({int? montant}) => LocalDossiersCommande(
    id: 'd1',
    shopId: 'shop-1',
    clientId: 'c1',
    categorie: 'gateau',
    description: 'Gâteau de mariage 3 étages',
    details: '{}',
    montantAccepte: montant,
    statut: montant == null ? 'demande' : 'confirmee',
    createdAt: DateTime(2026, 8, 31),
  );

  LocalPaiementsCommande paiement(
    String id,
    int montant, {
    String type = 'paiement',
    String mode = 'especes',
  }) => LocalPaiementsCommande(
    id: id,
    shopId: 'shop-1',
    dossierId: 'd1',
    typeMouvement: type,
    montant: montant,
    modePaiement: mode,
    effectueAt: DateTime(2026, 8, 31),
    createdAt: DateTime(2026, 8, 31),
  );

  test('une demande sans montant n\'a pas de solde, et c\'est normal', () {
    // La vendeuse enregistre ce que le client veut ; la propriétaire fixe le
    // prix depuis chez elle. Un dossier sans montant est une demande en
    // attente de devis, pas une donnée manquante.
    final d = DossierAvecSolde(
      dossier: dossier(),
      client: null,
      paiements: const [],
    );

    expect(d.solde, isNull);
    expect(d.estSolde, isFalse);
  });

  test('un devis de 150 000 F encaissé à 40 000 laisse 110 000 dus', () {
    final d = DossierAvecSolde(
      dossier: dossier(montant: 150000),
      client: null,
      paiements: [paiement('p1', 40000)],
    );

    expect(
      d.netEncaisse,
      40000,
      reason: 'seuls 40 000 F sont réellement entrés en caisse',
    );
    expect(d.solde, 110000);
    expect(d.estSolde, isFalse);
  });

  test('un remboursement est une ligne de plus, jamais une suppression', () {
    // La vendeuse ne peut pas effacer un acompte qu'elle a encaissé :
    // l'histoire de l'argent doit rester lisible, y compris ses erreurs.
    final d = DossierAvecSolde(
      dossier: dossier(montant: 150000),
      client: null,
      paiements: [
        paiement('p1', 40000),
        paiement('p2', 10000, type: 'remboursement'),
      ],
    );

    expect(d.totalPaye, 40000);
    expect(d.totalRembourse, 10000);
    expect(d.netEncaisse, 30000);
    expect(d.solde, 120000, reason: '150 000 − 30 000 réellement gardés');
  });

  test('le Mobile Money n\'entre pas dans le tiroir', () {
    // Un acompte payé par Mobile Money compté comme espèces produirait un
    // manquant du même montant à chaque clôture — et l'application accuserait
    // quelqu'un. C'est la même erreur que « toute sortie est une dépense ».
    final d = DossierAvecSolde(
      dossier: dossier(montant: 150000),
      client: null,
      paiements: [
        paiement('p1', 40000, mode: 'mtn_momo'),
        paiement('p2', 25000),
      ],
    );

    expect(d.netEncaisse, 65000, reason: 'le dossier a bien reçu 65 000 F');
    expect(
      d.encaisseEnEspeces,
      25000,
      reason: 'mais seuls 25 000 F sont dans la caisse physique',
    );
  });

  test('un dossier entièrement payé est soldé', () {
    final d = DossierAvecSolde(
      dossier: dossier(montant: 60000),
      client: null,
      paiements: [paiement('p1', 20000), paiement('p2', 40000)],
    );

    expect(d.solde, 0);
    expect(d.estSolde, isTrue);
  });
}

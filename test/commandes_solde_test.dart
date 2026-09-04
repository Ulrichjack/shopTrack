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

  test('le Mobile Money se compte, mais à part', () {
    // La vendeuse remet tout à la patronne le soir, Mobile Money compris. Cet
    // argent ne doit donc pas disparaître de l'écran — mais il ne doit pas non
    // plus entrer dans le tiroir, sinon le comptage du soir accuse quelqu'un.
    final d = DossierAvecSolde(
      dossier: dossier(montant: 150000),
      client: null,
      paiements: [
        paiement('p1', 40000),
        paiement('p2', 25000, mode: 'orange_money'),
        paiement('p3', 10000, mode: 'mtn_momo'),
      ],
    );

    expect(d.netEncaisse, 75000, reason: 'tout ce qui est entré');
    expect(d.encaisseEnEspeces, 40000, reason: 'ce qui est dans le tiroir');
    expect(
      d.netEncaisse - d.encaisseEnEspeces,
      35000,
      reason: 'à remettre à la patronne sans passer par la caisse',
    );
  });

  test('un remboursement en espèces retire bien du tiroir', () {
    final d = DossierAvecSolde(
      dossier: dossier(montant: 150000),
      client: null,
      paiements: [
        paiement('p1', 50000),
        paiement('p2', 50000, type: 'remboursement'),
      ],
    );

    expect(d.netEncaisse, 0);
    expect(d.encaisseEnEspeces, 0, reason: 'entré puis ressorti du tiroir');
    expect(d.solde, 150000, reason: 'la commande redevient entièrement due');
  });

  test('livrée et soldée ne veulent pas dire la même chose', () {
    // Le gâteau du 15 septembre, payé en entier aujourd'hui : soldé, et
    // entièrement à faire. Ranger la liste sur l'argent aurait rangé cette
    // commande parmi les affaires classées.
    final payeeNonLivree = DossierAvecSolde(
      dossier: dossier(montant: 60000),
      client: null,
      paiements: [paiement('p1', 60000)],
    );
    expect(payeeNonLivree.estSolde, isTrue);
    expect(payeeNonLivree.estLivree, isFalse);

    // L'inverse : la cliente emporte sa commande et doit encore 20 000 F.
    final livreeNonPayee = DossierAvecSolde(
      dossier: LocalDossiersCommande(
        id: 'd1',
        shopId: 'shop-1',
        clientId: 'c1',
        categorie: 'gateau',
        description: 'Gâteau anniversaire',
        details: '{}',
        montantAccepte: 60000,
        statut: 'terminee',
        createdAt: DateTime(2026, 8, 31),
      ),
      client: null,
      paiements: [paiement('p1', 40000)],
    );
    expect(livreeNonPayee.estLivree, isTrue);
    expect(livreeNonPayee.estSolde, isFalse);
    expect(
      livreeNonPayee.solde,
      20000,
      reason: 'livrer n\'efface pas la dette',
    );
  });

  test('sans coût saisi, le bénéfice est INCONNU — pas zéro', () {
    // Zéro dirait « elle n'a rien gagné ». Nul dit « on ne sait pas ». Afficher
    // zéro ferait croire à une commande blanche, et c'est le genre de chiffre
    // qu'on recopie dans un bilan sans se méfier.
    final d = DossierAvecSolde(
      dossier: dossier(montant: 150000),
      client: null,
      paiements: const [],
    );
    expect(d.benefice, isNull);
  });

  test('avec le coût, le bénéfice se calcule sur le PRIX, pas sur l\'encaissé', () {
    // Elle a gagné sa marge dès que la commande est livrée, même si la cliente
    // doit encore. Compter sur l'encaissé ferait baisser un bénéfice réel
    // parce qu'une cliente traîne à payer.
    final d = DossierAvecSolde(
      dossier: LocalDossiersCommande(
        id: 'd1',
        shopId: 'shop-1',
        clientId: 'c1',
        categorie: 'gateau',
        description: 'Gâteau mariage',
        details: '{}',
        montantAccepte: 150000,
        coutMatiere: 42000,
        statut: 'terminee',
        createdAt: DateTime(2026, 9, 1),
      ),
      client: null,
      paiements: [paiement('p1', 40000)],
    );

    expect(d.benefice, 108000, reason: '150 000 − 42 000');
    expect(d.solde, 110000, reason: 'et la cliente doit encore 110 000');
  });

  test('livrer n\'efface pas la dette : elle reste dans le total', () {
    // Le total de l'écran ne comptait que les commandes à livrer. Une cliente
    // qui avait emporté sa commande en devant 150 000 F sortait du compte, et
    // l'écran annonçait « reste à encaisser : 0 » avec 150 000 F dehors.
    //
    // C'est même là que la dette devient gênante : la marchandise est partie.
    final livreeAvecDette = DossierAvecSolde(
      dossier: LocalDossiersCommande(
        id: 'd1',
        shopId: 'shop-1',
        clientId: 'c1',
        categorie: 'gateau',
        description: 'Gâteau',
        details: '{}',
        montantAccepte: 200000,
        statut: 'terminee',
        createdAt: DateTime(2026, 9, 1),
      ),
      client: null,
      paiements: [paiement('p1', 50000)],
    );

    expect(livreeAvecDette.estLivree, isTrue);
    expect(
      livreeAvecDette.solde,
      150000,
      reason: 'la dette survit à la livraison',
    );

    // La règle du total : tout sauf les annulées, et seulement les soldes
    // positifs — une commande soldée ne retranche rien.
    final toutes = [
      livreeAvecDette,
      DossierAvecSolde(
        dossier: dossier(montant: 60000),
        client: null,
        paiements: [paiement('p2', 60000)],
      ),
    ];
    final total = toutes
        .where((d) => !d.estAnnulee && (d.solde ?? 0) > 0)
        .fold<int>(0, (somme, d) => somme + d.solde!);
    expect(total, 150000);
  });

  test('en retard se compare au JOUR, pas à l\'instant', () {
    // Une commande promise pour aujourd'hui n'est pas en retard à 8 h du
    // matin. Sans ce détail, tout ce qui est dû dans la journée s'afficherait
    // en rouge dès l'ouverture — et l'alerte deviendrait un décor.
    DossierAvecSolde avecDate(DateTime? quand, {String statut = 'confirmee'}) =>
        DossierAvecSolde(
          dossier: LocalDossiersCommande(
            id: 'd1',
            shopId: 'shop-1',
            clientId: 'c1',
            categorie: 'gateau',
            description: 'Gâteau',
            details: '{}',
            montantAccepte: 50000,
            datePrevue: quand,
            statut: statut,
            createdAt: DateTime(2026, 9, 1),
          ),
          client: null,
          paiements: const [],
        );

    final maintenant = DateTime.now();
    final aujourdhui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );

    expect(
      avecDate(aujourdhui.add(const Duration(hours: 2))).estEnRetard,
      isFalse,
      reason: 'promise aujourd\'hui : la journée n\'est pas finie',
    );
    expect(
      avecDate(aujourdhui.subtract(const Duration(days: 1))).estEnRetard,
      isTrue,
    );
    expect(
      avecDate(null).estEnRetard,
      isFalse,
      reason: 'sans date promise, aucun retard possible',
    );
    // Une commande livrée ou annulée n'est jamais en retard : le travail est
    // fait, ou il n\'y en a plus.
    expect(
      avecDate(
        aujourdhui.subtract(const Duration(days: 5)),
        statut: 'terminee',
      ).estEnRetard,
      isFalse,
    );
    expect(
      avecDate(
        aujourdhui.subtract(const Duration(days: 5)),
        statut: 'annulee',
      ).estEnRetard,
      isFalse,
    );
  });

  test('sur une commande annulée, c\'est la BOUTIQUE qui doit', () {
    // Vu à l'écran le 04/09 : « RESTE À PAYER 170 000 F » sur une commande
    // annulée dont la cliente avait versé 110 000 et reçu 100 000. Elle ne doit
    // rien — la boutique lui doit les 10 000 gardés.
    //
    // Réclamer 170 000 F à quelqu'un qu'on doit rembourser, c'est le genre
    // d'erreur qui coûte une cliente.
    final annulee = DossierAvecSolde(
      dossier: LocalDossiersCommande(
        id: 'd1',
        shopId: 'shop-1',
        clientId: 'c1',
        categorie: 'decoration_evenementielle',
        description: 'Déco',
        details: '{}',
        montantAccepte: 180000,
        statut: 'annulee',
        createdAt: DateTime(2026, 9, 1),
      ),
      client: null,
      paiements: [
        paiement('p1', 60000),
        paiement('p2', 50000),
        paiement('p3', 100000, type: 'remboursement'),
      ],
    );

    expect(annulee.estAnnulee, isTrue);
    expect(
      annulee.netEncaisse,
      10000,
      reason: 'ce que la boutique garde encore, et doit rendre',
    );
    // `solde` reste 170 000 — c'est arithmétiquement vrai, et c'est pour ça que
    // l'écran ne doit PAS l'afficher tel quel sur une annulée : le nombre est
    // juste, la phrase qui l'accompagnait était fausse.
    expect(annulee.solde, 170000);
  });
}

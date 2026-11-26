import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/web/web_activity_log.dart';

void main() {
  const roles = {'patron-1': 'owner', 'vendeuse-1': 'seller'};

  group('libelleMouvementCaisse', () {
    test('reprend les termes de l’Android', () {
      expect(
        libelleMouvementCaisse('morning_balance'),
        'Initialisation de la caisse',
      );
      expect(libelleMouvementCaisse('incoming'), 'Entrée de caisse');
      expect(libelleMouvementCaisse('withdrawal'), 'Sortie de caisse');
      expect(
        libelleMouvementCaisse('adjustment_in'),
        'Ajustement positif de caisse',
      );
      expect(
        libelleMouvementCaisse('adjustment_out'),
        'Ajustement négatif de caisse',
      );
    });

    test('un type inconnu reste lisible', () {
      expect(libelleMouvementCaisse('zigzag'), 'Mouvement de caisse');
      expect(libelleMouvementCaisse(null), 'Mouvement de caisse');
    });
  });

  group('nommerAuteurWeb', () {
    test('répond « qui », pas un identifiant', () {
      expect(nommerAuteurWeb('patron-1', roles), 'la patronne');
      expect(nommerAuteurWeb('vendeuse-1', roles), 'la vendeuse');
    });

    test('un compte retiré de la boutique garde un repli court', () {
      expect(
        nommerAuteurWeb('8f3c2b1a-aaaa-bbbb-cccc-dddddddddddd', roles),
        'utilisateur 8f3c2b1a',
      );
    });

    test('sans auteur, ne devine pas', () {
      expect(nommerAuteurWeb(null, roles), 'auteur inconnu');
    });
  });

  group('fusionnerJournalAudit', () {
    List<WebActivityEntry> fusion({
      List<Map<String, dynamic>> ventes = const [],
      List<Map<String, dynamic>> caisse = const [],
      List<Map<String, dynamic>> stock = const [],
      List<Map<String, dynamic>> clotures = const [],
      Map<String, String> noms = const {},
    }) => fusionnerJournalAudit(
      ventes: ventes,
      mouvementsCaisse: caisse,
      mouvementsStock: stock,
      clotures: clotures,
      roles: roles,
      nomsProduits: noms,
    );

    test('trie les quatre sources du plus récent au plus ancien', () {
      final lignes = fusion(
        ventes: [
          {
            'total_amount': 1000,
            'user_id': 'vendeuse-1',
            'created_at': '2026-11-18T08:00:00Z',
          },
        ],
        caisse: [
          {
            'type': 'withdrawal',
            'amount': 500,
            'user_id': 'patron-1',
            'created_at': '2026-11-19T08:00:00Z',
          },
        ],
        stock: [
          {
            'product_id': 'p1',
            'quantity': 12,
            'type': 'recharge',
            'created_at': '2026-11-17T08:00:00Z',
          },
        ],
        clotures: [
          {
            'closing_date': '2026-11-16',
            'closed_at': '2026-11-20T18:00:00Z',
            'cash_gap': -200,
            'user_id': 'patron-1',
          },
        ],
      );
      expect(lignes.map((l) => l.titre).toList(), [
        // La clôture est rangée à l'instant du geste (closed_at, le 20), pas à
        // la journée concernée (le 16) : une journée rouverte puis reclôturée
        // doit apparaître au moment de la reclôture.
        'Clôture de caisse',
        'Sortie de caisse',
        'Vente enregistrée',
        'Mouvement de stock',
      ]);
    });

    test('un mouvement de stock n’annonce pas d’auteur', () {
      // `stock_movements` ne porte pas de colonne d'auteur côté serveur.
      // L'écran Android y met l'identifiant de la boutique, ce qui affiche
      // « par utilisateur <boutique> » — un auteur inventé.
      final lignes = fusion(
        stock: [
          {
            'product_id': 'p1',
            'quantity': 3,
            'type': 'adjustment',
            'created_at': '2026-11-17T08:00:00Z',
          },
        ],
        noms: {'p1': 'Savon'},
      );
      expect(lignes.single.auteur, isNull);
      expect(lignes.single.detail, contains('Savon'));
      expect(lignes.single.detail, contains('Correction de stock'));
    });

    test('le signe du mouvement de caisse suit son sens', () {
      final lignes = fusion(
        caisse: [
          {
            'type': 'incoming',
            'amount': 300,
            'user_id': 'patron-1',
            'created_at': '2026-11-19T08:00:00Z',
          },
          {
            'type': 'withdrawal',
            'amount': 400,
            'user_id': 'patron-1',
            'created_at': '2026-11-18T08:00:00Z',
          },
        ],
      );
      expect(lignes.first.detail, startsWith('+'));
      expect(lignes.last.detail, startsWith('-'));
    });

    test('une clôture sans comptage ne montre pas un écart de zéro', () {
      final lignes = fusion(
        clotures: [
          {
            'closing_date': '2026-11-16',
            'closed_at': '2026-11-16T18:00:00Z',
            'cash_gap': null,
            'user_id': 'patron-1',
          },
        ],
      );
      expect(lignes.single.detail, 'Sans comptage du tiroir');
      expect(lignes.single.detail, isNot(contains('0 FCFA')));
    });

    test('une ligne sans date est ignorée, pas datée d’aujourd’hui', () {
      final lignes = fusion(
        ventes: [
          {'total_amount': 10, 'user_id': 'patron-1', 'created_at': null},
        ],
      );
      expect(lignes, isEmpty);
    });

    test('une note est reprise dans le détail', () {
      final lignes = fusion(
        caisse: [
          {
            'type': 'withdrawal',
            'amount': 400,
            'note': 'taxi marché',
            'user_id': 'patron-1',
            'created_at': '2026-11-18T08:00:00Z',
          },
        ],
      );
      expect(lignes.single.detail, contains('taxi marché'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'web_bilan_detail.dart';
import 'web_theme.dart';

/// Sections chiffrées du bilan et de la caisse.
///
/// Sorties de `web_app.dart` pour deux raisons : elles y étaient noyées dans
/// une classe d'état de plusieurs milliers de lignes, et surtout elles n'y
/// étaient pas rendables dans un test — donc jamais vérifiées sur un petit
/// écran, où ce projet a déjà caché du contenu trois fois.
///
/// Toutes prennent leur formateur de montant : la casse FCFA appartient à
/// l'écran appelant, pas à ces blocs.
typedef FormateurMontant = String Function(num montant);

int _entier(Object? valeur) => (valeur as num?)?.round() ?? 0;

/// Un intitulé de section, en petites capitales espacées.
class TitreSection extends StatelessWidget {
  const TitreSection(this.titre, {super.key});

  final String titre;

  @override
  Widget build(BuildContext context) => Text(
    titre,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: WebPalette.muted,
      letterSpacing: 1.2,
    ),
  );
}

/// Un libellé au-dessus de son montant.
class LigneChiffre extends StatelessWidget {
  const LigneChiffre(this.titre, this.valeur, {super.key});

  final String titre;
  final String valeur;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        titre.toUpperCase(),
        style: const TextStyle(
          color: WebPalette.muted,
          fontSize: 10,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(valeur, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

/// Les quatre tranches de jours, barres relatives au meilleur du mois.
///
/// Relatives au mois et non à un maximum absolu : c'est le rythme du mois
/// qu'on lit ici, pas une comparaison entre mois.
class BarresSemaines extends StatelessWidget {
  const BarresSemaines({
    super.key,
    required this.clotures,
    required this.fcfa,
  });

  final List<Map<String, dynamic>> clotures;
  final FormateurMontant fcfa;

  @override
  Widget build(BuildContext context) {
    final tranches = ventesParSemaine(clotures);
    final maximum = tranches.fold<int>(0, (a, b) => b > a ? b : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tranches.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        libellesSemaines[i],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    // Le montant peut être long et le texte grossi : il doit
                    // rétrécir plutôt que déborder de la ligne.
                    Flexible(
                      child: Text(
                        fcfa(tranches[i]),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: maximum == 0 ? 0 : tranches[i] / maximum,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE2EAE7),
                    valueColor: const AlwaysStoppedAnimation(WebPalette.pine),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Manques, surplus, et le nombre de tiroirs réellement comptés.
class BlocEcartsDeCaisse extends StatelessWidget {
  const BlocEcartsDeCaisse({
    super.key,
    required this.clotures,
    required this.fcfa,
  });

  final List<Map<String, dynamic>> clotures;
  final FormateurMontant fcfa;

  @override
  Widget build(BuildContext context) {
    final ecarts = ecartsDeCaisse(clotures);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trois colonnes de montants ne tiennent pas sur un téléphone
          // étroit avec un texte grossi : elles passent en lignes.
          Wrap(
            spacing: 22,
            runSpacing: 12,
            children: [
              LigneChiffre('Manques', fcfa(ecarts.manques)),
              LigneChiffre('Surplus', fcfa(ecarts.surplus)),
              LigneChiffre('Solde des écarts', fcfa(ecarts.total)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ecarts.journeesComptees == 0
                ? 'Aucun tiroir compté ce mois-ci : il n’y a donc aucun écart à '
                      'constater, ce qui n’est pas la même chose qu’une caisse juste.'
                : '${ecarts.journeesComptees} journée(s) dont le tiroir a été '
                      'réellement compté.',
            style: const TextStyle(color: WebPalette.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Le jour par jour, en tableau qui défile horizontalement.
///
/// Il défile plutôt qu'il ne rétrécit : cinq colonnes de montants tronquées
/// sur un téléphone donneraient des chiffres faux à la lecture.
class TableauParJour extends StatelessWidget {
  const TableauParJour({super.key, required this.clotures, required this.fcfa});

  final List<Map<String, dynamic>> clotures;
  final FormateurMontant fcfa;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2EAE7)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 22,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF2F6F4)),
        columns: const [
          DataColumn(label: Text('Jour')),
          DataColumn(label: Text('Ventes')),
          DataColumn(label: Text('Bénéfice')),
          DataColumn(label: Text('Comptée')),
          DataColumn(label: Text('Écart')),
        ],
        rows: [
          for (final cloture in clotures)
            DataRow(
              cells: [
                DataCell(Text(_jourCourt(cloture))),
                DataCell(Text(fcfa(_entier(cloture['total_sales'])))),
                DataCell(Text(fcfa(_entier(cloture['net_profit'])))),
                // Un tiroir non compté garde un tiret : imprimer 0 ferait
                // croire à une caisse vérifiée et vide.
                DataCell(
                  Text(
                    cloture['physical_cash'] == null
                        ? '—'
                        : fcfa(_entier(cloture['physical_cash'])),
                  ),
                ),
                DataCell(
                  cloture['cash_gap'] == null
                      ? const Text('—')
                      : Text(
                          fcfa(_entier(cloture['cash_gap'])),
                          style: TextStyle(
                            color: _entier(cloture['cash_gap']) < 0
                                ? WebPalette.danger
                                : WebPalette.pine,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

String _jourCourt(Map<String, dynamic> cloture) {
  final jour = jourDeCloture(cloture);
  return jour == null
      ? '${cloture['closing_date']}'
      : DateFormat('dd/MM').format(jour);
}

/// Les journées à ventes qu'aucune clôture ne couvre.
class AvertissementJourneesOubliees extends StatelessWidget {
  const AvertissementJourneesOubliees({super.key, required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF2D5A8)),
    ),
    child: Text(
      '$nombre journée(s) avec des ventes n’ont jamais été clôturées. Leurs '
      'ventes sont comptées ici — l’argent est bien entré — mais le tiroir '
      'n’a pas été vérifié ces jours-là.',
      style: const TextStyle(fontSize: 13, height: 1.45),
    ),
  );
}

/// Une journée clôturée, telle qu'elle a été enregistrée.
class CarteCloture extends StatelessWidget {
  const CarteCloture({super.key, required this.cloture, required this.fcfa});

  final Map<String, dynamic> cloture;
  final FormateurMontant fcfa;

  @override
  Widget build(BuildContext context) {
    final jour = jourDeCloture(cloture);
    final ecart = cloture['cash_gap'] as num?;
    final comptee = cloture['physical_cash'] as num?;
    final note = cloture['note'] as String?;
    // Un écart nul et une absence de comptage ne s'affichent pas pareil :
    // sans comptage, personne n'a vérifié le tiroir ce jour-là.
    final (libelle, couleur) = switch (ecart) {
      null => ('Tiroir non compté', WebPalette.muted),
      final valeur when valeur < 0 => (
        'Manque ${fcfa(valeur.abs())}',
        WebPalette.danger,
      ),
      final valeur when valeur > 0 => (
        'Surplus ${fcfa(valeur)}',
        WebPalette.pine,
      ),
      _ => ('Caisse juste', WebPalette.pine),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La date longue et l'écart côte à côte débordaient avec un texte
          // grossi : ils s'empilent quand la largeur ne suffit pas.
          Wrap(
            spacing: 12,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                jour == null
                    ? '${cloture['closing_date']}'
                    : DateFormat('EEEE d MMMM yyyy', 'fr').format(jour),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                libelle,
                style: TextStyle(color: couleur, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              LigneChiffre('Ventes', fcfa(_entier(cloture['total_sales']))),
              LigneChiffre(
                'Sorties',
                fcfa(_entier(cloture['total_withdrawals'])),
              ),
              LigneChiffre(
                'Calculée',
                fcfa(_entier(cloture['calculated_cash'])),
              ),
              LigneChiffre('Comptée', comptee == null ? '—' : fcfa(comptee)),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(color: WebPalette.muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

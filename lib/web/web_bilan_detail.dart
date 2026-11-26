import 'web_cameroun_time.dart';

/// Découpages du bilan mensuel, repris de l'écran Android.
///
/// Fonctions pures, volontairement séparées de l'écran et du PDF : les deux
/// affichent les mêmes chiffres, et un calcul dupliqué aurait fini par donner
/// deux totaux différents pour le même mois.

/// Les quatre tranches de l'Android : 1-7, 8-14, 15-21, 22-fin.
///
/// La dernière absorbe le reste du mois, donc 7, 8 ou 9 jours selon le mois.
/// C'est un choix d'affichage de l'Android, pas un découpage ISO : le garder
/// identique permet de comparer un bilan web et un bilan téléphone sans se
/// demander lequel des deux a raison.
const libellesSemaines = [
  'Sem. 1 (1-7)',
  'Sem. 2 (8-14)',
  'Sem. 3 (15-21)',
  'Sem. 4 (22-fin)',
];

int _trancheDuJour(int jour) {
  if (jour <= 7) return 0;
  if (jour <= 14) return 1;
  if (jour <= 21) return 2;
  return 3;
}

int _entier(Object? valeur) => (valeur as num?)?.round() ?? 0;

/// Jour d'une clôture : `closing_date` est une date nue (`YYYY-MM-DD`), donc
/// sans fuseau à interpréter. On ne la passe pas par `DateTime.parse` suivi
/// d'un `toLocal()` : un navigateur à l'ouest de Greenwich reculerait d'un
/// jour et ferait glisser la clôture du 1er dans la tranche du mois précédent.
DateTime? jourDeCloture(Map<String, dynamic> cloture) {
  final brut = cloture['closing_date'] as String?;
  if (brut == null || brut.length < 10) return null;
  final annee = int.tryParse(brut.substring(0, 4));
  final mois = int.tryParse(brut.substring(5, 7));
  final jour = int.tryParse(brut.substring(8, 10));
  if (annee == null || mois == null || jour == null) return null;
  return DateTime(annee, mois, jour);
}

/// Ventes par tranche, calculées sur les clôtures comme sur l'Android.
List<int> ventesParSemaine(List<Map<String, dynamic>> clotures) {
  final tranches = [0, 0, 0, 0];
  for (final cloture in clotures) {
    final jour = jourDeCloture(cloture);
    if (jour == null) continue;
    tranches[_trancheDuJour(jour.day)] += _entier(cloture['total_sales']);
  }
  return tranches;
}

/// Manques et surplus du mois.
///
/// Une journée clôturée sans comptage physique n'a pas d'écart : `cash_gap`
/// est nul, et un nul n'est ni un manque ni un surplus. Le compter comme un
/// surplus de 0 était sans effet sur le total, mais faisait annoncer « 12
/// journées vérifiées » pour trois comptages réels.
class EcartsDeCaisse {
  const EcartsDeCaisse({
    required this.manques,
    required this.surplus,
    required this.journeesComptees,
  });

  final int manques;
  final int surplus;

  /// Journées dont le tiroir a réellement été compté.
  final int journeesComptees;

  int get total => surplus - manques;
}

EcartsDeCaisse ecartsDeCaisse(List<Map<String, dynamic>> clotures) {
  var manques = 0;
  var surplus = 0;
  var comptees = 0;
  for (final cloture in clotures) {
    if (cloture['cash_gap'] == null) continue;
    comptees++;
    final ecart = _entier(cloture['cash_gap']);
    if (ecart < 0) {
      manques += -ecart;
    } else {
      surplus += ecart;
    }
  }
  return EcartsDeCaisse(
    manques: manques,
    surplus: surplus,
    journeesComptees: comptees,
  );
}

/// Journées qui ont des ventes mais aucune clôture.
///
/// Reprend l'avertissement de l'Android : ces ventes sont réelles et entrent
/// dans les totaux, mais personne n'a vérifié le tiroir ce jour-là. Le mois
/// est donc exact sur ce qui est entré, et muet sur ce qui a pu en sortir sans
/// trace. Le dire vaut mieux que laisser croire à un chiffre vérifié.
///
/// Le jour en cours ne compte pas : à 10 h du matin, une journée pas encore
/// clôturée est normale, pas oubliée.
int journeesNonCloturees({
  required List<Map<String, dynamic>> ventes,
  required List<Map<String, dynamic>> clotures,
  required DateTime aujourdhui,
}) {
  final joursCloture = <String>{
    for (final cloture in clotures)
      if (cloture['closing_date'] != null)
        (cloture['closing_date'] as String).substring(0, 10),
  };
  final joursVendus = <String>{};
  for (final vente in ventes) {
    final brut = vente['created_at'] as String?;
    if (brut == null) continue;
    final instant = DateTime.tryParse(brut);
    if (instant == null) continue;
    final jour = heureCameroun(instant);
    final cle =
        '${jour.year}-${jour.month.toString().padLeft(2, '0')}-${jour.day.toString().padLeft(2, '0')}';
    final cleDuJour =
        '${aujourdhui.year}-${aujourdhui.month.toString().padLeft(2, '0')}-${aujourdhui.day.toString().padLeft(2, '0')}';
    if (cle == cleDuJour) continue;
    joursVendus.add(cle);
  }
  return joursVendus.difference(joursCloture).length;
}

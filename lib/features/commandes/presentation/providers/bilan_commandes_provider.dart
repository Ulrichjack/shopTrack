import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/sync/sync_service.dart';
import 'commandes_provider.dart';

/// Ce que les commandes ont rapporté sur une période.
///
/// Volontairement SÉPARÉ du bilan boutique, jamais additionné. Les deux n'ont
/// pas le même rythme : un acompte d'août pour un gâteau livré en septembre
/// appartient à septembre. Les mélanger rendrait les deux illisibles, et
/// changerait des chiffres boutique que personne n'a demandé à changer.
class BilanCommandes {
  const BilanCommandes({
    required this.chiffreAffaires,
    required this.cout,
    required this.nombreLivrees,
    required this.livreesSansCout,
    required this.encoreDu,
    required this.semaines,
    required this.debitrices,
  });

  /// Le prix des commandes LIVRÉES sur la période. Un acompte n'y entre pas :
  /// ce n'est pas un gain, c'est de l'argent avancé.
  final int chiffreAffaires;

  /// Ce qu'elles ont coûté, pour celles où c'est renseigné.
  final int cout;

  final int nombreLivrees;

  /// Livrées sans coût saisi. À AFFICHER, pas à cacher : si elle en livre dix
  /// et n'en chiffre que huit, le bénéfice montré est trop beau. Le taire la
  /// ferait décider sur un chiffre incomplet.
  final int livreesSansCout;

  /// Ce que les clientes doivent encore, toutes commandes en cours confondues.
  /// Hors bénéfice, toujours : c'est attendu, pas gagné.
  final int encoreDu;

  final List<SemaineCommandes> semaines;

  /// Qui doit, et combien. Trié du plus gros au plus petit.
  ///
  /// « Encore dû : 110 000 F » sans savoir par qui est une information à
  /// moitié utile pour une propriétaire à distance qui lit un bilan une fois
  /// par semaine : elle ne peut ni appeler, ni relancer.
  final List<ClienteDebitrice> debitrices;

  /// Nul tant qu'aucune commande livrée n'a de coût : afficher le chiffre
  /// d'affaires comme un bénéfice serait le mensonge le plus facile à faire.
  int? get benefice =>
      nombreLivrees == livreesSansCout ? null : chiffreAffaires - cout;

  bool get estVide => nombreLivrees == 0 && encoreDu == 0;
}

class ClienteDebitrice {
  const ClienteDebitrice({
    required this.nom,
    required this.montant,
    required this.livree,
  });

  final String nom;
  final int montant;

  /// Livrée et impayée : la marchandise est partie, la dette n'est plus
  /// garantie par rien. C'est la ligne qu'il faut relancer en premier.
  final bool livree;
}

class SemaineCommandes {
  const SemaineCommandes({
    required this.debut,
    required this.fin,
    required this.chiffreAffaires,
    required this.cout,
    required this.nombreLivrees,
    required this.avecCoutManquant,
  });

  final DateTime debut;
  final DateTime fin;
  final int chiffreAffaires;
  final int cout;
  final int nombreLivrees;
  final bool avecCoutManquant;

  int? get benefice =>
      avecCoutManquant && cout == 0 ? null : chiffreAffaires - cout;
}

/// Le bilan des commandes d'un mois donné.
final bilanCommandesProvider = FutureProvider.family<BilanCommandes, DateTime>((
  ref,
  mois,
) async {
  final shopId = await watchShopId(ref);
  final db = ref.watch(localDbProvider);

  final debut = DateTime(mois.year, mois.month, 1);
  final fin = DateTime(mois.year, mois.month + 1, 1);

  final dossiers = await (db.select(
    db.localDossiersCommandes,
  )..where((row) => row.shopId.equals(shopId))).get();
  final paiements = await (db.select(
    db.localPaiementsCommandes,
  )..where((row) => row.shopId.equals(shopId))).get();

  final parDossier = <String, List<LocalPaiementsCommande>>{};
  for (final p in paiements) {
    parDossier.putIfAbsent(p.dossierId, () => []).add(p);
  }

  // Livrées DANS le mois — d'après la date de livraison réelle, jamais la date
  // prévue ni celle de la commande.
  final livrees = dossiers.where((d) {
    final quand = d.livreeAt;
    if (d.statut != 'terminee' || quand == null) return false;
    return !quand.isBefore(debut) && quand.isBefore(fin);
  }).toList();

  int chiffreAffaires = 0;
  int cout = 0;
  int sansCout = 0;
  for (final d in livrees) {
    chiffreAffaires += d.montantAccepte ?? 0;
    if (d.coutMatiere == null) {
      sansCout++;
    } else {
      cout += d.coutMatiere!;
    }
  }

  // Ce qui est encore dû ne dépend PAS du mois : une cliente qui doit depuis
  // juillet doit toujours en septembre. Découper cette dette par mois la
  // ferait disparaître de l'écran le 1er du mois suivant.
  final clients = await (db.select(
    db.localClients,
  )..where((row) => row.shopId.equals(shopId))).get();
  final parClient = {for (final c in clients) c.id: c};

  var encoreDu = 0;
  final debitrices = <ClienteDebitrice>[];
  for (final d in dossiers) {
    if (d.statut == 'annulee' || d.montantAccepte == null) continue;
    final solde = DossierAvecSolde(
      dossier: d,
      client: null,
      paiements: parDossier[d.id] ?? const [],
    ).solde;
    if (solde == null || solde <= 0) continue;
    encoreDu += solde;
    debitrices.add(
      ClienteDebitrice(
        nom: parClient[d.clientId]?.nom ?? 'Client',
        montant: solde,
        livree: d.statut == 'terminee',
      ),
    );
  }
  // Du plus gros au plus petit : c'est par là qu'on commence à relancer.
  debitrices.sort((a, b) => b.montant.compareTo(a.montant));

  return BilanCommandes(
    chiffreAffaires: chiffreAffaires,
    cout: cout,
    nombreLivrees: livrees.length,
    livreesSansCout: sansCout,
    encoreDu: encoreDu,
    debitrices: debitrices,
    semaines: decouperEnSemaines(livrees, debut, fin),
  );
});

/// Découpe le mois en semaines calendaires, du lundi au dimanche.
///
/// Elle regarde l'application une fois par semaine sans savoir quel jour. Un
/// sélecteur de dates l'obligerait à choisir ; le découpage lui montre
/// directement où elle en est, et lui permet de comparer avec la précédente.
List<SemaineCommandes> decouperEnSemaines(
  List<LocalDossiersCommande> livrees,
  DateTime debut,
  DateTime fin,
) {
  final semaines = <SemaineCommandes>[];
  // On recule jusqu'au lundi : une semaine coupée au 1er du mois ne se compare
  // à rien, et le commerçant, lui, compte en semaines entières.
  var curseur = debut.subtract(Duration(days: debut.weekday - 1));

  while (curseur.isBefore(fin)) {
    final finSemaine = curseur.add(const Duration(days: 7));
    final dedans = livrees.where((d) {
      final quand = d.livreeAt!;
      return !quand.isBefore(curseur) && quand.isBefore(finSemaine);
    }).toList();

    if (dedans.isNotEmpty) {
      int ca = 0;
      int cout = 0;
      var manquant = false;
      for (final d in dedans) {
        ca += d.montantAccepte ?? 0;
        if (d.coutMatiere == null) {
          manquant = true;
        } else {
          cout += d.coutMatiere!;
        }
      }
      semaines.add(
        SemaineCommandes(
          debut: curseur,
          fin: finSemaine.subtract(const Duration(days: 1)),
          chiffreAffaires: ca,
          cout: cout,
          nombreLivrees: dedans.length,
          avecCoutManquant: manquant,
        ),
      );
    }
    curseur = finSemaine;
  }
  return semaines;
}

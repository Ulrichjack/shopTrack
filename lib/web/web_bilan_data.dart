import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/daily_cash_calculator.dart';
import 'web_cameroun_time.dart';

/// Bilan mensuel des données confirmées par le serveur de test.
/// Les acomptes de commandes ne sont pas additionnés aux ventes : une commande
/// entre dans son bilan seulement le mois de sa livraison effective.
class WebBilanData {
  const WebBilanData({
    required this.nombreVentes,
    required this.totalVentes,
    required this.nombreRecettes,
    required this.totalRecettes,
    required this.commandesLivrees,
    required this.totalCommandesLivrees,
    required this.coutCommandesConnu,
    required this.commandesSansCout,
    required this.encoreDuCommandes,
    this.beneficeBrutVentes,
    this.depenses = 0,
    this.deplacements = 0,
    this.clotures = const [],
  });

  final int nombreVentes;
  final int totalVentes;
  final int nombreRecettes;
  final int totalRecettes;
  final int commandesLivrees;
  final int totalCommandesLivrees;
  final int coutCommandesConnu;
  final int commandesSansCout;
  final int encoreDuCommandes;
  final int? beneficeBrutVentes;
  final int depenses;
  final int deplacements;
  final List<Map<String, dynamic>> clotures;

  int? get beneficeNetVentes =>
      beneficeBrutVentes == null ? null : beneficeBrutVentes! - depenses;

  int? get beneficeCommandes => commandesLivrees == 0 || commandesSansCout > 0
      ? null
      : totalCommandesLivrees - coutCommandesConnu;
}

Future<List<Map<String, dynamic>>> _toutesLesLignes(
  Future<List<Map<String, dynamic>>> Function(int debut, int fin) lire,
) async {
  final lignes = <Map<String, dynamic>>[];
  for (var debut = 0; ; debut += 500) {
    final page = await lire(debut, debut + 499);
    lignes.addAll(page);
    if (page.length < 500) break;
  }
  return lignes;
}

Future<WebBilanData> chargerBilanWeb(
  SupabaseClient client, {
  required String shopId,
  required DateTime mois,
  required bool inventairePeriodique,
  required bool commandesActives,
}) async {
  final debutLocal = DateTime(mois.year, mois.month);
  final finLocale = DateTime(mois.year, mois.month + 1);
  final debutUtc = debutMoisCamerounUtc(mois).toIso8601String();
  final finUtc = finMoisCamerounUtc(mois).toIso8601String();
  final debutDate =
      '${debutLocal.year}-${debutLocal.month.toString().padLeft(2, '0')}-01';
  final finDate =
      '${finLocale.year}-${finLocale.month.toString().padLeft(2, '0')}-01';

  final ventes = inventairePeriodique
      ? <Map<String, dynamic>>[]
      : await _toutesLesLignes(
          (debut, fin) => client
              .from('sales')
              .select('id,total_amount,total_profit')
              .eq('shop_id', shopId)
              .gte('created_at', debutUtc)
              .lt('created_at', finUtc)
              .order('id')
              .range(debut, fin),
        );
  final mouvements = inventairePeriodique
      ? <Map<String, dynamic>>[]
      : await _toutesLesLignes(
          (debut, fin) => client
              .from('cash_movements')
              .select('id,type,amount,category')
              .eq('shop_id', shopId)
              .eq('type', 'withdrawal')
              .gte('created_at', debutUtc)
              .lt('created_at', finUtc)
              .order('id')
              .range(debut, fin),
        );
  final clotures = inventairePeriodique
      ? <Map<String, dynamic>>[]
      : await _toutesLesLignes(
          (debut, fin) => client
              .from('daily_closings')
              .select('id,closing_date,total_sales,gross_profit,net_profit,physical_cash,cash_gap,note')
              .eq('shop_id', shopId)
              .eq('is_closed', true)
              .gte('closing_date', debutDate)
              .lt('closing_date', finDate)
              .order('closing_date')
              .range(debut, fin),
        );
  final recettes = !inventairePeriodique
      ? <Map<String, dynamic>>[]
      : await _toutesLesLignes(
          (debut, fin) => client
              .from('shop_takings')
              .select('id,amount')
              .eq('shop_id', shopId)
              .gte('date', debutDate)
              .lt('date', finDate)
              .order('id')
              .range(debut, fin),
        );
  final livrees = !commandesActives
      ? <Map<String, dynamic>>[]
      : await _toutesLesLignes(
          (debut, fin) => client
              .from('dossiers_commandes')
              .select('id,montant_accepte,cout_matiere')
              .eq('shop_id', shopId)
              .eq('statut', 'terminee')
              .gte('livree_at', debutUtc)
              .lt('livree_at', finUtc)
              .order('id')
              .range(debut, fin),
        );
  final creances = !commandesActives
      ? <Map<String, dynamic>>[]
      : await _toutesLesLignes(
          (debut, fin) => client
              .from('dossiers_commandes_avec_solde')
              .select('id,solde')
              .eq('shop_id', shopId)
              .neq('statut', 'annulee')
              .gt('solde', 0)
              .order('id')
              .range(debut, fin),
        );

  int somme(List<Map<String, dynamic>> lignes, String colonne) => lignes.fold(
    0,
    (total, ligne) => total + ((ligne[colonne] as num?)?.round() ?? 0),
  );

  return WebBilanData(
    nombreVentes: ventes.length,
    totalVentes: somme(ventes, 'total_amount'),
    nombreRecettes: recettes.length,
    totalRecettes: somme(recettes, 'amount'),
    commandesLivrees: livrees.length,
    totalCommandesLivrees: somme(livrees, 'montant_accepte'),
    coutCommandesConnu: somme(livrees, 'cout_matiere'),
    commandesSansCout: livrees.where((d) => d['cout_matiere'] == null).length,
    encoreDuCommandes: somme(creances, 'solde'),
    beneficeBrutVentes: inventairePeriodique ||
            ventes.any((vente) => vente['total_profit'] == null)
        ? null
        : somme(ventes, 'total_profit'),
    depenses: mouvements
        .where((m) => !categoriesSansImpactSurLeBenefice.contains(m['category']))
        .fold<int>(0, (total, m) => total + ((m['amount'] as num?)?.round() ?? 0)),
    deplacements: mouvements
        .where((m) => categoriesSansImpactSurLeBenefice.contains(m['category']))
        .fold<int>(0, (total, m) => total + ((m['amount'] as num?)?.round() ?? 0)),
    clotures: clotures,
  );
}

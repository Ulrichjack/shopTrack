import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/daily_cash_calculator.dart';
import 'web_cameroun_time.dart';

class WebCashData {
  const WebCashData({
    required this.totaux,
    required this.mouvementsRecents,
    required this.aDesOperations,
    required this.clotureAujourdhui,
    required this.derniereCloture,
  });

  final DailyCashTotals totaux;
  final List<Map<String, dynamic>> mouvementsRecents;
  final bool aDesOperations;
  final bool clotureAujourdhui;
  final Map<String, dynamic>? derniereCloture;
}

Future<List<Map<String, dynamic>>> _chargerToutesLesLignes(
  Future<List<Map<String, dynamic>>> Function(int, int) lire,
) async {
  final resultat = <Map<String, dynamic>>[];
  for (var debut = 0; ; debut += 500) {
    final page = await lire(debut, debut + 499);
    resultat.addAll(page);
    if (page.length < 500) break;
  }
  return resultat;
}

/// Reprend la frontière de la dernière clôture et le calculateur de l'Android.
Future<WebCashData> chargerCaisseWeb(
  SupabaseClient client, {
  required String shopId,
  required bool estPatron,
}) async {
  final cloture = await client
      .from('daily_closings')
      .select('closing_date,closed_at,physical_cash,calculated_cash,cash_gap,note')
      .eq('shop_id', shopId)
      .eq('is_closed', true)
      .order('closing_date', ascending: false)
      .limit(1)
      .maybeSingle();
  DateTime? debut;
  if (cloture != null) {
    final dateCloture = DateTime.parse(cloture['closing_date'] as String);
    debut = cloture['closed_at'] != null
        ? DateTime.parse(cloture['closed_at'] as String)
        : finJourCamerounUtc(dateCloture);
  }
  final borne = debut?.toUtc().toIso8601String();
  final ventes = await _chargerToutesLesLignes((premier, dernier) {
    var requete = client
        .from('sales')
        .select(estPatron
            ? 'id,total_amount,total_profit,created_at'
            : 'id,total_amount,created_at')
        .eq('shop_id', shopId);
    if (borne != null) requete = requete.gte('created_at', borne);
    return requete.order('created_at').order('id').range(premier, dernier);
  });
  final mouvements = await _chargerToutesLesLignes((premier, dernier) {
    var requete = client
        .from('cash_movements')
        .select('id,type,amount,category,note,created_at')
        .eq('shop_id', shopId);
    if (borne != null) requete = requete.gte('created_at', borne);
    return requete.order('created_at').order('id').range(premier, dernier);
  });
  final ouverture = (cloture?['physical_cash'] as num?) ??
      (cloture?['calculated_cash'] as num?) ?? 0;
  final totaux = DailyCashCalculator.calculate(
    openingBalance: ouverture.toDouble(),
    sales: ventes.map((vente) => SaleValue(
      amount: (vente['total_amount'] as num).toDouble(),
      profit: ((vente['total_profit'] as num?) ?? 0).toDouble(),
      createdAt: DateTime.parse(vente['created_at'] as String).toLocal(),
    )),
    movements: mouvements.map((mouvement) => CashMovementValue(
      type: mouvement['type'] as String,
      amount: (mouvement['amount'] as num).toDouble(),
      category: mouvement['category'] as String?,
      createdAt: DateTime.parse(mouvement['created_at'] as String).toLocal(),
    )),
  );
  return WebCashData(
    totaux: totaux,
    mouvementsRecents: mouvements.reversed.take(20).toList(),
    aDesOperations: cloture != null || ventes.isNotEmpty || mouvements.isNotEmpty,
    clotureAujourdhui: cloture?['closing_date'] ==
        (() {
          final cameroun = DateTime.now().toUtc().add(const Duration(hours: 1));
          return '${cameroun.year}-${cameroun.month.toString().padLeft(2, '0')}-${cameroun.day.toString().padLeft(2, '0')}';
        })(),
    derniereCloture: cloture,
  );
}

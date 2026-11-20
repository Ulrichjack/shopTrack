import 'package:supabase_flutter/supabase_flutter.dart';
import 'web_cameroun_time.dart';

/// Journal confirmé par Supabase. Les données encore dans la file locale
/// d'Android n'apparaissent qu'après leur synchronisation.
class WebJournalEntry {
  const WebJournalEntry({
    required this.id,
    required this.date,
    required this.titre,
    required this.montant,
    required this.estVente,
    required this.details,
  });

  final String id;
  final DateTime date;
  final String titre;
  final int montant;
  final bool estVente;
  final List<String> details;
}

class WebJournalDay {
  const WebJournalDay(this.entrees);
  final List<WebJournalEntry> entrees;

  Iterable<WebJournalEntry> get ventes => entrees.where((e) => e.estVente);
  int get totalVentes => ventes.fold(0, (total, e) => total + e.montant);
  int get nombreVentes => ventes.length;
}

Future<WebJournalDay> chargerJournalWeb(
  SupabaseClient client,
  String shopId,
  DateTime jour,
) async {
  final debut = debutJourCamerounUtc(jour).toIso8601String();
  final fin = finJourCamerounUtc(jour).toIso8601String();

  // Toujours filtrer par shop_id : un compte peut gérer plusieurs boutiques.
  // Ne sélectionner ni prix d'achat, ni marge, ni bénéfice côté vendeur.
  final ventes = await client
      .from('sales')
      .select(
        'id,total_amount,created_at,sale_items(product_name,quantity,sell_price)',
      )
      .eq('shop_id', shopId)
      .gte('created_at', debut)
      .lt('created_at', fin)
      .order('created_at', ascending: false);
  final mouvements = await client
      .from('cash_movements')
      .select('id,amount,type,category,note,created_at')
      .eq('shop_id', shopId)
      .gte('created_at', debut)
      .lt('created_at', fin)
      .order('created_at', ascending: false);

  final entrees = <WebJournalEntry>[
    for (final vente in ventes)
      WebJournalEntry(
        id: vente['id'] as String,
        date: heureCameroun(DateTime.parse(vente['created_at'] as String)),
        titre: 'Vente',
        montant: ((vente['total_amount'] as num?) ?? 0).round(),
        estVente: true,
        details: [
          for (final item in (vente['sale_items'] as List? ?? []))
            '${item['quantity']} × ${item['product_name']} · ${((item['sell_price'] as num?) ?? 0).round()} FCFA / unité',
        ],
      ),
    for (final mouvement in mouvements)
      WebJournalEntry(
        id: mouvement['id'] as String,
        date: heureCameroun(DateTime.parse(mouvement['created_at'] as String)),
        titre: switch (mouvement['type']) {
          'morning_balance' => 'Fonds de caisse',
          'withdrawal' => 'Sortie de caisse',
          'incoming' => 'Entrée de caisse',
          'adjustment_in' => 'Ajustement positif',
          'adjustment_out' => 'Ajustement négatif',
          _ => 'Mouvement de caisse',
        },
        montant: ((mouvement['amount'] as num?) ?? 0).round(),
        estVente: false,
        details: [
          if ((mouvement['category'] as String?)?.isNotEmpty == true)
            mouvement['category'] as String,
          if ((mouvement['note'] as String?)?.isNotEmpty == true)
            mouvement['note'] as String,
        ],
      ),
  ]..sort((a, b) => b.date.compareTo(a.date));
  return WebJournalDay(entrees);
}

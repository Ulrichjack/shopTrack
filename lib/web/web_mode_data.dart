import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Lectures web des modules optionnels. Chaque requête porte le shop_id actif.
/// Les écritures métier seront ajoutées avec leurs règles propres à chaque
/// module ; ces vues ne transforment aucun montant ni stock.
class WebInventaireData {
  const WebInventaireData(this.recettes, this.comptages);
  final List<Map<String, dynamic>> recettes;
  final List<Map<String, dynamic>> comptages;
}

class WebCyclesData {
  const WebCyclesData(this.cycles);
  final List<Map<String, dynamic>> cycles;
}

class WebCommandeData {
  const WebCommandeData(this.dossiers, this.clients);
  final List<Map<String, dynamic>> dossiers;
  final Map<String, String> clients;

  int? solde(Map<String, dynamic> dossier) {
    return (dossier['solde'] as num?)?.round();
  }
}

Future<WebInventaireData> chargerInventaireWeb(
  SupabaseClient client,
  String shopId,
) async {
  final recettes = await client
      .from('shop_takings')
      .select('id,date,amount')
      .eq('shop_id', shopId)
      .order('date', ascending: false)
      .limit(30);
  final comptages = await client
      .from('inventory_counts')
      .select('id,product_id,counted_at,counted_quantity')
      .eq('shop_id', shopId)
      .order('counted_at', ascending: false)
      .limit(500);
  return WebInventaireData(recettes, comptages);
}

/// Même identifiant déterministe qu'Android pour « boutique + date ».
/// Une correction réutilise la ligne existante et ne crée pas une deuxième
/// recette pour le même jour.
Future<void> enregistrerRecetteWeb(
  SupabaseClient client, {
  required String shopId,
  required DateTime date,
  required int montant,
}) async {
  if (montant < 0) throw ArgumentError('Le montant doit être positif ou nul.');
  final isoDate =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final existante = await client
      .from('shop_takings')
      .select('id')
      .eq('shop_id', shopId)
      .eq('date', isoDate)
      .maybeSingle();
  final id =
      (existante?['id'] as String?) ??
      const Uuid().v5(
        Namespace.url.value,
        'shoptrack:takings:$shopId:$isoDate',
      );
  await client.from('shop_takings').upsert({
    'id': id,
    'shop_id': shopId,
    'date': isoDate,
    'amount': montant,
  }, onConflict: 'shop_id,date');
}

Future<WebCyclesData> chargerCyclesWeb(
  SupabaseClient client,
  String shopId,
) async {
  final cycles = await client
      .from('supply_cycles')
      .select('id,product_id,opened_at,quantity_received,status')
      .eq('shop_id', shopId)
      .order('opened_at', ascending: false)
      .limit(100);
  return WebCyclesData(cycles);
}

Future<WebCommandeData> chargerCommandesWeb(
  SupabaseClient client,
  String shopId,
) async {
  final dossiers = await client
      .from('dossiers_commandes_avec_solde')
      .select(
        'id,client_id,categorie,description,montant_accepte,montant_net_encaisse,date_prevue,statut,created_at,solde',
      )
      .eq('shop_id', shopId)
      .order('created_at', ascending: false)
      .limit(100);
  final clients = await client
      .from('clients')
      .select('id,nom')
      .eq('shop_id', shopId);
  final noms = <String, String>{
    for (final client in clients)
      client['id'] as String: client['nom'] as String,
  };
  return WebCommandeData(dossiers, noms);
}

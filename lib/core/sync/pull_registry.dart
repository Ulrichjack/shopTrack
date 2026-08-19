import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';

/// Une table qui descend du serveur, déclarée **à un seul endroit**.
///
/// Le bug le plus cher du projet vient d'avoir écrit chaque table deux fois :
/// la requête distante d'un côté, le mapping vers Drift trois cents lignes
/// plus bas. Oublier un des deux côtés n'échoue jamais bruyamment — le
/// téléchargement réécrit la ligne locale sans le champ et l'efface en
/// silence quelques secondes après sa création. Vu sur `sale_items.cycle_id`,
/// invisible sur un seul téléphone.
///
/// Ici, ajouter une table ou une colonne se fait en un endroit, et
/// `test/sync_pull_coverage_test.dart` vérifie qu'aucune colonne locale n'a
/// été oubliée en chemin.
abstract class TableTiree {
  /// Nom de la table côté Supabase, tel qu'il apparaît dans les traces.
  String get nom;

  /// Colonnes locales sans contrepartie distante, déclarées exprès.
  ///
  /// Tout ce qui n'est pas listé ici **doit** être recopié par [appliquer] :
  /// c'est ce qui permet au test de couverture de distinguer un oubli d'un
  /// choix.
  Set<String> get colonnesLocales;

  /// La table Drift visée.
  TableInfo<Table, dynamic> cible(AppDatabase db);

  Future<dynamic> tirer(SupabaseClient supabase, String shopId);

  void appliquer(AppDatabase db, Batch batch, List<dynamic> lignes);
}

TableTiree _tableTiree<T extends Table, D>({
  required String nom,
  required TableInfo<T, D> Function(AppDatabase db) cible,
  required Future<dynamic> Function(SupabaseClient supabase, String shopId)
  requete,
  required Insertable<D> Function(Map<String, dynamic> ligne) versLigne,
  Set<String> colonnesLocales = const {},
}) {
  return _TableTireeImpl<T, D>(
    nom: nom,
    cibleFn: cible,
    requete: requete,
    versLigne: versLigne,
    colonnesLocales: colonnesLocales,
  );
}

class _TableTireeImpl<T extends Table, D> implements TableTiree {
  const _TableTireeImpl({
    required this.nom,
    required this.colonnesLocales,
    required this.cibleFn,
    required this.requete,
    required this.versLigne,
  });

  @override
  final String nom;

  @override
  final Set<String> colonnesLocales;

  final TableInfo<T, D> Function(AppDatabase) cibleFn;
  final Future<dynamic> Function(SupabaseClient, String) requete;
  final Insertable<D> Function(Map<String, dynamic>) versLigne;

  @override
  TableInfo<Table, dynamic> cible(AppDatabase db) => cibleFn(db);

  @override
  Future<dynamic> tirer(SupabaseClient supabase, String shopId) =>
      requete(supabase, shopId);

  /// Fusionner au lieu de vider : `insertOrReplace` protège les écritures
  /// faites hors ligne qui ne sont pas encore parties.
  @override
  void appliquer(AppDatabase db, Batch batch, List<dynamic> lignes) {
    batch.insertAll(
      cibleFn(db),
      lignes
          .map((ligne) => versLigne(ligne as Map<String, dynamic>))
          .toList(),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Sert au test de couverture, qui construit une ligne distante factice.
  Insertable<D> mapperPourTest(Map<String, dynamic> ligne) => versLigne(ligne);
}

/// Passe la ligne au mapping de la table, pour les tests uniquement.
Insertable<dynamic> mapperLigne(TableTiree table, Map<String, dynamic> ligne) {
  return (table as dynamic).mapperPourTest(ligne) as Insertable<dynamic>;
}

double _reel(Object? valeur) => (valeur as num).toDouble();
double? _reelOuNul(Object? valeur) => (valeur as num?)?.toDouble();
DateTime _date(Object? valeur) => DateTime.parse(valeur as String).toLocal();
DateTime? _dateOuNulle(Object? valeur) =>
    valeur == null ? null : DateTime.parse(valeur as String).toLocal();

/// Tout ce qui redescend du serveur pour la boutique active.
///
/// **Ajouter une table synchronisée, c'est ajouter une entrée ici** — rien
/// d'autre. Une table oubliée ne casse rien de visible : elle laisse
/// simplement un second téléphone avec des données manquantes.
final List<TableTiree> tablesTirees = [
  _tableTiree(
    nom: 'products',
    cible: (db) => db.localProducts,
    requete: (supabase, shopId) =>
        supabase.from('products').select().eq('shop_id', shopId),
    versLigne: (p) => LocalProduct(
      id: p['id'],
      shopId: p['shop_id'],
      name: p['name'],
      buyPrice: _reel(p['buy_price']),
      sellPrice: _reel(p['sell_price']),
      quantity: p['quantity'],
      minQuantity: p['min_quantity'],
      barcode: p['barcode'],
      photoUrl: p['photo_url'],
      unit: p['unit'] as String?,
      archivedAt: _dateOuNulle(p['archived_at']),
    ),
  ),
  _tableTiree(
    nom: 'cash_movements',
    cible: (db) => db.localCashMovements,
    requete: (supabase, shopId) =>
        supabase.from('cash_movements').select().eq('shop_id', shopId),
    versLigne: (c) => LocalCashMovement(
      id: c['id'],
      shopId: c['shop_id'],
      userId: c['user_id'],
      amount: _reel(c['amount']),
      type: c['type'],
      category: c['category'],
      note: c['note'],
      createdAt: _date(c['created_at']),
    ),
  ),
  _tableTiree(
    nom: 'sales',
    cible: (db) => db.localSales,
    requete: (supabase, shopId) =>
        supabase.from('sales').select().eq('shop_id', shopId),
    versLigne: (s) => LocalSale(
      id: s['id'],
      shopId: s['shop_id'],
      userId: s['user_id'],
      totalAmount: _reel(s['total_amount']),
      totalProfit: _reel(s['total_profit']),
      createdAt: _date(s['created_at']),
    ),
  ),
  _tableTiree(
    nom: 'sale_items',
    cible: (db) => db.localSaleItems,
    // Les lignes de vente n'ont pas de `shop_id` : on passe par la vente.
    requete: (supabase, shopId) => supabase
        .from('sale_items')
        .select('*, sales!inner(shop_id)')
        .eq('sales.shop_id', shopId),
    versLigne: (i) => LocalSaleItem(
      id: i['id'],
      saleId: i['sale_id'],
      productId: i['product_id'],
      productName: i['product_name'],
      quantity: i['quantity'],
      sellPrice: _reel(i['sell_price']),
      buyPrice: _reel(i['buy_price']),
      profit: _reel(i['profit']),
      // Module A : sans ces colonnes, le téléchargement efface le lien
      // vente ↔ cycle et le rapport retombe à 0 F.
      cycleId: i['cycle_id'] as String?,
      unitId: i['unit_id'] as String?,
      quantityInBase: i['quantity_in_base'] as int?,
      unitSellPrice: _reelOuNul(i['unit_sell_price']),
    ),
  ),
  _tableTiree(
    nom: 'daily_closings',
    cible: (db) => db.localDailyClosings,
    requete: (supabase, shopId) =>
        supabase.from('daily_closings').select().eq('shop_id', shopId),
    versLigne: (c) => LocalDailyClosing(
      id: c['id'],
      shopId: c['shop_id'],
      userId: c['user_id'],
      closingDate: DateTime.parse(c['closing_date']),
      morningBalance: _reel(c['morning_balance']),
      totalSales: _reel(c['total_sales']),
      totalWithdrawals: _reel(c['total_withdrawals']),
      calculatedCash: _reel(c['calculated_cash']),
      grossProfit: _reel(c['gross_profit']),
      netProfit: _reel(c['net_profit']),
      physicalCash: _reelOuNul(c['physical_cash']),
      cashGap: _reelOuNul(c['cash_gap']),
      isClosed: c['is_closed'] ?? false,
      note: c['note'],
    ),
  ),
  // Module A : sans ces trois-là, un 2e téléphone ne voit ni les cycles ni
  // les unités, donc ne peut pas vendre au plateau.
  _tableTiree(
    nom: 'supply_cycles',
    cible: (db) => db.localSupplyCycles,
    requete: (supabase, shopId) =>
        supabase.from('supply_cycles').select().eq('shop_id', shopId),
    versLigne: (c) => LocalSupplyCycle(
      id: c['id'],
      shopId: c['shop_id'],
      productId: c['product_id'],
      openedAt: _date(c['opened_at']),
      closedAt: _dateOuNulle(c['closed_at']),
      quantityReceived: c['quantity_received'],
      purchaseCost: _reel(c['purchase_cost']),
      referenceMarginPerUnit: _reelOuNul(c['reference_margin_per_unit']),
      status: c['status'] ?? 'open',
    ),
  ),
  _tableTiree(
    nom: 'product_units',
    cible: (db) => db.localProductUnits,
    requete: (supabase, shopId) => supabase
        .from('product_units')
        .select('*, products!inner(shop_id)')
        .eq('products.shop_id', shopId),
    versLigne: (u) => LocalProductUnit(
      id: u['id'],
      productId: u['product_id'],
      unitName: u['unit_name'],
      ratioToBase: u['ratio_to_base'],
      sortOrder: u['sort_order'] ?? 0,
    ),
  ),
  _tableTiree(
    nom: 'cycle_losses',
    cible: (db) => db.localCycleLosses,
    requete: (supabase, shopId) => supabase
        .from('cycle_losses')
        .select('*, supply_cycles!inner(shop_id)')
        .eq('supply_cycles.shop_id', shopId),
    versLigne: (l) => LocalCycleLossesData(
      id: l['id'],
      cycleId: l['cycle_id'],
      quantity: l['quantity'],
      reason: l['reason'],
      note: l['note'],
      createdAt: _date(l['created_at']),
    ),
  ),
  // Module B : la recette locale doit revenir après connexion sur un autre
  // téléphone, au même titre que les autres données métier.
  _tableTiree(
    nom: 'shop_takings',
    cible: (db) => db.localShopTakings,
    requete: (supabase, shopId) =>
        supabase.from('shop_takings').select().eq('shop_id', shopId),
    versLigne: (t) => LocalShopTaking(
      shopId: t['shop_id'],
      date: DateTime.parse(t['date']),
      amount: _reel(t['amount']),
    ),
  ),
  // Module B : les comptages sont des repères historiques. Sans eux, un
  // second téléphone ne peut ni reprendre ni terminer le tour.
  _tableTiree(
    nom: 'inventory_counts',
    cible: (db) => db.localInventoryCounts,
    requete: (supabase, shopId) =>
        supabase.from('inventory_counts').select().eq('shop_id', shopId),
    versLigne: (c) => LocalInventoryCount(
      id: c['id'],
      shopId: c['shop_id'],
      productId: c['product_id'],
      countedAt: _date(c['counted_at']),
      countedQuantity: c['counted_quantity'],
      previousCountedAt: _dateOuNulle(c['previous_counted_at']),
      previousQuantity: c['previous_quantity'],
    ),
  ),
  // Les recharges sont poussées par `apply_stock_movement` mais n'étaient
  // jamais retéléchargées. Le rapport de période en tire ses achats : sans
  // elles, les sorties valent « stock de départ − stock compté », le
  // réapprovisionnement disparaît du calcul et l'app annonce un bénéfice
  // surévalué. Le stock, lui, restait juste — le bug était invisible sur
  // l'écran Stock.
  _tableTiree(
    nom: 'stock_movements',
    cible: (db) => db.localStockMovements,
    requete: (supabase, shopId) =>
        supabase.from('stock_movements').select().eq('shop_id', shopId),
    versLigne: (m) => LocalStockMovement(
      id: m['id'],
      shopId: m['shop_id'],
      productId: m['product_id'],
      quantity: m['quantity'],
      type: m['type'],
      createdAt: _date(m['created_at']),
    ),
  ),
  // Module B : sans les pertes déclarées, la casse d'un téléphone redevient
  // de l'inexpliqué sur l'autre — donc du vol présumé.
  _tableTiree(
    nom: 'inventory_losses',
    cible: (db) => db.localInventoryLosses,
    requete: (supabase, shopId) =>
        supabase.from('inventory_losses').select().eq('shop_id', shopId),
    versLigne: (l) => LocalInventoryLoss(
      id: l['id'],
      shopId: l['shop_id'],
      productId: l['product_id'],
      quantity: l['quantity'],
      reason: l['reason'],
      note: l['note'] as String?,
      occurredAt: _date(l['occurred_at']),
    ),
  ),
  // Le prix payé voyage avec l'achat : sans ce téléchargement, un second
  // téléphone revaloriserait tout au prix actuel du produit.
  _tableTiree(
    nom: 'stock_purchases',
    cible: (db) => db.localStockPurchases,
    requete: (supabase, shopId) =>
        supabase.from('stock_purchases').select().eq('shop_id', shopId),
    versLigne: (p) => LocalStockPurchase(
      id: p['id'],
      shopId: p['shop_id'],
      productId: p['product_id'],
      quantity: p['quantity'],
      unitCost: _reel(p['unit_cost']),
      purchasedAt: _date(p['purchased_at']),
      note: p['note'] as String?,
    ),
  ),
  // Le tarif pratiqué pendant la période, pour la même raison.
  _tableTiree(
    nom: 'product_prices',
    cible: (db) => db.localProductPrices,
    requete: (supabase, shopId) =>
        supabase.from('product_prices').select().eq('shop_id', shopId),
    versLigne: (p) => LocalProductPrice(
      id: p['id'],
      shopId: p['shop_id'],
      productId: p['product_id'],
      buyPrice: _reel(p['buy_price']),
      sellPrice: _reel(p['sell_price']),
      effectiveAt: _date(p['effective_at']),
    ),
  ),
  // Les deux sens : la boutique voit ce qu'elle a envoyé ET ce qu'elle doit
  // recevoir. Sans le second, personne ne pourrait confirmer une réception.
  _tableTiree(
    nom: 'stock_transfers',
    cible: (db) => db.localStockTransfers,
    requete: (supabase, shopId) => supabase
        .from('stock_transfers')
        .select()
        .or('from_shop_id.eq.$shopId,to_shop_id.eq.$shopId'),
    versLigne: (t) => LocalStockTransfer(
      id: t['id'],
      fromShopId: t['from_shop_id'],
      toShopId: t['to_shop_id'],
      productId: t['product_id'],
      // L'identité recopiée à l'envoi : sans elle ici, le téléchargement
      // réécrirait la ligne locale en effaçant le nom du produit, et le
      // destinataire retomberait sur « Produit inconnu » quelques secondes
      // après l'avoir reçu.
      productName: t['product_name'] as String?,
      buyPrice: _reelOuNul(t['buy_price']),
      sellPrice: _reelOuNul(t['sell_price']),
      unit: t['unit'] as String?,
      quantity: t['quantity'],
      receivedQuantity: t['received_quantity'] as int?,
      receivedAt: _dateOuNulle(t['received_at']),
      transferredAt: _date(t['transferred_at']),
      note: t['note'] as String?,
    ),
  ),
];

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// --- 1. DÉFINITION DES TABLES LOCALES ---

// Table des Produits
class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  RealColumn get buyPrice => real()();
  RealColumn get sellPrice => real()();
  IntColumn get quantity => integer()();
  IntColumn get minQuantity => integer()();
  TextColumn get barcode => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  /// Étiquette d'affichage (sac, bouteille, casier, g, l…). N'entre dans
  /// aucun calcul : le commerçant compte dans une seule unité par produit.
  TextColumn get unit => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table des Ventes
class LocalSales extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get userId => text()();
  RealColumn get totalAmount => real()();
  RealColumn get totalProfit => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table des Articles Vendus
class LocalSaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get sellPrice => real()();
  RealColumn get buyPrice => real()();
  RealColumn get profit => real()();
  // Module A (cycles/unités) — nullable : ignoré en mode simple.
  TextColumn get cycleId => text().nullable()();
  TextColumn get unitId => text().nullable()();
  IntColumn get quantityInBase => integer().nullable()();
  RealColumn get unitSellPrice => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table des Mouvements de Caisse
class LocalCashMovements extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real()();
  TextColumn get type =>
      text()(); // 'morning_balance', 'withdrawal', 'incoming'
  TextColumn get category => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table des Mouvements de Stock (Recharges)
class LocalStockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table des Clôtures Journalières
class LocalDailyClosings extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get closingDate => dateTime()();
  RealColumn get morningBalance => real()();
  RealColumn get totalSales => real()();
  RealColumn get totalWithdrawals => real()();
  RealColumn get calculatedCash => real()();
  RealColumn get grossProfit => real()();
  RealColumn get netProfit => real()();
  RealColumn get physicalCash => real().nullable()();
  RealColumn get cashGap => real().nullable()();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table des Réglages de Boutique (modules optionnels : cycles, multi-point...)
class LocalShopSettings extends Table {
  TextColumn get shopId => text()();
  TextColumn get unitMode => text().withDefault(const Constant('simple'))();
  TextColumn get saleCaptureMode =>
      text().withDefault(const Constant('realtime'))();
  BoolColumn get multiPointEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {shopId};
}

// Module A — Unités d'un produit (ex: œuf(1), plateau(30), carton(360))
class LocalProductUnits extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get unitName => text()();
  IntColumn get ratioToBase => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// Module A — Cycles d'approvisionnement
class LocalSupplyCycles extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productId => text()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get quantityReceived => integer()();
  RealColumn get purchaseCost => real()();
  RealColumn get referenceMarginPerUnit => real().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();

  @override
  Set<Column> get primaryKey => {id};
}

// Module A — Pertes rattachées à un cycle
class LocalCycleLosses extends Table {
  TextColumn get id => text()();
  TextColumn get cycleId => text()();
  IntColumn get quantity => integer()();
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Module B — Recette encaissée par jour et par boutique.
class LocalShopTakings extends Table {
  TextColumn get shopId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();

  @override
  Set<Column> get primaryKey => {shopId, date};
}

// Module B — Repères physiques posés produit par produit.
class LocalInventoryCounts extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productId => text()();
  DateTimeColumn get countedAt => dateTime()();
  IntColumn get countedQuantity => integer()();
  DateTimeColumn get previousCountedAt => dateTime().nullable()();
  IntColumn get previousQuantity => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Module B — Marchandise déplacée d'une boutique à l'autre.
//
// Ce n'est PAS une recharge : rien n'est acheté, la marchandise est déjà
// payée. L'enregistrer comme un achat la ferait compter deux fois dans les
// dépenses du groupe, et le bénéfice consolidé du patron deviendrait faux.
//
// `receivedQuantity` est rempli à l'arrivée si quelqu'un vérifie. L'écart
// avec `quantity` est une perte de transport imputée à l'expéditeur : la
// marchandise était la sienne, et sans cette imputation le manquant
// deviendrait un écart inexpliqué chez lui — donc un vol présumé.
@DataClassName('LocalStockTransfer')
class LocalStockTransfers extends Table {
  TextColumn get id => text()();
  TextColumn get fromShopId => text()();
  TextColumn get toShopId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  IntColumn get receivedQuantity => integer().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  DateTimeColumn get transferredAt => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Module B — Historique des prix d'un produit, une ligne par changement.
//
// Le prix d'achat est figé sur la ligne d'achat, mais le prix de VENTE
// restait celui d'aujourd'hui : une période close se revalorisait toute seule
// dès que le commerçant changeait son tarif, et l'écart avec sa caisse
// devenait faux sans que rien ne le signale.
@DataClassName('LocalProductPrice')
class LocalProductPrices extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productId => text()();
  RealColumn get buyPrice => real()();
  RealColumn get sellPrice => real()();
  DateTimeColumn get effectiveAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Module B — Ce qui a été acheté, avec le prix payé ce jour-là.
//
// Le prix vit sur la ligne d'achat et pas seulement sur le produit : sinon
// revaloriser un produit au prix du marché réécrit le coût de toutes les
// périodes déjà closes, et un rapport consulté hier affiche d'autres chiffres
// aujourd'hui. Le client a confirmé que ses prix bougent souvent.
@DataClassName('LocalStockPurchase')
class LocalStockPurchases extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitCost => real()();
  DateTimeColumn get purchasedAt => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Module B — Casse, péremption, invendu : ce qui est sorti du stock sans être
// vendu. Séparé de `LocalCycleLosses`, qui appartient au module A et se
// rattache à un cycle d'arrivage : ici la perte se rattache à une date, la
// seule chose que le commerçant connaisse.
//
// Une perte déclarée ne touche PAS le stock enregistré : en inventaire
// périodique, le stock ne bouge qu'au comptage. Elle sert uniquement à dire
// « ces 3 bouteilles n'ont pas été volées, elles sont cassées ».
@DataClassName('LocalInventoryLoss')
class LocalInventoryLosses extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();

  /// casse · peremption · invendu · vol · autre — mêmes valeurs que la
  /// contrainte SQL de `inventory_losses`, sinon le push est rejeté.
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table de la Salle d'attente (Sync Queue)
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Nombre de refus essuyés. Sans ce compteur, une opération que le serveur
  /// refusera toujours gelait la file entière — et le commerçant continuait
  /// de travailler sans savoir que plus rien ne partait.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Mise de côté après trop de refus. L'opération reste dans la file : on ne
  /// jette pas le travail de quelqu'un sans le lui dire. Elle n'est
  /// simplement plus renvoyée toute seule, et elle attend une décision.
  BoolColumn get setAside => boolean().withDefault(const Constant(false))();

  /// Ce que le serveur a répondu la dernière fois, pour pouvoir l'afficher.
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}

// --- 2. CONFIGURATION DE LA BASE DE DONNÉES ---

@DriftDatabase(
  tables: [
    LocalProducts,
    LocalSales,
    LocalSaleItems,
    LocalCashMovements,
    LocalStockMovements,
    LocalDailyClosings,
    LocalShopSettings,
    LocalProductUnits,
    LocalSupplyCycles,
    LocalCycleLosses,
    LocalShopTakings,
    LocalInventoryCounts,
    LocalInventoryLosses,
    LocalStockPurchases,
    LocalProductPrices,
    LocalStockTransfers,
    SyncQueueItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Base en mémoire, pour les tests uniquement.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(localShopSettings);
      }
      if (from < 3) {
        await m.createTable(localProductUnits);
        await m.createTable(localSupplyCycles);
        await m.createTable(localCycleLosses);
        await m.addColumn(localSaleItems, localSaleItems.cycleId);
        await m.addColumn(localSaleItems, localSaleItems.unitId);
        await m.addColumn(localSaleItems, localSaleItems.quantityInBase);
        await m.addColumn(localSaleItems, localSaleItems.unitSellPrice);
      }
      if (from < 4) {
        await m.createTable(localShopTakings);
      }
      if (from < 5) {
        await m.createTable(localInventoryCounts);
      }
      if (from < 6) {
        await m.addColumn(localProducts, localProducts.unit);
      }
      if (from < 7) {
        await m.createTable(localInventoryLosses);
      }
      if (from < 8) {
        await m.createTable(localStockPurchases);
      }
      if (from < 9) {
        await m.createTable(localProductPrices);
      }
      if (from < 10) {
        await m.createTable(localStockTransfers);
      }
      if (from < 11) {
        await m.addColumn(syncQueueItems, syncQueueItems.attempts);
        await m.addColumn(syncQueueItems, syncQueueItems.setAside);
        await m.addColumn(syncQueueItems, syncQueueItems.lastError);
        await m.addColumn(syncQueueItems, syncQueueItems.lastAttemptAt);
      }
    },
  );

  // --- FONCTIONS POUR LA SALLE D'ATTENTE ---
  Future<int> addToQueue(String action, String payload) {
    return into(syncQueueItems).insert(
      SyncQueueItemsCompanion(action: Value(action), payload: Value(payload)),
    );
  }

  /// Toute la file, mises de côté comprises, dans l'ordre où les opérations
  /// ont été faites. `id` départage : deux opérations de la même milliseconde
  /// sortaient sinon dans un ordre indéfini, et l'ordre est ce qui garantit
  /// qu'un produit est créé avant qu'on lui ajoute du stock.
  Future<List<SyncQueueItem>> getPendingItems() {
    return (select(syncQueueItems)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt),
          (t) => OrderingTerm(expression: t.id),
        ]))
        .get();
  }

  Future<int> getPendingCount() async {
    final countExpression = syncQueueItems.id.count();
    final query = selectOnly(syncQueueItems)..addColumns([countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  /// Les opérations que le serveur refuse et qui attendent une décision.
  Future<List<SyncQueueItem>> getSetAsideItems() {
    return (select(syncQueueItems)
          ..where((t) => t.setAside.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<int> getSetAsideCount() async {
    final countExpression = syncQueueItems.id.count();
    final query = selectOnly(syncQueueItems)
      ..addColumns([countExpression])
      ..where(syncQueueItems.setAside.equals(true));
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  /// Note un refus. Au-delà du seuil, l'opération passe de côté.
  Future<void> noteQueueFailure(
    int id, {
    required int attempts,
    required String error,
    required bool setAside,
  }) {
    return (update(syncQueueItems)..where((t) => t.id.equals(id))).write(
      SyncQueueItemsCompanion(
        attempts: Value(attempts),
        lastError: Value(error),
        lastAttemptAt: Value(DateTime.now()),
        setAside: Value(setAside),
      ),
    );
  }

  /// Remet une opération dans le circuit, compteur remis à zéro.
  Future<void> requeueItem(int id) {
    return (update(syncQueueItems)..where((t) => t.id.equals(id))).write(
      const SyncQueueItemsCompanion(
        setAside: Value(false),
        attempts: Value(0),
        lastError: Value(null),
      ),
    );
  }

  Future<void> requeueAllSetAside() {
    return (update(syncQueueItems)..where((t) => t.setAside.equals(true)))
        .write(
          const SyncQueueItemsCompanion(
            setAside: Value(false),
            attempts: Value(0),
            lastError: Value(null),
          ),
        );
  }

  Future<void> removeFromQueue(int id) {
    return (delete(syncQueueItems)..where((t) => t.id.equals(id))).go();
  }

  // --- FONCTIONS POUR VIDER LA BASE (Utile pour la déconnexion) ---
  Future<void> clearAllData() async {
    await delete(localProducts).go();
    await delete(localSales).go();
    await delete(localSaleItems).go();
    await delete(localCashMovements).go();
    await delete(localStockMovements).go();
    await delete(localDailyClosings).go();
    await delete(localShopSettings).go();
    await delete(localProductUnits).go();
    await delete(localSupplyCycles).go();
    await delete(localCycleLosses).go();
    await delete(localShopTakings).go();
    await delete(localInventoryCounts).go();
    await delete(syncQueueItems).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'shoptrack_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

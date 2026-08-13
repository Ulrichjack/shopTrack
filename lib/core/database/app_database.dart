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

// Table de la Salle d'attente (Sync Queue)
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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
    SyncQueueItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Base en mémoire, pour les tests uniquement.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

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
    },
  );

  // --- FONCTIONS POUR LA SALLE D'ATTENTE ---
  Future<int> addToQueue(String action, String payload) {
    return into(syncQueueItems).insert(
      SyncQueueItemsCompanion(action: Value(action), payload: Value(payload)),
    );
  }

  Future<List<SyncQueueItem>> getPendingItems() {
    return (select(
      syncQueueItems,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
  }

  Future<int> getPendingCount() async {
    final countExpression = syncQueueItems.id.count();
    final query = selectOnly(syncQueueItems)..addColumns([countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
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

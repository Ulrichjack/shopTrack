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

  @override
  Set<Column> get primaryKey => {id};
}

// Table des Mouvements de Caisse
class LocalCashMovements extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'morning_balance', 'withdrawal', 'incoming'
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


// Table de la Salle d'attente (Sync Queue)
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}



// --- 2. CONFIGURATION DE LA BASE DE DONNÉES ---

@DriftDatabase(tables: [
  LocalProducts,
  LocalSales,
  LocalSaleItems,
  LocalCashMovements,
  LocalStockMovements,
  LocalDailyClosings,
  SyncQueueItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- FONCTIONS POUR LA SALLE D'ATTENTE ---
  Future<int> addToQueue(String action, String payload) {
    return into(syncQueueItems).insert(
      SyncQueueItemsCompanion(
        action: Value(action),
        payload: Value(payload),
      ),
    );
  }

  Future<List<SyncQueueItem>> getPendingItems() {
    return (select(syncQueueItems)..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
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
    await delete(localDailyClosings).go();
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
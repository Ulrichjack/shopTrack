import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../sync/sync_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.read(localDbProvider));
});

class BackupService {
  const BackupService(this.db);

  final AppDatabase db;

  Future<String> createBackup() async {
    final products = await db.select(db.localProducts).get();
    final sales = await db.select(db.localSales).get();
    final saleItems = await db.select(db.localSaleItems).get();
    final cashMovements = await db.select(db.localCashMovements).get();
    final stockMovements = await db.select(db.localStockMovements).get();
    final closings = await db.select(db.localDailyClosings).get();
    final queue = await db.getPendingItems();

    final data = {
      'format': 'shoptrack-backup-v1',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'products': products.map((row) => row.toJson()).toList(),
      'sales': sales.map((row) => row.toJson()).toList(),
      'sale_items': saleItems.map((row) => row.toJson()).toList(),
      'cash_movements': cashMovements.map((row) => row.toJson()).toList(),
      'stock_movements': stockMovements.map((row) => row.toJson()).toList(),
      'daily_closings': closings.map((row) => row.toJson()).toList(),
      'pending_sync': queue.map((row) => row.toJson()).toList(),
    };

    final documents = await getApplicationDocumentsDirectory();
    final backupDirectory = Directory(
      path.join(documents.path, 'ShopTrackBackups'),
    );
    await backupDirectory.create(recursive: true);

    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final file = File(path.join(backupDirectory.path, 'shoptrack_$date.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    return file.path;
  }
}

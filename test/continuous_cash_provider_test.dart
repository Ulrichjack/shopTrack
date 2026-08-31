import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/network/connectivity_provider.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/dashboard/presentation/providers/dashboard_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'cached_shop_id': 'shop-1',
      'cached_user_id': 'user-1',
    });
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        localDbProvider.overrideWithValue(db),
        connectivityProvider.overrideWith((ref) => Stream.value(false)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('une boutique vide démarre à zéro sans saisie matinale', () async {
    final dashboard = await container.read(dashboardProvider.future);

    expect(dashboard.morningBalance, 0);
    expect(dashboard.calculatedCash, 0);
    expect(dashboard.hasMorningBalance, isTrue);
  });

  test('reporte le solde même si la veille n’a pas été clôturée', () async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    await db
        .into(db.localCashMovements)
        .insert(
          LocalCashMovement(
            id: 'opening',
            shopId: 'shop-1',
            userId: 'user-1',
            amount: 50000,
            type: 'morning_balance',
            createdAt: yesterday.add(const Duration(hours: 8)),
          ),
        );
    await db
        .into(db.localSales)
        .insert(
          LocalSale(
            id: 'sale',
            shopId: 'shop-1',
            userId: 'user-1',
            totalAmount: 10000,
            totalProfit: 2000,
            createdAt: yesterday.add(const Duration(hours: 12)),
          ),
        );

    final dashboard = await container.read(dashboardProvider.future);

    expect(dashboard.morningBalance, 60000);
    expect(dashboard.calculatedCash, 60000);
    expect(dashboard.needsPreviousDayClosing, isFalse);
  });

  test('la dernière clôture physique devient le point de contrôle', () async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    await db
        .into(db.localCashMovements)
        .insert(
          LocalCashMovement(
            id: 'opening',
            shopId: 'shop-1',
            userId: 'user-1',
            amount: 50000,
            type: 'morning_balance',
            createdAt: yesterday.add(const Duration(hours: 8)),
          ),
        );
    await db
        .into(db.localDailyClosings)
        .insert(
          LocalDailyClosing(
            id: 'closing',
            shopId: 'shop-1',
            userId: 'user-1',
            closingDate: yesterday,
            morningBalance: 50000,
            totalSales: 0,
            totalWithdrawals: 0,
            calculatedCash: 50000,
            grossProfit: 0,
            netProfit: 0,
            physicalCash: 40000,
            cashGap: -10000,
            isClosed: true,
          ),
        );

    final dashboard = await container.read(dashboardProvider.future);

    expect(dashboard.morningBalance, 40000);
    expect(dashboard.calculatedCash, 40000);
  });
}

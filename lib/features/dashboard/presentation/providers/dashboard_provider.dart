import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/daily_cash_calculator.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../domain/entities/daily_closing_entity.dart';
import '../../data/datasources/closing_remote_datasource.dart';
import '../../data/repositories/closing_repository_impl.dart';

// --- 1. REPOSITORIES POUR LA CLÔTURE (Supabase) ---
final closingRemoteDataSourceProvider = Provider((ref) {
  return ClosingRemoteDataSource(Supabase.instance.client);
});

final closingRepositoryProvider = Provider((ref) {
  final remoteDataSource = ref.read(closingRemoteDataSourceProvider);
  return ClosingRepositoryImpl(remoteDataSource);
});

// --- 2. MODÈLE DE DONNÉES DU DASHBOARD ---
class DashboardState {
  final double morningBalance;
  final double totalSales;
  final double totalWithdrawals;
  final double calculatedCash;
  final double grossProfit;
  final double netProfit;
  final int salesCount;
  final bool isClosed;
  final DailyClosingEntity? closingData;

  // NOUVEAU : Gestion de l'oubli de clôture
  final bool needsPreviousDayClosing;
  final DateTime? dateToClose;

  DashboardState({
    required this.morningBalance,
    required this.totalSales,
    required this.totalWithdrawals,
    required this.calculatedCash,
    required this.grossProfit,
    required this.netProfit,
    required this.salesCount,
    required this.isClosed,
    this.closingData,
    this.needsPreviousDayClosing = false,
    this.dateToClose,
  });
}

// --- 3. LE PROVIDER PRINCIPAL (100% LOCAL avec cache SharedPreferences) ---
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(() {
      return DashboardNotifier();
    });

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    return _fetchDashboardData();
  }

  // 👇 SYNCHRO AMÉLIORÉE (Récupère aussi le nom de la boutique)
  Future<void> _runBackgroundSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        await prefs.setString('cached_user_id', currentUser.id);

        // On récupère le shop_id ET le nom de la boutique via une jointure Supabase
        final memberResponse = await Supabase.instance.client
            .from('shop_members')
            .select('shop_id, shops(name)')
            .eq('user_id', currentUser.id)
            .single();

        await prefs.setString(
          'cached_shop_id',
          memberResponse['shop_id'] as String,
        );
        // On sauvegarde le nom de la boutique
        final shopData = memberResponse['shops'] as Map<String, dynamic>;
        await prefs.setString('cached_shop_name', shopData['name'] as String);
      }

      await ref.read(syncServiceProvider).pullDataFromSupabase();
    } catch (e) {
      print('Erreur réseau en arrière-plan : $e');
    }
  }

  Future<DashboardState> _fetchDashboardData() async {
    final db = ref.read(localDbProvider);
    final isOnline = ref.read(connectivityProvider).value ?? true;
    final prefs = await SharedPreferences.getInstance();

    String shopId = prefs.getString('cached_shop_id') ?? '';

    // 1. SI C'EST LA TOUTE PREMIÈRE CONNEXION
    final localProducts = await db.select(db.localProducts).get();
    final isFirstLoad = localProducts.isEmpty;

    if (isOnline) {
      try {
        if (isFirstLoad) {
          await _runBackgroundSync();
          ref.invalidate(productProvider);
        } else {
          await _runBackgroundSync();
          ref.invalidate(productProvider);
        }
      } catch (e) {
        print(
          '⚠️ Synchro échouée, mais on charge quand même le cache local : $e',
        );
      }
    }

    if (shopId.isEmpty && isFirstLoad) {
      throw Exception('Boutique introuvable. Connectez-vous à internet.');
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    // ==========================================
    // 2. VÉRIFICATION DE LA CLÔTURE DE LA VEILLE
    // ==========================================
    final lastSale =
        await (db.select(db.localSales)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.createdAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (lastSale != null) {
      final lastSaleDate = DateTime(
        lastSale.createdAt.year,
        lastSale.createdAt.month,
        lastSale.createdAt.day,
      );

      if (lastSaleDate.isBefore(startOfDay)) {
        final startOfSaleDay = DateTime(
          lastSaleDate.year,
          lastSaleDate.month,
          lastSaleDate.day,
        );
        final endOfSaleDay = DateTime(
          lastSaleDate.year,
          lastSaleDate.month,
          lastSaleDate.day,
          23,
          59,
          59,
        );

        final existingClosing =
            await (db.select(db.localDailyClosings)..where(
                  (t) => t.closingDate.isBetweenValues(
                    startOfSaleDay,
                    endOfSaleDay,
                  ),
                ))
                .getSingleOrNull();

        if (existingClosing == null) {
          return DashboardState(
            morningBalance: 0,
            totalSales: 0,
            totalWithdrawals: 0,
            calculatedCash: 0,
            grossProfit: 0,
            netProfit: 0,
            salesCount: 0,
            isClosed: false,
            needsPreviousDayClosing: true,
            dateToClose: lastSaleDate,
          );
        }
      }
    }

    // ==========================================
    // 3. LECTURE LOCALE DE LA JOURNÉE ACTUELLE
    // ==========================================
    // ✅ FIX : Utilisation de isBetweenValues au lieu de .year.equals()
    final todayClosing =
        await (db.select(db.localDailyClosings)..where(
              (t) => t.closingDate.isBetweenValues(startOfDay, endOfDay),
            ))
            .getSingleOrNull();

    if (todayClosing != null && todayClosing.isClosed) {
      return DashboardState(
        morningBalance: todayClosing.morningBalance,
        totalSales: todayClosing.totalSales,
        totalWithdrawals: todayClosing.totalWithdrawals,
        calculatedCash: todayClosing.calculatedCash,
        grossProfit: todayClosing.grossProfit,
        netProfit: todayClosing.netProfit,
        salesCount: 0,
        isClosed: true,
      );
    }

    final localSales = await (db.select(
      db.localSales,
    )..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))).get();

    // ✅ FIX : On trie par date décroissante pour prendre le solde le plus récent
    final localCashMovements =
        await (db.select(db.localCashMovements)
              ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.createdAt,
                  mode: drift.OrderingMode.desc,
                ),
              ]))
            .get();

    final totals = _calculateTotals(localSales, localCashMovements);

    return DashboardState(
      morningBalance: totals.morningBalance,
      totalSales: totals.totalSales,
      totalWithdrawals: totals.totalWithdrawals,
      calculatedCash: totals.calculatedCash,
      grossProfit: totals.grossProfit,
      netProfit: totals.netProfit,
      salesCount: localSales.length,
      isClosed: false,
    );
  }

  DailyCashTotals _calculateTotals(
    List<LocalSale> sales,
    List<LocalCashMovement> movements,
  ) {
    return DailyCashCalculator.calculate(
      sales: sales.map(
        (sale) => SaleValue(amount: sale.totalAmount, profit: sale.totalProfit),
      ),
      movements: movements.map(
        (movement) => CashMovementValue(
          type: movement.type,
          amount: movement.amount,
          createdAt: movement.createdAt,
        ),
      ),
    );
  }

  // --- ACTIONS DU DASHBOARD ---

  Future<void> saveMorningBalance(double amount) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(localDbProvider);
      final prefs = await SharedPreferences.getInstance();

      final shopId = prefs.getString('cached_shop_id');
      final userId = prefs.getString('cached_user_id') ?? 'offline_user';

      if (shopId == null) throw Exception('Boutique introuvable.');

      final movementId = const Uuid().v4();
      final now = DateTime.now();

      await db
          .into(db.localCashMovements)
          .insert(
            LocalCashMovement(
              id: movementId,
              shopId: shopId,
              userId: userId,
              amount: amount,
              type: 'morning_balance',
              createdAt: now,
            ),
          );

      final payload = {
        'id': movementId,
        'shop_id': shopId,
        'user_id': userId,
        'amount': amount,
        'type': 'morning_balance',
        'created_at': now.toIso8601String(),
      };
      await db.addToQueue('ADD_CASH_MOVEMENT', jsonEncode(payload));
      await ref.read(syncServiceProvider).processQueue();

      state = AsyncValue.data(await _fetchDashboardData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> closeDay(
    double physicalCash,
    String? note, {
    DateTime? specificDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(localDbProvider);
      final prefs = await SharedPreferences.getInstance();

      final shopId = prefs.getString('cached_shop_id');
      final userId = prefs.getString('cached_user_id') ?? 'offline_user';

      if (shopId == null) throw Exception('Boutique introuvable.');

      final dateToClose = specificDate ?? DateTime.now();
      final startOfDay = DateTime(
        dateToClose.year,
        dateToClose.month,
        dateToClose.day,
      );
      final endOfDay = DateTime(
        dateToClose.year,
        dateToClose.month,
        dateToClose.day,
        23,
        59,
        59,
      );

      final localSales = await (db.select(
        db.localSales,
      )..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))).get();
      final localCashMovements = await (db.select(
        db.localCashMovements,
      )..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))).get();
      final totals = _calculateTotals(localSales, localCashMovements);
      final cashGap = physicalCash - totals.calculatedCash;

      final existingClosing =
          await (db.select(db.localDailyClosings)..where(
                (t) => t.closingDate.isBetweenValues(startOfDay, endOfDay),
              ))
              .getSingleOrNull();
      final closingId = existingClosing?.id ?? const Uuid().v4();
      final normalizedClosingDate = startOfDay;

      await db
          .into(db.localDailyClosings)
          .insert(
            LocalDailyClosing(
              id: closingId,
              shopId: shopId,
              userId: userId,
              closingDate: normalizedClosingDate,
              morningBalance: totals.morningBalance,
              totalSales: totals.totalSales,
              totalWithdrawals: totals.totalWithdrawals,
              calculatedCash: totals.calculatedCash,
              grossProfit: totals.grossProfit,
              netProfit: totals.netProfit,
              physicalCash: physicalCash,
              cashGap: cashGap,
              isClosed: true,
              note: note,
            ),
            mode: drift.InsertMode.insertOrReplace,
          );

      final payload = {
        'id': closingId,
        'shop_id': shopId,
        'user_id': userId,
        'closing_date':
            "${dateToClose.year}-${dateToClose.month.toString().padLeft(2, '0')}-${dateToClose.day.toString().padLeft(2, '0')}",
        'morning_balance': totals.morningBalance,
        'total_sales': totals.totalSales,
        'total_withdrawals': totals.totalWithdrawals,
        'calculated_cash': totals.calculatedCash,
        'gross_profit': totals.grossProfit,
        'net_profit': totals.netProfit,
        'physical_cash': physicalCash,
        'cash_gap': cashGap,
        'is_closed': true,
        'note': note,
      };
      await db.addToQueue('ADD_CLOSING', jsonEncode(payload));
      await ref.read(syncServiceProvider).processQueue();
      try {
        await ref.read(backupServiceProvider).createBackup();
      } catch (_) {
        // La clôture reste valide même si le stockage du téléphone est plein.
      }

      state = AsyncValue.data(await _fetchDashboardData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

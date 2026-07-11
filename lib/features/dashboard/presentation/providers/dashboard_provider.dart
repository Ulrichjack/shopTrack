import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../cash/domain/entities/cash_movement_entity.dart';
import '../../../sales/presentation/providers/sale_provider.dart';
import '../../../cash/data/datasources/cash_remote_datasource.dart';
import '../../../cash/data/repositories/cash_repository_impl.dart';
import '../../data/datasources/closing_remote_datasource.dart';
import '../../data/repositories/closing_repository_impl.dart';
import '../../domain/entities/daily_closing_entity.dart';

// --- 1. INITIALISATION DES REPOSITORIES ---

final cashRemoteDataSourceProvider = Provider((ref) {
  return CashRemoteDataSource(Supabase.instance.client);
});

final cashRepositoryProvider = Provider((ref) {
  final remoteDataSource = ref.read(cashRemoteDataSourceProvider);
  return CashRepositoryImpl(remoteDataSource);
});

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
  final bool isClosed; // Vrai si la journée est clôturée
  final DailyClosingEntity? closingData; // Les données de clôture si ça a été fait

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
  });
}

// --- 3. LE PROVIDER PRINCIPAL (LE CERVEAU) ---

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    return _fetchDashboardData();
  }

  Future<DashboardState> _fetchDashboardData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Non connecté');

      final memberResponse = await Supabase.instance.client
          .from('shop_members')
          .select('shop_id')
          .eq('user_id', userId)
          .limit(1)
          .single();
      final shopId = memberResponse['shop_id'] as String;

      final today = DateTime.now();

      // 1. Vérifier si la journée est déjà clôturée
      final closingRepo = ref.read(closingRepositoryProvider);
      final closing = await closingRepo.getClosingForDate(shopId, today);

      if (closing != null && closing.isClosed) {
        return DashboardState(
          morningBalance: closing.morningBalance,
          totalSales: closing.totalSales,
          totalWithdrawals: closing.totalWithdrawals,
          calculatedCash: closing.calculatedCash,
          grossProfit: closing.grossProfit,
          netProfit: closing.netProfit,
          salesCount: 0,
          isClosed: true,
          closingData: closing,
        );
      }

      // 2. Si non clôturé, on calcule tout en temps réel !
      final saleRepo = ref.read(saleRepositoryProvider);
      final cashRepo = ref.read(cashRepositoryProvider);

      // Récupération des données du jour
      final todaySales = await saleRepo.getDailySales(shopId, today);
      final todayCashMovements = await cashRepo.getTodayMovements(shopId, today);

      // Variables pour les calculs
      double morningBalance = 0;
      double totalWithdrawals = 0;
      double totalSales = 0;
      double grossProfit = 0;

      // Calcul des mouvements de caisse
      for (var movement in todayCashMovements) {
        if (movement.type == 'morning_balance') {
          morningBalance = movement.amount;
        } else if (movement.type == 'withdrawal') {
          totalWithdrawals += movement.amount;
        }
      }

      // Calcul des ventes
      for (var sale in todaySales) {
        totalSales += sale.totalAmount;
        grossProfit += sale.totalProfit;
      }

      final calculatedCash = morningBalance + totalSales - totalWithdrawals;
      final netProfit = grossProfit - totalWithdrawals;

      return DashboardState(
        morningBalance: morningBalance,
        totalSales: totalSales,
        totalWithdrawals: totalWithdrawals,
        calculatedCash: calculatedCash,
        grossProfit: grossProfit,
        netProfit: netProfit,
        salesCount: todaySales.length,
        isClosed: false,
      );
    } catch (e, stackTrace) {
      // 👇 LE PRINT MAGIQUE EST ICI 👇
      print('🔴 ERREUR DANS DASHBOARD PROVIDER : $e');
      print('🔴 TRACE DE L\'ERREUR : $stackTrace');
      rethrow; // On relance l'erreur pour que l'UI l'affiche
    }
  }

  // --- 4. ACTIONS DU DASHBOARD ---

  // Action pour enregistrer le solde du matin
  Future<void> saveMorningBalance(double amount) async {
    state = const AsyncValue.loading();
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final memberResponse = await Supabase.instance.client
          .from('shop_members')
          .select('shop_id')
          .eq('user_id', userId!)
          .limit(1)
          .single();
      final shopId = memberResponse['shop_id'] as String;

      final cashRepo = ref.read(cashRepositoryProvider);

      // On crée le mouvement "Solde Matin"
      await cashRepo.addMovement(
        CashMovementEntity(
          id: '',
          shopId: shopId,
          userId: userId!,
          amount: amount,
          type: 'morning_balance',
          createdAt: DateTime.now(),
        ),
      );

      // On rafraîchit le dashboard
      state = AsyncValue.data(await _fetchDashboardData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Action pour clôturer la journée
  Future<void> closeDay(double physicalCash, String? note) async {
    state = const AsyncValue.loading();
    try {
      final currentState = await _fetchDashboardData();

      final userId = Supabase.instance.client.auth.currentUser?.id;
      final memberResponse = await Supabase.instance.client
          .from('shop_members')
          .select('shop_id')
          .eq('user_id', userId!)
          .limit(1)
          .single();
      final shopId = memberResponse['shop_id'] as String;

      // 👇 FORMULE 2 : L'ÉCART DE CAISSE 👇
      final cashGap = physicalCash - currentState.calculatedCash;

      final closingRepo = ref.read(closingRepositoryProvider);

      // On sauvegarde la clôture
      await closingRepo.saveClosing(
        DailyClosingEntity(
          id: '',
          shopId: shopId,
          userId: userId!,
          closingDate: DateTime.now(),
          morningBalance: currentState.morningBalance,
          totalSales: currentState.totalSales,
          totalWithdrawals: currentState.totalWithdrawals,
          calculatedCash: currentState.calculatedCash,
          grossProfit: currentState.grossProfit,
          netProfit: currentState.netProfit,
          physicalCash: physicalCash,
          cashGap: cashGap,
          isClosed: true,
          note: note,
        ),
      );

      // On rafraîchit le dashboard (qui va maintenant afficher l'état clôturé)
      state = AsyncValue.data(await _fetchDashboardData());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
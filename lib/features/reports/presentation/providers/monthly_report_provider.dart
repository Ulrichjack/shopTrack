import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/domain/entities/daily_closing_entity.dart';

// Modèle pour stocker les résultats du mois
class MonthlyReportState {
  final double totalSales;
  final double totalNetProfit;
  final double totalWithdrawals;
  final double totalCashGap; // L'écart total (s'il y a eu des trous dans la caisse)
  final List<DailyClosingEntity> dailyClosings;

  MonthlyReportState({
    required this.totalSales,
    required this.totalNetProfit,
    required this.totalWithdrawals,
    required this.totalCashGap,
    required this.dailyClosings,
  });
}

// On utilise un FamilyProvider pour pouvoir lui passer le mois et l'année en paramètre
final monthlyReportProvider = FutureProvider.family<MonthlyReportState, DateTime>((ref, date) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('Non connecté');

  final memberResponse = await Supabase.instance.client
      .from('shop_members')
      .select('shop_id')
      .eq('user_id', userId)
      .limit(1)
      .single();
  final shopId = memberResponse['shop_id'] as String;

  final closingRepo = ref.read(closingRepositoryProvider);

  // On récupère toutes les clôtures du mois demandé
  final closings = await closingRepo.getClosingsForMonth(shopId, date.year, date.month);

  double totalSales = 0;
  double totalNetProfit = 0;
  double totalWithdrawals = 0;
  double totalCashGap = 0;

  // On additionne tout !
  for (var closing in closings) {
    totalSales += closing.totalSales;
    totalNetProfit += closing.netProfit;
    totalWithdrawals += closing.totalWithdrawals;
    totalCashGap += (closing.cashGap ?? 0);
  }

  return MonthlyReportState(
    totalSales: totalSales,
    totalNetProfit: totalNetProfit,
    totalWithdrawals: totalWithdrawals,
    totalCashGap: totalCashGap,
    dailyClosings: closings,
  );
});
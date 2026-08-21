import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/cash_movement_model.dart';

class CashRemoteDataSource {
  final SupabaseClient supabase;

  CashRemoteDataSource(this.supabase);

  Future<void> addMovement(CashMovementModel movement) async {
    await supabase.from('cash_movements').insert(movement.toJson());
  }

  Future<List<CashMovementModel>> getTodayMovements(
    String shopId,
    DateTime date,
  ) async {
    // On prend du début à la fin de la journée
    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    ).toUtc().toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    final response = await supabase
        .from('cash_movements')
        .select()
        .eq('shop_id', shopId)
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay);

    return response.map((json) => CashMovementModel.fromJson(json)).toList();
  }
}

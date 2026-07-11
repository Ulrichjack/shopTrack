import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_closing_model.dart';

class ClosingRemoteDataSource {
  final SupabaseClient supabase;

  ClosingRemoteDataSource(this.supabase);

  Future<void> saveClosing(DailyClosingModel closing) async {
    await supabase.from('daily_closings').upsert(
      closing.toJson(),
      onConflict: 'shop_id,closing_date', // Résout le conflit automatiquement !
    );
  }

  Future<DailyClosingModel?> getClosingForDate(String shopId, DateTime date) async {
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await supabase
        .from('daily_closings')
        .select()
        .eq('shop_id', shopId)
        .eq('closing_date', dateString)
        .maybeSingle();

    if (response == null) return null;
    return DailyClosingModel.fromJson(response);
  }

  Future<List<DailyClosingModel>> getClosingsForMonth(String shopId, int year, int month) async {
    // On crée la date de début (1er du mois) et de fin (dernier jour du mois)
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final response = await supabase
        .from('daily_closings')
        .select()
        .eq('shop_id', shopId)
        .gte('closing_date', startDate)
        .lte('closing_date', endDate)
        .order('closing_date', ascending: true); // Trié du 1er au 31

    return response.map((json) => DailyClosingModel.fromJson(json)).toList();
  }



}
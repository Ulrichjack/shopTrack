import '../entities/daily_closing_entity.dart';

abstract class ClosingRepository {
  Future<void> saveClosing(DailyClosingEntity closing);
  Future<DailyClosingEntity?> getClosingForDate(String shopId, DateTime date);
  Future<List<DailyClosingEntity>> getClosingsForMonth(
    String shopId,
    int year,
    int month,
  );
}

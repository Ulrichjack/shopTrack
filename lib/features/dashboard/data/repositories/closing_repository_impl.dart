import '../../domain/entities/daily_closing_entity.dart';
import '../../domain/repositories/closing_repository.dart';
import '../datasources/closing_remote_datasource.dart';
import '../models/daily_closing_model.dart';

class ClosingRepositoryImpl implements ClosingRepository {
  final ClosingRemoteDataSource remoteDataSource;

  ClosingRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> saveClosing(DailyClosingEntity closing) async {
    final model = DailyClosingModel(
      id: closing.id,
      shopId: closing.shopId,
      userId: closing.userId,
      closingDate: closing.closingDate,
      morningBalance: closing.morningBalance,
      totalSales: closing.totalSales,
      totalWithdrawals: closing.totalWithdrawals,
      calculatedCash: closing.calculatedCash,
      grossProfit: closing.grossProfit,
      netProfit: closing.netProfit,
      physicalCash: closing.physicalCash,
      cashGap: closing.cashGap,
      isClosed: closing.isClosed,
      note: closing.note,
    );
    await remoteDataSource.saveClosing(model);
  }

  @override
  Future<DailyClosingEntity?> getClosingForDate(String shopId, DateTime date) async {
    return remoteDataSource.getClosingForDate(shopId, date);
  }

  @override
  Future<List<DailyClosingEntity>> getClosingsForMonth(String shopId, int year, int month) async {
    return remoteDataSource.getClosingsForMonth(shopId, year, month);
  }

}
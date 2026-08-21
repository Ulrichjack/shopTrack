import '../../domain/entities/cash_movement_entity.dart';
import '../../domain/models/cash_movement_model.dart';
import '../../domain/repositories/cash_repository.dart';
import '../datasources/cash_remote_datasource.dart';

class CashRepositoryImpl implements CashRepository {
  final CashRemoteDataSource remoteDataSource;

  CashRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> addMovement(CashMovementEntity movement) async {
    final model = CashMovementModel(
      id: movement.id,
      shopId: movement.shopId,
      userId: movement.userId,
      amount: movement.amount,
      type: movement.type,
      category: movement.category,
      note: movement.note,
      createdAt: movement.createdAt,
    );
    await remoteDataSource.addMovement(model);
  }

  @override
  Future<List<CashMovementEntity>> getTodayMovements(
    String shopId,
    DateTime date,
  ) async {
    return remoteDataSource.getTodayMovements(shopId, date);
  }
}

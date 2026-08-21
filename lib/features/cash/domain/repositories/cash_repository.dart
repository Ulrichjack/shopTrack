import '../entities/cash_movement_entity.dart';

abstract class CashRepository {
  Future<void> addMovement(CashMovementEntity movement);
  Future<List<CashMovementEntity>> getTodayMovements(
    String shopId,
    DateTime date,
  );
}

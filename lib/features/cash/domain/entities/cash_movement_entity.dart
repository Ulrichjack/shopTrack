class CashMovementEntity {
  final String id;
  final String shopId;
  final String userId;
  final double amount;
  final String type; // 'morning_balance', 'withdrawal', 'incoming'
  final String? category;
  final String? note;
  final DateTime createdAt;

  CashMovementEntity({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.amount,
    required this.type,
    this.category,
    this.note,
    required this.createdAt,
  });
}

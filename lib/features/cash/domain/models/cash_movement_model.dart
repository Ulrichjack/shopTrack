import '../../domain/entities/cash_movement_entity.dart';

class CashMovementModel extends CashMovementEntity {
  CashMovementModel({
    required super.id,
    required super.shopId,
    required super.userId,
    required super.amount,
    required super.type,
    super.category,
    super.note,
    required super.createdAt,
  });

  factory CashMovementModel.fromJson(Map<String, dynamic> json) {
    return CashMovementModel(
      id: json['id'],
      shopId: json['shop_id'],
      userId: json['user_id'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      category: json['category'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
    };
  }
}

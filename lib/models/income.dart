import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import 'enums.dart';

part 'income.freezed.dart';

@freezed
abstract class Income with _$Income {
  const Income._();

  const factory Income({
    required String id,
    required DateTime date,
    required double amount,
    String? description,
    int? eggCount,
    String? flockId,
    @Default(IncomeType.sale) IncomeType type,
    String? recipientId,
    required DateTime createdAt,
  }) = _Income;

  /// Create a new income with generated ID and timestamp
  factory Income.create({
    required DateTime date,
    required double amount,
    String? description,
    int? eggCount,
    String? flockId,
    IncomeType type = IncomeType.sale,
    String? recipientId,
  }) {
    return Income(
      id: const Uuid().v4(),
      date: date,
      amount: amount,
      description: description,
      eggCount: eggCount,
      flockId: flockId,
      type: type,
      recipientId: recipientId,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      eggCount: map['egg_count'] as int?,
      flockId: map['flock_id'] as String?,
      type: IncomeType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? 'sale'),
        orElse: () => IncomeType.sale,
      ),
      recipientId: map['recipient_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'description': description,
      'egg_count': eggCount,
      'flock_id': flockId,
      'type': type.name,
      'recipient_id': recipientId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isGift => type == IncomeType.gift;

  /// Calculate price per egg if egg count is available
  double? get pricePerEgg {
    if (eggCount == null || eggCount == 0) return null;
    return amount / eggCount!;
  }
}

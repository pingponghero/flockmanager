import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

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
    required DateTime createdAt,
  }) = _Income;

  /// Create a new income with generated ID and timestamp
  factory Income.create({
    required DateTime date,
    required double amount,
    String? description,
    int? eggCount,
  }) {
    return Income(
      id: const Uuid().v4(),
      date: date,
      amount: amount,
      description: description,
      eggCount: eggCount,
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Calculate price per egg if egg count is available
  double? get pricePerEgg {
    if (eggCount == null || eggCount == 0) return null;
    return amount / eggCount!;
  }
}

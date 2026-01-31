import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import 'enums.dart';

part 'expense.freezed.dart';

@freezed
abstract class Expense with _$Expense {
  const Expense._();

  const factory Expense({
    required String id,
    required DateTime date,
    required double amount,
    required ExpenseCategory category,
    String? description,
    String? flockId,
    @Default(false) bool isRecurring,
    RecurringInterval? recurringInterval,
    required DateTime createdAt,
  }) = _Expense;

  /// Create a new expense with generated ID and timestamp
  factory Expense.create({
    required DateTime date,
    required double amount,
    required ExpenseCategory category,
    String? description,
    String? flockId,
    bool isRecurring = false,
    RecurringInterval? recurringInterval,
  }) {
    return Expense(
      id: const Uuid().v4(),
      date: date,
      amount: amount,
      category: category,
      description: description,
      flockId: flockId,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: map['description'] as String?,
      flockId: map['flock_id'] as String?,
      isRecurring: (map['is_recurring'] as int?) == 1,
      recurringInterval: map['recurring_interval'] != null
          ? RecurringInterval.values.firstWhere(
              (e) => e.name == map['recurring_interval'],
              orElse: () => RecurringInterval.monthly,
            )
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category.name,
      'description': description,
      'flock_id': flockId,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_interval': recurringInterval?.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/expense.dart';
import 'package:flock_manager/models/enums.dart';

void main() {
  group('Expense', () {
    test('create() generates unique ID and timestamp', () {
      final expense = Expense.create(
        date: DateTime(2024, 1, 15),
        amount: 49.99,
        category: ExpenseCategory.feed,
      );

      expect(expense.id, isNotEmpty);
      expect(expense.amount, 49.99);
      expect(expense.category, ExpenseCategory.feed);
      expect(expense.isRecurring, false);
      expect(expense.createdAt, isNotNull);
    });

    test('create() with recurring expense', () {
      final expense = Expense.create(
        date: DateTime(2024, 1, 1),
        amount: 25.00,
        category: ExpenseCategory.bedding,
        description: 'Monthly bedding',
        isRecurring: true,
        recurringInterval: RecurringInterval.monthly,
      );

      expect(expense.isRecurring, true);
      expect(expense.recurringInterval, RecurringInterval.monthly);
    });

    test('toMap() converts to SQLite-compatible map', () {
      final date = DateTime(2024, 1, 15);
      final createdAt = DateTime(2024, 1, 15, 10, 0);

      final expense = Expense(
        id: 'expense-123',
        date: date,
        amount: 75.50,
        category: ExpenseCategory.medical,
        description: 'Vet visit',
        flockId: 'flock-456',
        isRecurring: false,
        createdAt: createdAt,
      );

      final map = expense.toMap();

      expect(map['id'], 'expense-123');
      expect(map['amount'], 75.50);
      expect(map['category'], 'medical');
      expect(map['description'], 'Vet visit');
      expect(map['flock_id'], 'flock-456');
      expect(map['is_recurring'], 0);
    });

    test('fromMap() creates Expense from SQLite map', () {
      final map = {
        'id': 'expense-456',
        'date': '2024-06-20T00:00:00.000',
        'amount': 150.00,
        'category': 'equipment',
        'description': 'New waterer',
        'flock_id': null,
        'is_recurring': 0,
        'recurring_interval': null,
        'created_at': '2024-06-20T00:00:00.000',
      };

      final expense = Expense.fromMap(map);

      expect(expense.id, 'expense-456');
      expect(expense.amount, 150.00);
      expect(expense.category, ExpenseCategory.equipment);
      expect(expense.isRecurring, false);
    });

    test('fromMap() handles recurring expense', () {
      final map = {
        'id': 'expense-789',
        'date': '2024-01-01T00:00:00.000',
        'amount': 30.00,
        'category': 'feed',
        'description': 'Weekly feed delivery',
        'flock_id': 'flock-123',
        'is_recurring': 1,
        'recurring_interval': 'weekly',
        'created_at': '2024-01-01T00:00:00.000',
      };

      final expense = Expense.fromMap(map);

      expect(expense.isRecurring, true);
      expect(expense.recurringInterval, RecurringInterval.weekly);
    });

    test('roundtrip: toMap -> fromMap preserves data', () {
      final original = Expense.create(
        date: DateTime(2024, 3, 15),
        amount: 99.99,
        category: ExpenseCategory.supplies,
        description: 'Egg cartons',
        flockId: 'flock-123',
        isRecurring: true,
        recurringInterval: RecurringInterval.monthly,
      );

      final map = original.toMap();
      final restored = Expense.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.category, original.category);
      expect(restored.isRecurring, original.isRecurring);
      expect(restored.recurringInterval, original.recurringInterval);
    });
  });
}

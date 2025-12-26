import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/income.dart';

void main() {
  group('Income', () {
    test('create() generates unique ID and timestamp', () {
      final income = Income.create(
        date: DateTime(2024, 1, 15),
        amount: 24.00,
      );

      expect(income.id, isNotEmpty);
      expect(income.amount, 24.00);
      expect(income.createdAt, isNotNull);
    });

    test('create() with all fields', () {
      final income = Income.create(
        date: DateTime(2024, 1, 15),
        amount: 36.00,
        description: 'Sold 3 dozen eggs',
        eggCount: 36,
      );

      expect(income.description, 'Sold 3 dozen eggs');
      expect(income.eggCount, 36);
    });

    test('toMap() converts to SQLite-compatible map', () {
      final date = DateTime(2024, 1, 15);
      final createdAt = DateTime(2024, 1, 15, 14, 0);

      final income = Income(
        id: 'income-123',
        date: date,
        amount: 48.00,
        description: 'Farmers market sales',
        eggCount: 48,
        createdAt: createdAt,
      );

      final map = income.toMap();

      expect(map['id'], 'income-123');
      expect(map['amount'], 48.00);
      expect(map['description'], 'Farmers market sales');
      expect(map['egg_count'], 48);
    });

    test('fromMap() creates Income from SQLite map', () {
      final map = {
        'id': 'income-456',
        'date': '2024-06-20T00:00:00.000',
        'amount': 60.00,
        'description': 'Neighbor purchase',
        'egg_count': 60,
        'created_at': '2024-06-20T00:00:00.000',
      };

      final income = Income.fromMap(map);

      expect(income.id, 'income-456');
      expect(income.amount, 60.00);
      expect(income.eggCount, 60);
    });

    test('pricePerEgg calculates correctly', () {
      final income = Income(
        id: 'income-price',
        date: DateTime(2024, 1, 15),
        amount: 12.00,
        eggCount: 24,
        createdAt: DateTime.now(),
      );

      expect(income.pricePerEgg, 0.5);
    });

    test('pricePerEgg returns null when eggCount is null', () {
      final income = Income(
        id: 'income-no-count',
        date: DateTime(2024, 1, 15),
        amount: 50.00,
        createdAt: DateTime.now(),
      );

      expect(income.pricePerEgg, isNull);
    });

    test('pricePerEgg returns null when eggCount is zero', () {
      final income = Income(
        id: 'income-zero',
        date: DateTime(2024, 1, 15),
        amount: 50.00,
        eggCount: 0,
        createdAt: DateTime.now(),
      );

      expect(income.pricePerEgg, isNull);
    });

    test('roundtrip: toMap -> fromMap preserves data', () {
      final original = Income.create(
        date: DateTime(2024, 3, 15),
        amount: 72.00,
        description: 'Monthly sales',
        eggCount: 144,
      );

      final map = original.toMap();
      final restored = Income.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.eggCount, original.eggCount);
    });
  });
}

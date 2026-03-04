import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/repositories/expense_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late ExpenseRepository repository;

  final start = DateTime(2024, 1, 1);
  final end = DateTime(2024, 12, 31);
  final startStr = DateTime(2024, 1, 1).toIso8601String();
  final endStr = DateTime(2024, 12, 31, 23, 59, 59).toIso8601String();

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    repository = ExpenseRepository(db: mockDbHelper);
  });

  group('getTotalExpenses', () {
    test('returns sum of expenses in date range', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'total': 198.50}]);

      final result = await repository.getTotalExpenses(start, end);

      expect(result, 198.50);
      verify(() => mockDatabase.rawQuery(
            any(that: contains('FROM expenses')),
            [startStr, endStr],
          )).called(1);
    });

    test('returns 0.0 when no expenses', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'total': 0}]);

      final result = await repository.getTotalExpenses(start, end);

      expect(result, 0.0);
    });
  });

  group('getTotalExpensesByFlock', () {
    test('includes shared expenses (null flock_id)', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'total': 150.0}]);

      final result =
          await repository.getTotalExpensesByFlock('flock-1', start, end);

      expect(result, 150.0);
      verify(() => mockDatabase.rawQuery(
            any(that: contains('flock_id IS NULL')),
            [startStr, endStr, 'flock-1'],
          )).called(1);
    });
  });

  group('getTotalExpensesAllTime', () {
    test('returns sum of all expenses', () async {
      when(() => mockDatabase.rawQuery(any()))
          .thenAnswer((_) async => [{'total': 500.0}]);

      final result = await repository.getTotalExpensesAllTime();

      expect(result, 500.0);
    });

    test('returns 0.0 when no expenses', () async {
      when(() => mockDatabase.rawQuery(any()))
          .thenAnswer((_) async => [{'total': 0}]);

      final result = await repository.getTotalExpensesAllTime();

      expect(result, 0.0);
    });
  });

  group('getTotalIncome', () {
    test('returns sum of income in date range', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'total': 54.0}]);

      final result = await repository.getTotalIncome(start, end);

      expect(result, 54.0);
    });

    test('returns 0.0 when no income', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'total': 0}]);

      final result = await repository.getTotalIncome(start, end);

      expect(result, 0.0);
    });
  });

  group('getTotalIncomeByFlock', () {
    test('includes shared income (null flock_id)', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'total': 30.0}]);

      final result =
          await repository.getTotalIncomeByFlock('flock-1', start, end);

      expect(result, 30.0);
      verify(() => mockDatabase.rawQuery(
            any(that: contains('flock_id IS NULL')),
            [startStr, endStr, 'flock-1'],
          )).called(1);
    });
  });

  group('getTotalIncomeAllTime', () {
    test('returns sum of all income', () async {
      when(() => mockDatabase.rawQuery(any()))
          .thenAnswer((_) async => [{'total': 200.0}]);

      final result = await repository.getTotalIncomeAllTime();

      expect(result, 200.0);
    });
  });

  group('getEggSalesData', () {
    test('returns eggs sold and sale income for date range', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'eggs': 108, 'income': 54.0}]);

      final (eggsSold, saleIncome) =
          await repository.getEggSalesData(start, end);

      expect(eggsSold, 108);
      expect(saleIncome, 54.0);
    });

    test('excludes income without egg_count', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'eggs': 0, 'income': 0}]);

      final (eggsSold, saleIncome) =
          await repository.getEggSalesData(start, end);

      expect(eggsSold, 0);
      expect(saleIncome, 0.0);
      verify(() => mockDatabase.rawQuery(
            any(that: contains('egg_count IS NOT NULL')),
            any(),
          )).called(1);
    });

    test('returns zeros when no matching records', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'eggs': 0, 'income': 0}]);

      final (eggsSold, saleIncome) =
          await repository.getEggSalesData(start, end);

      expect(eggsSold, 0);
      expect(saleIncome, 0.0);
    });
  });

  group('getEggSalesDataByFlock', () {
    test('includes shared income (null flock_id)', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [{'eggs': 50, 'income': 25.0}]);

      final (eggsSold, saleIncome) =
          await repository.getEggSalesDataByFlock('flock-1', start, end);

      expect(eggsSold, 50);
      expect(saleIncome, 25.0);
      verify(() => mockDatabase.rawQuery(
            any(that: contains('flock_id IS NULL')),
            [startStr, endStr, 'flock-1'],
          )).called(1);
    });
  });

  group('getEggSalesDataAllTime', () {
    test('returns all-time egg sales data', () async {
      when(() => mockDatabase.rawQuery(any()))
          .thenAnswer((_) async => [{'eggs': 300, 'income': 150.0}]);

      final (eggsSold, saleIncome) =
          await repository.getEggSalesDataAllTime();

      expect(eggsSold, 300);
      expect(saleIncome, 150.0);
    });

    test('returns zeros when no sales with egg counts', () async {
      when(() => mockDatabase.rawQuery(any()))
          .thenAnswer((_) async => [{'eggs': 0, 'income': 0}]);

      final (eggsSold, saleIncome) =
          await repository.getEggSalesDataAllTime();

      expect(eggsSold, 0);
      expect(saleIncome, 0.0);
    });
  });

  group('getExpensesByCategoriesByFlock', () {
    test('returns expenses grouped by category', () async {
      when(() => mockDatabase.rawQuery(any(), any())).thenAnswer((_) async => [
            {'category': 'feed', 'total': 80.0},
            {'category': 'bedding', 'total': 15.0},
            {'category': 'supplies', 'total': 33.0},
          ]);

      final result = await repository.getExpensesByCategoriesByFlock(
          'flock-1', start, end);

      expect(result[ExpenseCategory.feed], 80.0);
      expect(result[ExpenseCategory.bedding], 15.0);
      expect(result[ExpenseCategory.supplies], 33.0);
      expect(result.length, 3);
    });

    test('returns empty map when no expenses', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => []);

      final result = await repository.getExpensesByCategoriesByFlock(
          'flock-1', start, end);

      expect(result, isEmpty);
    });

    test('includes shared expenses (null flock_id)', () async {
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => []);

      await repository.getExpensesByCategoriesByFlock('flock-1', start, end);

      verify(() => mockDatabase.rawQuery(
            any(that: contains('flock_id IS NULL')),
            any(),
          )).called(1);
    });
  });
}

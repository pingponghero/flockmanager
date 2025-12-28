import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/enums.dart';

/// Repository for expense and income data access operations.
class ExpenseRepository {
  final DatabaseHelper _db;

  ExpenseRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  // ==================== EXPENSES ====================

  /// Get all expenses, ordered by date descending.
  Future<List<Expense>> getAllExpenses() async {
    final db = await _db.database;

    final maps = await db.query(
      'expenses',
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses within a date range (inclusive).
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses by category.
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    final db = await _db.database;

    final maps = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses for a specific flock.
  Future<List<Expense>> getExpensesByFlock(String flockId) async {
    final db = await _db.database;

    final maps = await db.query(
      'expenses',
      where: 'flock_id = ?',
      whereArgs: [flockId],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get a single expense by ID.
  Future<Expense?> getExpenseById(String id) async {
    final db = await _db.database;

    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  /// Insert a new expense.
  Future<void> insertExpense(Expense expense) async {
    final db = await _db.database;
    await db.insert('expenses', expense.toMap());
  }

  /// Update an existing expense.
  Future<void> updateExpense(Expense expense) async {
    final db = await _db.database;

    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Delete an expense.
  Future<void> deleteExpense(String id) async {
    final db = await _db.database;

    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total expenses within a date range.
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ?',
      [startStr, endStr],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total expenses for all time.
  Future<double> getTotalExpensesAllTime() async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses',
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get expenses grouped by category within a date range.
  Future<Map<ExpenseCategory, double>> getExpensesByCategories(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE date >= ? AND date <= ?
      GROUP BY category
      ''',
      [startStr, endStr],
    );

    final categories = <ExpenseCategory, double>{};
    for (final row in result) {
      final categoryName = row['category'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final category = ExpenseCategory.values.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => ExpenseCategory.other,
      );
      categories[category] = total;
    }
    return categories;
  }

  // ==================== INCOME ====================

  /// Get all income records, ordered by date descending.
  Future<List<Income>> getAllIncome() async {
    final db = await _db.database;

    final maps = await db.query(
      'income',
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => Income.fromMap(map)).toList();
  }

  /// Get income within a date range (inclusive).
  Future<List<Income>> getIncomeByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      'income',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => Income.fromMap(map)).toList();
  }

  /// Get a single income record by ID.
  Future<Income?> getIncomeById(String id) async {
    final db = await _db.database;

    final maps = await db.query(
      'income',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Income.fromMap(maps.first);
  }

  /// Insert a new income record.
  Future<void> insertIncome(Income income) async {
    final db = await _db.database;
    await db.insert('income', income.toMap());
  }

  /// Update an existing income record.
  Future<void> updateIncome(Income income) async {
    final db = await _db.database;

    await db.update(
      'income',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  /// Delete an income record.
  Future<void> deleteIncome(String id) async {
    final db = await _db.database;

    await db.delete(
      'income',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total income within a date range.
  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM income WHERE date >= ? AND date <= ?',
      [startStr, endStr],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total income for all time.
  Future<double> getTotalIncomeAllTime() async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM income',
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total eggs sold within a date range.
  Future<int> getTotalEggsSold(DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(egg_count), 0) as total FROM income WHERE date >= ? AND date <= ? AND egg_count IS NOT NULL',
      [startStr, endStr],
    );

    return (result.first['total'] as int?) ?? 0;
  }
}

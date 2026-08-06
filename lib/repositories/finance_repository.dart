import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/enums.dart';
import '../models/recipient.dart';

/// Aggregated sale/gift statistics for one recipient.
class RecipientStats {
  final int saleCount;
  final int giftCount;
  final int eggsSold;
  final int eggsGifted;
  final double totalIncome;

  const RecipientStats({
    this.saleCount = 0,
    this.giftCount = 0,
    this.eggsSold = 0,
    this.eggsGifted = 0,
    this.totalIncome = 0,
  });
}

/// Repository for expense and income data access operations.
class FinanceRepository {
  final DatabaseHelper _db;

  FinanceRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

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
  /// Includes shared expenses (null flock_id) and flock-specific.
  Future<List<Expense>> getExpensesByFlock(String flockId) async {
    final db = await _db.database;

    final maps = await db.query(
      'expenses',
      where: 'flock_id = ? OR flock_id IS NULL',
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

  /// Insert a new expense. Amount must be positive.
  Future<void> insertExpense(Expense expense) async {
    if (expense.amount <= 0) {
      throw ArgumentError('Expense amount must be positive');
    }
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

  /// Get total expenses within a date range for a specific flock.
  /// Includes shared expenses (null flock_id) and flock-specific.
  Future<double> getTotalExpensesByFlock(
      String flockId, DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses '
      'WHERE date >= ? AND date <= ? AND (flock_id = ? OR flock_id IS NULL)',
      [startStr, endStr, flockId],
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

  /// Get expenses grouped by category within a date range for a specific flock.
  /// Includes shared expenses (null flock_id) and flock-specific.
  Future<Map<ExpenseCategory, double>> getExpensesByCategoriesByFlock(
    String flockId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE date >= ? AND date <= ? AND (flock_id = ? OR flock_id IS NULL)
      GROUP BY category
      ''',
      [startStr, endStr, flockId],
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

  /// Get the earliest expense date, or null if no expenses exist.
  Future<DateTime?> getFirstExpenseDate() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT MIN(date) as first_date FROM expenses',
    );
    final dateStr = result.first['first_date'] as String?;
    return dateStr != null ? DateTime.parse(dateStr) : null;
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

  /// Get income for a specific flock.
  /// Includes shared income (null flock_id) and flock-specific.
  Future<List<Income>> getIncomeByFlock(String flockId) async {
    final db = await _db.database;

    final maps = await db.query(
      'income',
      where: 'flock_id = ? OR flock_id IS NULL',
      whereArgs: [flockId],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => Income.fromMap(map)).toList();
  }

  /// Get the earliest income date, or null if no income exists.
  Future<DateTime?> getFirstIncomeDate() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT MIN(date) as first_date FROM income',
    );
    final dateStr = result.first['first_date'] as String?;
    return dateStr != null ? DateTime.parse(dateStr) : null;
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

  /// Insert a new income record. Sales must have a positive amount;
  /// gifts are recorded with amount 0.
  Future<void> insertIncome(Income income) async {
    if (income.amount < 0) {
      throw ArgumentError('Income amount cannot be negative');
    }
    if (income.type == IncomeType.sale && income.amount <= 0) {
      throw ArgumentError('Sale amount must be positive');
    }
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

  /// Get total income within a date range for a specific flock.
  /// Includes shared income (null flock_id) and flock-specific.
  Future<double> getTotalIncomeByFlock(
      String flockId, DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM income '
      'WHERE date >= ? AND date <= ? AND (flock_id = ? OR flock_id IS NULL)',
      [startStr, endStr, flockId],
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

  /// Get daily expense totals within a date range.
  Future<Map<DateTime, double>> getDailyExpenses(
      DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT date(date) as day, SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ? GROUP BY date(date) ORDER BY day ASC',
      [startStr, endStr],
    );

    final counts = <DateTime, double>{};
    for (final row in result) {
      final dayStr = row['day'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final day = DateTime.parse(dayStr);
      counts[DateTime(day.year, day.month, day.day)] = total;
    }
    return counts;
  }

  /// Get daily income totals within a date range.
  Future<Map<DateTime, double>> getDailyIncome(
      DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT date(date) as day, SUM(amount) as total FROM income WHERE date >= ? AND date <= ? GROUP BY date(date) ORDER BY day ASC',
      [startStr, endStr],
    );

    final counts = <DateTime, double>{};
    for (final row in result) {
      final dayStr = row['day'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final day = DateTime.parse(dayStr);
      counts[DateTime(day.year, day.month, day.day)] = total;
    }
    return counts;
  }

  /// Get total eggs sold within a date range.
  Future<int> getTotalEggsSold(DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(egg_count), 0) as total FROM income "
      "WHERE date >= ? AND date <= ? AND egg_count IS NOT NULL AND type = 'sale'",
      [startStr, endStr],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get eggs sold and their actual sale income within a date range.
  ///
  /// Returns (eggsSold, saleIncome) from income records that have egg_count.
  /// Income records without egg_count are excluded — those are treated as
  /// additive cash with no egg count adjustment.
  Future<(int eggsSold, double saleIncome)> getEggSalesData(
      DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(egg_count), 0) as eggs, COALESCE(SUM(amount), 0) as income '
      "FROM income WHERE date >= ? AND date <= ? AND egg_count IS NOT NULL AND type = 'sale'",
      [startStr, endStr],
    );

    final eggs = (result.first['eggs'] as int?) ?? 0;
    final income = (result.first['income'] as num?)?.toDouble() ?? 0.0;
    return (eggs, income);
  }

  /// Get eggs sold and sale income for a specific flock within a date range.
  /// Includes shared income (null flock_id) and flock-specific.
  Future<(int eggsSold, double saleIncome)> getEggSalesDataByFlock(
      String flockId, DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(egg_count), 0) as eggs, COALESCE(SUM(amount), 0) as income '
      "FROM income WHERE date >= ? AND date <= ? AND egg_count IS NOT NULL AND type = 'sale' "
      'AND (flock_id = ? OR flock_id IS NULL)',
      [startStr, endStr, flockId],
    );

    final eggs = (result.first['eggs'] as int?) ?? 0;
    final income = (result.first['income'] as num?)?.toDouble() ?? 0.0;
    return (eggs, income);
  }

  /// Get eggs sold and sale income for all time.
  Future<(int eggsSold, double saleIncome)> getEggSalesDataAllTime() async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(egg_count), 0) as eggs, COALESCE(SUM(amount), 0) as income '
      "FROM income WHERE egg_count IS NOT NULL AND type = 'sale'",
    );

    final eggs = (result.first['eggs'] as int?) ?? 0;
    final income = (result.first['income'] as num?)?.toDouble() ?? 0.0;
    return (eggs, income);
  }

  // ==================== GIFTS ====================

  /// Get total eggs gifted within a date range.
  Future<int> getEggsGifted(DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(egg_count), 0) as eggs FROM income "
      "WHERE date >= ? AND date <= ? AND egg_count IS NOT NULL AND type = 'gift'",
      [startStr, endStr],
    );

    return (result.first['eggs'] as int?) ?? 0;
  }

  /// Get total eggs gifted for a specific flock within a date range.
  /// Includes shared gifts (null flock_id) and flock-specific.
  Future<int> getEggsGiftedByFlock(
      String flockId, DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr =
        DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(egg_count), 0) as eggs FROM income "
      "WHERE date >= ? AND date <= ? AND egg_count IS NOT NULL AND type = 'gift' "
      'AND (flock_id = ? OR flock_id IS NULL)',
      [startStr, endStr, flockId],
    );

    return (result.first['eggs'] as int?) ?? 0;
  }

  /// Get total eggs gifted for all time.
  Future<int> getEggsGiftedAllTime() async {
    final db = await _db.database;

    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(egg_count), 0) as eggs FROM income "
      "WHERE egg_count IS NOT NULL AND type = 'gift'",
    );

    return (result.first['eggs'] as int?) ?? 0;
  }

  /// Count distinct recipients that have received at least one gift.
  Future<int> getGiftRecipientCount() async {
    final db = await _db.database;

    final result = await db.rawQuery(
      "SELECT COUNT(DISTINCT recipient_id) as count FROM income "
      "WHERE type = 'gift' AND recipient_id IS NOT NULL",
    );

    return (result.first['count'] as int?) ?? 0;
  }

  // ==================== RECIPIENTS ====================

  /// Get all recipients, ordered by name.
  Future<List<Recipient>> getAllRecipients() async {
    final db = await _db.database;

    final maps = await db.query(
      'recipients',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return maps.map((map) => Recipient.fromMap(map)).toList();
  }

  /// Get a single recipient by ID.
  Future<Recipient?> getRecipientById(String id) async {
    final db = await _db.database;

    final maps = await db.query(
      'recipients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Recipient.fromMap(maps.first);
  }

  /// Insert a new recipient. Name must be non-empty.
  Future<void> insertRecipient(Recipient recipient) async {
    if (recipient.name.trim().isEmpty) {
      throw ArgumentError('Recipient name cannot be empty');
    }
    final db = await _db.database;
    await db.insert('recipients', recipient.toMap());
  }

  /// Update an existing recipient.
  Future<void> updateRecipient(Recipient recipient) async {
    final db = await _db.database;

    await db.update(
      'recipients',
      recipient.toMap(),
      where: 'id = ?',
      whereArgs: [recipient.id],
    );
  }

  /// Delete a recipient. Income records keep their data but are unlinked.
  Future<void> deleteRecipient(String id) async {
    final db = await _db.database;

    await db.update(
      'income',
      {'recipient_id': null},
      where: 'recipient_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'recipients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Aggregated per-recipient statistics across all income records.
  Future<Map<String, RecipientStats>> getRecipientStats() async {
    final db = await _db.database;

    final rows = await db.rawQuery('''
      SELECT recipient_id, type,
             COUNT(*) as records,
             COALESCE(SUM(egg_count), 0) as eggs,
             COALESCE(SUM(amount), 0) as total
      FROM income
      WHERE recipient_id IS NOT NULL
      GROUP BY recipient_id, type
    ''');

    final stats = <String, RecipientStats>{};
    for (final row in rows) {
      final id = row['recipient_id'] as String;
      final isGift = (row['type'] as String?) == 'gift';
      final records = (row['records'] as int?) ?? 0;
      final eggs = (row['eggs'] as int?) ?? 0;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;

      final existing = stats[id] ?? const RecipientStats();
      stats[id] = RecipientStats(
        saleCount: existing.saleCount + (isGift ? 0 : records),
        giftCount: existing.giftCount + (isGift ? records : 0),
        eggsSold: existing.eggsSold + (isGift ? 0 : eggs),
        eggsGifted: existing.eggsGifted + (isGift ? eggs : 0),
        totalIncome: existing.totalIncome + (isGift ? 0 : total),
      );
    }
    return stats;
  }
}

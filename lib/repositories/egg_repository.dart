import '../database/database_helper.dart';
import '../models/egg_log.dart';

/// Repository for egg log data access operations.
class EggRepository {
  final DatabaseHelper _db;

  EggRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  /// Get all egg logs, ordered by date descending.
  Future<List<EggLog>> getAllEggLogs() async {
    final db = await _db.database;

    final maps = await db.query(
      'egg_logs',
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => EggLog.fromMap(map)).toList();
  }

  /// Get egg logs for a specific date.
  Future<List<EggLog>> getEggLogsByDate(DateTime date, {String? flockId}) async {
    final db = await _db.database;

    // Normalize to start of day for comparison
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final String where;
    final List<Object?> whereArgs;

    if (flockId != null) {
      where = 'date(date) = date(?) AND flock_id = ?';
      whereArgs = [dateStr, flockId];
    } else {
      where = 'date(date) = date(?)';
      whereArgs = [dateStr];
    }

    final maps = await db.query(
      'egg_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => EggLog.fromMap(map)).toList();
  }

  /// Get egg logs within a date range (inclusive).
  Future<List<EggLog>> getEggLogsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      'egg_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => EggLog.fromMap(map)).toList();
  }

  /// Get egg logs for a specific flock.
  Future<List<EggLog>> getEggLogsByFlock(String flockId) async {
    final db = await _db.database;

    final maps = await db.query(
      'egg_logs',
      where: 'flock_id = ?',
      whereArgs: [flockId],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => EggLog.fromMap(map)).toList();
  }

  /// Get egg logs for a specific bird.
  Future<List<EggLog>> getEggLogsByBird(String birdId) async {
    final db = await _db.database;

    final maps = await db.query(
      'egg_logs',
      where: 'bird_id = ?',
      whereArgs: [birdId],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => EggLog.fromMap(map)).toList();
  }

  /// Count egg logs for a specific bird.
  Future<int> getEggLogCountByBird(String birdId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM egg_logs WHERE bird_id = ?',
      [birdId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Reassign egg logs from a bird to anonymous (null bird_id).
  Future<int> reassignEggLogsToAnonymous(String birdId) async {
    final db = await _db.database;
    return db.update(
      'egg_logs',
      {'bird_id': null},
      where: 'bird_id = ?',
      whereArgs: [birdId],
    );
  }

  /// Get a single egg log by ID.
  Future<EggLog?> getEggLogById(String id) async {
    final db = await _db.database;

    final maps = await db.query(
      'egg_logs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return EggLog.fromMap(maps.first);
  }

  /// Insert a new egg log.
  Future<void> insertEggLog(EggLog log) async {
    final db = await _db.database;

    await db.insert('egg_logs', log.toMap());
  }

  /// Update an existing egg log.
  Future<void> updateEggLog(EggLog log) async {
    final db = await _db.database;

    await db.update(
      'egg_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Delete an egg log.
  Future<void> deleteEggLog(String id) async {
    final db = await _db.database;

    await db.delete(
      'egg_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total egg count across all logs.
  Future<int> getTotalEggCount() async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs',
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get total egg count for a specific flock.
  Future<int> getTotalEggCountByFlock(String flockId) async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE flock_id = ?',
      [flockId],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get total egg count for a specific bird.
  Future<int> getTotalEggCountByBird(String birdId) async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE bird_id = ?',
      [birdId],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get egg count within a date range.
  Future<int> getEggCountByDateRange(DateTime start, DateTime end) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE date >= ? AND date <= ?',
      [startStr, endStr],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get egg count for a specific flock within a date range.
  Future<int> getEggCountByFlockAndDateRange(
    String flockId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE flock_id = ? AND date >= ? AND date <= ?',
      [flockId, startStr, endStr],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get daily egg counts for a date range (for charts).
  Future<Map<DateTime, int>> getDailyEggCounts(
    DateTime start,
    DateTime end, {
    String? flockId,
  }) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final String query;
    final List<Object?> args;

    if (flockId != null) {
      query = '''
        SELECT date(date) as day, SUM(count) as total
        FROM egg_logs
        WHERE date >= ? AND date <= ? AND flock_id = ?
        GROUP BY date(date)
        ORDER BY day ASC
      ''';
      args = [startStr, endStr, flockId];
    } else {
      query = '''
        SELECT date(date) as day, SUM(count) as total
        FROM egg_logs
        WHERE date >= ? AND date <= ?
        GROUP BY date(date)
        ORDER BY day ASC
      ''';
      args = [startStr, endStr];
    }

    final result = await db.rawQuery(query, args);

    final counts = <DateTime, int>{};
    for (final row in result) {
      final dayStr = row['day'] as String;
      final total = (row['total'] as int?) ?? 0;
      final day = DateTime.parse(dayStr);
      counts[DateTime(day.year, day.month, day.day)] = total;
    }
    return counts;
  }

  /// Get the most recent egg log's flock ID (for defaults).
  Future<String?> getLastLoggedFlockId() async {
    final db = await _db.database;

    final maps = await db.query(
      'egg_logs',
      columns: ['flock_id'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['flock_id'] as String?;
  }

  /// Get egg count for a specific date and flock (for defaults).
  Future<int> getEggCountForDateAndFlock(DateTime date, String flockId) async {
    final db = await _db.database;

    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE date(date) = date(?) AND flock_id = ?',
      [dateStr, flockId],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  // ==================== ACHIEVEMENT QUERIES ====================

  /// Get the maximum eggs logged in a single day
  Future<int> getMaxEggsInOneDay() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(MAX(daily_total), 0) as max_eggs FROM (
        SELECT date(date) as day, SUM(count) as daily_total
        FROM egg_logs
        GROUP BY date(date)
      )
    ''');

    return (result.first['max_eggs'] as int?) ?? 0;
  }

  /// Get the maximum eggs logged in a single day during summer (June, July, August)
  Future<int> getMaxEggsInSummer() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(MAX(daily_total), 0) as max_eggs FROM (
        SELECT date(date) as day, SUM(count) as daily_total
        FROM egg_logs
        WHERE CAST(strftime('%m', date) AS INTEGER) IN (6, 7, 8)
        GROUP BY date(date)
      )
    ''');

    return (result.first['max_eggs'] as int?) ?? 0;
  }

  /// Get current consecutive logging streak (days in a row with logs ending today or yesterday)
  Future<int> getCurrentLoggingStreak() async {
    final db = await _db.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all distinct dates with logs, ordered descending
    final result = await db.rawQuery('''
      SELECT DISTINCT date(date) as log_date
      FROM egg_logs
      ORDER BY log_date DESC
    ''');

    if (result.isEmpty) return 0;

    int streak = 0;
    DateTime? expectedDate;

    for (final row in result) {
      final dateStr = row['log_date'] as String;
      final logDate = DateTime.parse(dateStr);
      final normalizedDate = DateTime(logDate.year, logDate.month, logDate.day);

      if (expectedDate == null) {
        // First entry - must be today or yesterday to count
        final diffFromToday = today.difference(normalizedDate).inDays;
        if (diffFromToday > 1) break; // Streak broken
        expectedDate = normalizedDate;
        streak = 1;
      } else {
        // Check if this is the previous day
        final expectedPrevious = expectedDate.subtract(const Duration(days: 1));
        if (normalizedDate == expectedPrevious) {
          streak++;
          expectedDate = normalizedDate;
        } else {
          break; // Streak broken
        }
      }
    }

    return streak;
  }

  /// Get set of months (1-12) that have egg logs
  Future<Set<int>> getMonthsWithEggs() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT DISTINCT CAST(strftime('%m', date) AS INTEGER) as month
      FROM egg_logs
    ''');

    return result.map((r) => r['month'] as int).toSet();
  }

  /// Get total egg count for a specific month (across all years)
  Future<int> getTotalEggsForMonth(int month) async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(count), 0) as total FROM egg_logs
      WHERE CAST(strftime('%m', date) AS INTEGER) = ?
    ''', [month]);

    return (result.first['total'] as int?) ?? 0;
  }

  /// Check if any log was created before a specific hour
  Future<bool> hasLogBeforeHour(int hour) async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM egg_logs
      WHERE CAST(strftime('%H', created_at) AS INTEGER) < ?
    ''', [hour]);

    return ((result.first['count'] as int?) ?? 0) > 0;
  }

  /// Check if any log was created after a specific hour
  Future<bool> hasLogAfterHour(int hour) async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM egg_logs
      WHERE CAST(strftime('%H', created_at) AS INTEGER) >= ?
    ''', [hour]);

    return ((result.first['count'] as int?) ?? 0) > 0;
  }

  /// Get count of distinct days with egg logs (for "days using app")
  Future<int> getDistinctLogDays() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT date(date)) as days FROM egg_logs
    ''');

    return (result.first['days'] as int?) ?? 0;
  }

  /// Get the longest logging streak ever achieved
  Future<int> getLongestStreak() async {
    final db = await _db.database;

    // Get all distinct dates with logs, ordered ascending
    final result = await db.rawQuery('''
      SELECT DISTINCT date(date) as log_date
      FROM egg_logs
      ORDER BY log_date ASC
    ''');

    if (result.isEmpty) return 0;

    int longestStreak = 0;
    int currentStreak = 1;
    DateTime? previousDate;

    for (final row in result) {
      final dateStr = row['log_date'] as String;
      final logDate = DateTime.parse(dateStr);
      final normalizedDate = DateTime(logDate.year, logDate.month, logDate.day);

      if (previousDate != null) {
        final expectedNext = previousDate.add(const Duration(days: 1));
        if (normalizedDate == expectedNext) {
          currentStreak++;
        } else {
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
          currentStreak = 1;
        }
      }
      previousDate = normalizedDate;
    }

    // Check final streak
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    return longestStreak;
  }

  /// Check if any double yolk egg has been logged
  Future<bool> hasDoubleYolkEgg() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM egg_logs WHERE quality = 'doubleYolk'
    ''');

    return ((result.first['count'] as int?) ?? 0) > 0;
  }

  /// Check if any abnormal egg has been logged
  Future<bool> hasAbnormalEgg() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM egg_logs WHERE quality = 'abnormal'
    ''');

    return ((result.first['count'] as int?) ?? 0) > 0;
  }

  /// Check if any fairy egg has been logged
  Future<bool> hasFairyEgg() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM egg_logs WHERE quality = 'fairy'
    ''');

    return ((result.first['count'] as int?) ?? 0) > 0;
  }

  /// Check if eggs were logged on Christmas Day (Dec 25) any year
  Future<bool> hasChristmasEggs() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM egg_logs
      WHERE strftime('%m-%d', date) = '12-25'
    ''');

    return ((result.first['count'] as int?) ?? 0) > 0;
  }

  /// Get the date of the first egg log (for "All Time" analytics start)
  Future<DateTime?> getFirstEggLogDate() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT MIN(date) as first_date FROM egg_logs
    ''');

    final dateStr = result.first['first_date'] as String?;
    if (dateStr == null) return null;

    return DateTime.parse(dateStr);
  }
}

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
  Future<List<EggLog>> getEggLogsByDate(DateTime date) async {
    final db = await _db.database;

    // Normalize to start of day for comparison
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final maps = await db.query(
      'egg_logs',
      where: 'date(date) = date(?)',
      whereArgs: [dateStr],
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
    DateTime end,
  ) async {
    final db = await _db.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT date(date) as day, SUM(count) as total
      FROM egg_logs
      WHERE date >= ? AND date <= ?
      GROUP BY date(date)
      ORDER BY day ASC
      ''',
      [startStr, endStr],
    );

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
}

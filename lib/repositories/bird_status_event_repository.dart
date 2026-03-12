import '../database/database_helper.dart';
import '../models/bird_status_event.dart';

/// Repository for bird status event data access operations.
class BirdStatusEventRepository {
  final DatabaseHelper _db;

  BirdStatusEventRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  /// Insert a new event.
  Future<void> insertEvent(BirdStatusEvent event) async {
    final db = await _db.database;
    await db.insert('bird_status_events', event.toMap());
  }

  /// Delete an event by ID.
  Future<void> deleteEvent(String id) async {
    final db = await _db.database;
    await db.delete(
      'bird_status_events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all events for a specific bird, ordered by date descending.
  Future<List<BirdStatusEvent>> getEventsByBird(String birdId) async {
    final db = await _db.database;

    final maps = await db.query(
      'bird_status_events',
      where: 'bird_id = ?',
      whereArgs: [birdId],
      orderBy: 'event_date DESC',
    );

    return maps.map((map) => BirdStatusEvent.fromMap(map)).toList();
  }

  /// Get all events for a specific flock, ordered by date descending.
  Future<List<BirdStatusEvent>> getEventsByFlock(String flockId) async {
    final db = await _db.database;

    final maps = await db.query(
      'bird_status_events',
      where: 'flock_id = ?',
      whereArgs: [flockId],
      orderBy: 'event_date DESC',
    );

    return maps.map((map) => BirdStatusEvent.fromMap(map)).toList();
  }

  /// Get all events across all flocks, ordered by date descending.
  Future<List<BirdStatusEvent>> getAllEvents() async {
    final db = await _db.database;

    final maps = await db.query(
      'bird_status_events',
      orderBy: 'event_date DESC',
    );

    return maps.map((map) => BirdStatusEvent.fromMap(map)).toList();
  }

  /// Get events within a date range for a flock (or all flocks if null).
  Future<List<BirdStatusEvent>> getEventsInDateRange(
    String? flockId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;

    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final List<Map<String, dynamic>> maps;
    if (flockId != null) {
      maps = await db.query(
        'bird_status_events',
        where: 'flock_id = ? AND event_date >= ? AND event_date <= ?',
        whereArgs: [flockId, startStr, endStr],
        orderBy: 'event_date ASC',
      );
    } else {
      maps = await db.query(
        'bird_status_events',
        where: 'event_date >= ? AND event_date <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'event_date ASC',
      );
    }

    return maps.map((map) => BirdStatusEvent.fromMap(map)).toList();
  }

  /// Get the count of active birds on a specific date for a flock (or all flocks if null).
  /// This reconstructs the flock size at any point in history.
  Future<int> getActiveCountOnDate(String? flockId, DateTime date) async {
    final db = await _db.database;
    final dateStr = date.toIso8601String();

    // For each unique bird_id, find the most recent event on or before the date
    // and count those where status = 'active'
    final String query;
    final List<Object?> args;

    if (flockId != null) {
      query = '''
        SELECT COUNT(DISTINCT bird_id) as count
        FROM bird_status_events e1
        WHERE flock_id = ?
          AND event_date <= ?
          AND status = 'active'
          AND event_date = (
            SELECT MAX(event_date)
            FROM bird_status_events e2
            WHERE e2.bird_id = e1.bird_id
              AND e2.event_date <= ?
          )
      ''';
      args = [flockId, dateStr, dateStr];
    } else {
      query = '''
        SELECT COUNT(DISTINCT bird_id) as count
        FROM bird_status_events e1
        WHERE event_date <= ?
          AND status = 'active'
          AND event_date = (
            SELECT MAX(event_date)
            FROM bird_status_events e2
            WHERE e2.bird_id = e1.bird_id
              AND e2.event_date <= ?
          )
      ''';
      args = [dateStr, dateStr];
    }

    final result = await db.rawQuery(query, args);
    return result.first['count'] as int? ?? 0;
  }

  /// Get active bird counts for multiple dates in a single pass.
  /// Returns a map of date -> active count. Dates should be mid-month
  /// or similar reference points; each is queried as end-of-day.
  Future<Map<DateTime, int>> getActiveCountsOnDates(
    String? flockId,
    List<DateTime> dates,
  ) async {
    if (dates.isEmpty) return {};
    final db = await _db.database;
    final result = <DateTime, int>{};

    // Build a single query using UNION ALL for each date
    final parts = <String>[];
    final args = <Object?>[];

    for (final date in dates) {
      final dateStr = date.toIso8601String();
      if (flockId != null) {
        parts.add('''
          SELECT ? as query_date, COUNT(DISTINCT bird_id) as count
          FROM bird_status_events e1
          WHERE flock_id = ?
            AND event_date <= ?
            AND status = 'active'
            AND event_date = (
              SELECT MAX(event_date)
              FROM bird_status_events e2
              WHERE e2.bird_id = e1.bird_id
                AND e2.event_date <= ?
            )
        ''');
        args.addAll([dateStr, flockId, dateStr, dateStr]);
      } else {
        parts.add('''
          SELECT ? as query_date, COUNT(DISTINCT bird_id) as count
          FROM bird_status_events e1
          WHERE event_date <= ?
            AND status = 'active'
            AND event_date = (
              SELECT MAX(event_date)
              FROM bird_status_events e2
              WHERE e2.bird_id = e1.bird_id
                AND e2.event_date <= ?
            )
        ''');
        args.addAll([dateStr, dateStr, dateStr]);
      }
    }

    final query = parts.join(' UNION ALL ');
    final rows = await db.rawQuery(query, args);

    for (var i = 0; i < rows.length && i < dates.length; i++) {
      result[dates[i]] = rows[i]['count'] as int? ?? 0;
    }

    return result;
  }

  /// Get the flock size history - active bird count at the end of each day
  /// that had an event. Useful for charts.
  Future<List<({DateTime date, int count})>> getFlockSizeHistory(
    String? flockId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // Get all unique dates with events in the range
    final String dateQuery;
    final List<Object?> dateArgs;

    if (flockId != null) {
      dateQuery = '''
        SELECT DISTINCT date(event_date) as event_day
        FROM bird_status_events
        WHERE flock_id = ? AND event_date >= ? AND event_date <= ?
        ORDER BY event_day ASC
      ''';
      dateArgs = [flockId, startStr, endStr];
    } else {
      dateQuery = '''
        SELECT DISTINCT date(event_date) as event_day
        FROM bird_status_events
        WHERE event_date >= ? AND event_date <= ?
        ORDER BY event_day ASC
      ''';
      dateArgs = [startStr, endStr];
    }

    final dates = await db.rawQuery(dateQuery, dateArgs);

    final history = <({DateTime date, int count})>[];
    for (final row in dates) {
      final dayStr = row['event_day'] as String;
      final day = DateTime.parse(dayStr);
      // Get count at end of day
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final count = await getActiveCountOnDate(flockId, endOfDay);
      history.add((date: day, count: count));
    }

    return history;
  }
}

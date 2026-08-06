import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import 'tables.dart';

/// Singleton database helper for Flock Manager.
/// Handles database initialization, migrations, and provides access to the database.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  static const String _databaseName = 'flock_manager.db';
  static const int _databaseVersion = 6;

  /// Get the database instance, initializing if needed.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database.
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database settings (enable foreign keys).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all tables for a fresh database.
  Future<void> _onCreate(Database db, int version) async {
    for (final table in Tables.allTables) {
      await db.execute(table);
    }
  }

  /// Handle database migrations. Public so tests can exercise migrations
  /// against an in-memory database.
  @visibleForTesting
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration to version 2: Add sex and species columns to birds table
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE birds ADD COLUMN sex TEXT DEFAULT 'female'");
      await db.execute("ALTER TABLE birds ADD COLUMN species TEXT DEFAULT 'chicken'");
    }

    // Migration to version 3: Add bird_status_events table and backfill
    if (oldVersion < 3) {
      // Create the table
      await db.execute(Tables.birdStatusEvents);

      // Backfill events from existing birds
      final birds = await db.query('birds');
      final batch = db.batch();
      const uuid = Uuid();

      for (final bird in birds) {
        final birdId = bird['id'] as String;
        final flockId = bird['flock_id'] as String;
        final createdAt = bird['created_at'] as String;
        final status = bird['status'] as String;
        final statusDate = bird['status_date'] as String?;
        final statusNotes = bird['status_notes'] as String?;

        // Event 1: Bird was added (active)
        batch.insert('bird_status_events', {
          'id': uuid.v4(),
          'bird_id': birdId,
          'flock_id': flockId,
          'status': 'active',
          'event_date': createdAt,
          'notes': null,
          'created_at': createdAt,
        });

        // Event 2: If status changed from active, add another event
        if (status != 'active' && statusDate != null) {
          batch.insert('bird_status_events', {
            'id': uuid.v4(),
            'bird_id': birdId,
            'flock_id': flockId,
            'status': status,
            'event_date': statusDate,
            'notes': statusNotes,
            'created_at': statusDate,
          });
        }
      }

      await batch.commit(noResult: true);
    }

    // Migration to version 4: Add flock_id to income table
    if (oldVersion < 4) {
      final cols = await db.rawQuery('PRAGMA table_info(income)');
      final hasFlockId = cols.any((c) => c['name'] == 'flock_id');
      if (!hasFlockId) {
        await db.execute('ALTER TABLE income ADD COLUMN flock_id TEXT');
      }
    }

    // Migration to version 5: Repair medication_logs rows saved with an
    // empty id (a form bug inserted id = '' — at most one such row could
    // exist, and it blocked all later medication saves).
    if (oldVersion < 5) {
      // The UNIQUE constraint guarantees at most one such row exists.
      await db.update(
        'medication_logs',
        {'id': const Uuid().v4()},
        where: "id = ''",
      );

      // Repair bird status event timelines. Earlier import/migration code
      // could leave a non-active bird's latest event as 'active' (missing
      // terminal event, or terminal event dated before the 'active' event),
      // which made deceased/sold birds count as active in forecasts.
      const uuid = Uuid();
      final nonActiveBirds = await db.query(
        'birds',
        columns: ['id', 'flock_id', 'status', 'status_date', 'status_notes', 'created_at'],
        where: "status != 'active'",
      );
      for (final bird in nonActiveBirds) {
        final birdId = bird['id'] as String;
        final latest = await db.query(
          'bird_status_events',
          columns: ['status', 'event_date'],
          where: 'bird_id = ?',
          whereArgs: [birdId],
          orderBy: 'event_date DESC',
          limit: 1,
        );
        final latestStatus =
            latest.isEmpty ? null : latest.first['status'] as String?;
        if (latestStatus == 'active' || latestStatus == null) {
          // Insert the missing terminal event so the timeline agrees with
          // the bird's actual status. It must be the bird's LATEST event to
          // take effect, so use status_date only when it postdates the
          // current latest event; otherwise fall back to now.
          final latestDate = latest.isEmpty
              ? null
              : DateTime.parse(latest.first['event_date'] as String);
          final statusDate = bird['status_date'] as String?;
          final String eventDate;
          if (statusDate != null &&
              (latestDate == null ||
                  DateTime.parse(statusDate).isAfter(latestDate))) {
            eventDate = statusDate;
          } else {
            eventDate = DateTime.now().toIso8601String();
          }
          await db.insert('bird_status_events', {
            'id': uuid.v4(),
            'bird_id': birdId,
            'flock_id': bird['flock_id'],
            'status': bird['status'],
            'event_date': eventDate,
            'notes': bird['status_notes'],
            'created_at': eventDate,
          });
        }
      }
    }

    // Migration to version 6: gifted eggs + recipient directory.
    // Adds income.type ('sale' | 'gift') and income.recipient_id, and the
    // recipients table. Existing income rows default to 'sale'.
    if (oldVersion < 6) {
      await db.execute(Tables.recipients
          .replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
      final cols = await db.rawQuery('PRAGMA table_info(income)');
      final hasType = cols.any((c) => c['name'] == 'type');
      if (!hasType) {
        await db.execute(
            "ALTER TABLE income ADD COLUMN type TEXT NOT NULL DEFAULT 'sale'");
        await db.execute(
            'ALTER TABLE income ADD COLUMN recipient_id TEXT REFERENCES recipients(id)');
      }
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database (for testing/reset purposes).
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

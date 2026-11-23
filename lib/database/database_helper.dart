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
  static const int _databaseVersion = 8;

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

    // Migration to version 7: store bird photos by filename, not absolute
    // path. iOS can move the app container on update, which broke every
    // absolute path saved before (issue #52). PhotoStorage resolves the
    // filename against the current photo directory.
    if (oldVersion < 7 && newVersion >= 7) {
      final birds = await db.query(
        'birds',
        columns: ['id', 'photo_primary'],
        where: "photo_primary IS NOT NULL AND photo_primary != ''",
      );
      for (final bird in birds) {
        final stored = bird['photo_primary'] as String;
        final name = basename(stored);
        if (name != stored) {
          await db.update('birds', {'photo_primary': name},
              where: 'id = ?', whereArgs: [bird['id']]);
        }
      }
    }

    // Migration to version 8: a bird's first 'active' event was dated when
    // she was entered in the app, not when she joined the flock, so eggs
    // logged before that were divided by too few hens (#88). Move it back
    // to her acquired date when that's earlier and still before her next
    // status change.
    if (oldVersion < 8 && newVersion >= 8) {
      await backdateJoinedEvents(db);
    }
  }

  /// Repairs each bird's status history so it starts when she joined the
  /// flock (#88). Used by the v8 migration and after every import, since
  /// older versions wrote these events wrongly:
  ///
  /// - The first 'active' event was dated when she was entered in the app,
  ///   not when she joined: it moves back to her joined date (her acquired
  ///   date, else when she was entered).
  /// - Older imports wrote an 'active' event for every bird at import time,
  ///   after real deaths and sales: `[deceased 2022, active 2026]`. If she
  ///   isn't active now, such a late 'active' event moves back to her joined
  ///   date, or is dropped when she already has one.
  /// - A history that starts with a death or sale gets the 'active' event it
  ///   is missing, at her joined date.
  ///
  /// A hen who really came back (active now) keeps her later events.
  static Future<void> backdateJoinedEvents(DatabaseExecutor db) async {
    final birds = await db.query(
      'birds',
      columns: ['id', 'flock_id', 'status', 'acquired_date', 'created_at'],
    );
    final now = DateTime.now();
    for (final bird in birds) {
      final acquired = DateTime.tryParse(bird['acquired_date'] as String? ?? '');
      final created = DateTime.tryParse(bird['created_at'] as String? ?? '');
      final joined = acquired != null && !acquired.isAfter(now) ? acquired : created;
      if (joined == null) continue;

      final events = await db.query(
        'bird_status_events',
        columns: ['id', 'status', 'event_date'],
        where: 'bird_id = ?',
        whereArgs: [bird['id']],
        orderBy: 'event_date ASC',
      );
      if (events.isEmpty) continue;
      DateTime dateOf(Map<String, Object?> e) => DateTime.parse(e['event_date'] as String);
      Future<void> moveTo(Map<String, Object?> e, DateTime date) => db.update(
            'bird_status_events',
            {'event_date': date.toIso8601String()},
            where: 'id = ?',
            whereArgs: [e['id']],
          );

      final firstChange = events.indexWhere((e) => e['status'] != 'active');
      final hasEarlyActive = firstChange != 0; // an 'active' before any change

      if (bird['status'] != 'active' && firstChange >= 0) {
        final lastChange = events.lastIndexWhere((e) => e['status'] != 'active');
        final late = events.sublist(lastChange + 1); // all 'active'
        if (late.isNotEmpty) {
          if (!hasEarlyActive && joined.isBefore(dateOf(events[firstChange]))) {
            // [deceased 2022, active 2026] → [active <joined>, deceased 2022]
            await moveTo(late.first, joined);
            for (final e in late.skip(1)) {
              await db.delete('bird_status_events', where: 'id = ?', whereArgs: [e['id']]);
            }
            continue;
          }
          for (final e in late) {
            await db.delete('bird_status_events', where: 'id = ?', whereArgs: [e['id']]);
          }
        }
      }

      if (!hasEarlyActive) {
        // Starts with a death or sale: she was active before it.
        if (joined.isBefore(dateOf(events.first))) {
          await db.insert('bird_status_events', {
            'id': const Uuid().v4(),
            'bird_id': bird['id'],
            'flock_id': bird['flock_id'],
            'status': 'active',
            'event_date': joined.toIso8601String(),
            'notes': null,
            'created_at': now.toIso8601String(),
          });
        }
        continue;
      }

      if (joined.isBefore(dateOf(events.first))) {
        await moveTo(events.first, joined);
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

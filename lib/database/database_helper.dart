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
  static const int _databaseVersion = 3;

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
      onUpgrade: _onUpgrade,
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

  /// Handle database migrations.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
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

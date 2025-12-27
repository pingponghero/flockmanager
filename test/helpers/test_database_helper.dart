import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flock_manager/database/tables.dart';

/// A test database helper that uses in-memory SQLite via sqflite_common_ffi.
/// This allows repository tests to run without needing a real database.
class TestDatabaseHelper {
  Database? _database;

  /// Initialize the FFI database factory (call once at test setup).
  static void initializeFfi() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  /// Get or create the in-memory database.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final table in Tables.allTables) {
      await db.execute(table);
    }
  }

  /// Close and dispose of the database.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

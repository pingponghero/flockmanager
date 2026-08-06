import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flock_manager/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  /// Creates a database with the pre-v6 income schema (no type /
  /// recipient_id columns, no recipients table).
  Future<Database> createV5Database() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE flocks (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE income (
              id TEXT PRIMARY KEY,
              date TEXT NOT NULL,
              amount REAL NOT NULL,
              description TEXT,
              egg_count INTEGER,
              flock_id TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    return db;
  }

  group('migration to v6', () {
    test('adds type/recipient_id columns and recipients table', () async {
      final db = await createV5Database();
      await db.insert('income', {
        'id': 'i1',
        'date': '2026-01-15T00:00:00.000',
        'amount': 5.0,
        'egg_count': 12,
        'created_at': '2026-01-15T00:00:00.000',
      });

      await DatabaseHelper.instance.onUpgrade(db, 5, 6);

      // Existing rows default to 'sale'
      final rows = await db.query('income');
      expect(rows.single['type'], 'sale');
      expect(rows.single['recipient_id'], isNull);

      // Recipients table exists and accepts inserts
      await db.insert('recipients', {
        'id': 'r1',
        'name': 'Anna',
        'created_at': '2026-01-15T00:00:00.000',
      });

      // Gift rows can now be stored with a recipient
      await db.insert('income', {
        'id': 'i2',
        'date': '2026-02-01T00:00:00.000',
        'amount': 0.0,
        'egg_count': 10,
        'type': 'gift',
        'recipient_id': 'r1',
        'created_at': '2026-02-01T00:00:00.000',
      });
      final gifts =
          await db.query('income', where: "type = 'gift'");
      expect(gifts.length, 1);

      await db.close();
    });

    test('is idempotent when run twice', () async {
      final db = await createV5Database();

      await DatabaseHelper.instance.onUpgrade(db, 5, 6);
      await DatabaseHelper.instance.onUpgrade(db, 5, 6);

      final cols = await db.rawQuery('PRAGMA table_info(income)');
      expect(cols.where((c) => c['name'] == 'type').length, 1);

      await db.close();
    });
  });
}

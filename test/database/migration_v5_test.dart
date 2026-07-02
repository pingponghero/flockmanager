import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/database/tables.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> createV4Database() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          for (final table in Tables.allTables) {
            await db.execute(table);
          }
        },
      ),
    );
    await db.insert('flocks', {
      'id': 'f1',
      'name': 'Main Flock',
      'created_at': '2024-01-01T00:00:00.000',
    });
    return db;
  }

  group('migration to v5', () {
    test('assigns a UUID to a medication log saved with a blank id', () async {
      final db = await createV4Database();
      await db.insert('medication_logs', {
        'id': '',
        'flock_id': 'f1',
        'medication_name': 'Corid',
        'start_date': '2024-05-01T00:00:00.000',
        'created_at': '2024-05-01T00:00:00.000',
      });

      await DatabaseHelper.instance.onUpgrade(db, 4, 5);

      final rows = await db.query('medication_logs');
      expect(rows.length, 1);
      final id = rows.first['id'] as String;
      expect(id, isNotEmpty);
      expect(id.length, 36); // UUID v4

      // A new medication insert must no longer hit the UNIQUE constraint
      await db.insert('medication_logs', {
        'id': '',
        'flock_id': 'f1',
        'medication_name': 'Second Med',
        'start_date': '2024-06-01T00:00:00.000',
        'created_at': '2024-06-01T00:00:00.000',
      });
      expect((await db.query('medication_logs')).length, 2);

      await db.close();
    });

    test('adds terminal status event for deceased bird missing one', () async {
      final db = await createV4Database();
      await db.insert('birds', {
        'id': 'b1',
        'flock_id': 'f1',
        'name': 'Henrietta',
        'status': 'deceased',
        'status_date': '2025-03-10T00:00:00.000',
        'created_at': '2024-01-01T00:00:00.000',
      });
      // Only the 'active' event exists — the bug being repaired
      await db.insert('bird_status_events', {
        'id': 'ev1',
        'bird_id': 'b1',
        'flock_id': 'f1',
        'status': 'active',
        'event_date': '2024-01-01T00:00:00.000',
        'created_at': '2024-01-01T00:00:00.000',
      });

      await DatabaseHelper.instance.onUpgrade(db, 4, 5);

      final events = await db.query(
        'bird_status_events',
        where: 'bird_id = ?',
        whereArgs: ['b1'],
        orderBy: 'event_date DESC',
      );
      expect(events.length, 2);
      expect(events.first['status'], 'deceased');
      expect(events.first['event_date'], '2025-03-10T00:00:00.000');

      await db.close();
    });

    test(
        'terminal event postdates a bogus later active event '
        '(imported-history case)', () async {
      final db = await createV4Database();
      // Bird died in 2023 but was imported in 2026, so the reconstructed
      // 'active' event postdates the death date.
      await db.insert('birds', {
        'id': 'b2',
        'flock_id': 'f1',
        'name': 'Old Girl',
        'status': 'deceased',
        'status_date': '2023-06-01T00:00:00.000',
        'created_at': '2026-01-15T00:00:00.000',
      });
      await db.insert('bird_status_events', {
        'id': 'ev2',
        'bird_id': 'b2',
        'flock_id': 'f1',
        'status': 'active',
        'event_date': '2026-01-15T00:00:00.000',
        'created_at': '2026-01-15T00:00:00.000',
      });
      await db.insert('bird_status_events', {
        'id': 'ev3',
        'bird_id': 'b2',
        'flock_id': 'f1',
        'status': 'deceased',
        'event_date': '2023-06-01T00:00:00.000',
        'created_at': '2023-06-01T00:00:00.000',
      });

      await DatabaseHelper.instance.onUpgrade(db, 4, 5);

      final events = await db.query(
        'bird_status_events',
        where: 'bird_id = ?',
        whereArgs: ['b2'],
        orderBy: 'event_date DESC',
      );
      // The latest event must now be the terminal status
      expect(events.first['status'], 'deceased');

      await db.close();
    });

    test('leaves consistent birds untouched', () async {
      final db = await createV4Database();
      await db.insert('birds', {
        'id': 'b3',
        'flock_id': 'f1',
        'name': 'Sold Hen',
        'status': 'sold',
        'status_date': '2025-02-01T00:00:00.000',
        'created_at': '2024-01-01T00:00:00.000',
      });
      await db.insert('bird_status_events', {
        'id': 'ev4',
        'bird_id': 'b3',
        'flock_id': 'f1',
        'status': 'active',
        'event_date': '2024-01-01T00:00:00.000',
        'created_at': '2024-01-01T00:00:00.000',
      });
      await db.insert('bird_status_events', {
        'id': 'ev5',
        'bird_id': 'b3',
        'flock_id': 'f1',
        'status': 'sold',
        'event_date': '2025-02-01T00:00:00.000',
        'created_at': '2025-02-01T00:00:00.000',
      });

      await DatabaseHelper.instance.onUpgrade(db, 4, 5);

      final events = await db.query(
        'bird_status_events',
        where: 'bird_id = ?',
        whereArgs: ['b3'],
      );
      expect(events.length, 2); // no extra event inserted

      await db.close();
    });
  });
}

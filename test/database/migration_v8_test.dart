import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flock_manager/database/database_helper.dart';

/// #88: a bird's first 'active' event was dated when she was entered in the
/// app, not when she joined, so eggs logged earlier were divided by too few
/// hens.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> createV7Database() {
    return databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 7,
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE birds (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              acquired_date TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE bird_status_events (
              id TEXT PRIMARY KEY,
              bird_id TEXT NOT NULL,
              flock_id TEXT NOT NULL,
              status TEXT NOT NULL,
              event_date TEXT NOT NULL,
              notes TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<void> addEvent(Database db, String id, String bird, String status, String date) =>
      db.insert('bird_status_events', {
        'id': id,
        'bird_id': bird,
        'flock_id': 'f',
        'status': status,
        'event_date': date,
        'created_at': date,
      });

  Future<Map<String, String>> eventDates(Database db) async => {
        for (final r in await db.query('bird_status_events'))
          r['id'] as String: r['event_date'] as String,
      };

  test('moves the first active event back to the acquired date', () async {
    final db = await createV7Database();
    await db.insert('birds', {'id': 'a', 'name': 'Henrietta', 'acquired_date': '2024-03-01T00:00:00.000'});
    await addEvent(db, 'a1', 'a', 'active', '2025-06-10T09:30:00.000');

    await DatabaseHelper.instance.onUpgrade(db, 7, 8);

    expect((await eventDates(db))['a1'], '2024-03-01T00:00:00.000');
  });

  test('leaves birds alone when there is nothing to fix', () async {
    final db = await createV7Database();
    // No acquired date.
    await db.insert('birds', {'id': 'b', 'name': 'Ginger'});
    await addEvent(db, 'b1', 'b', 'active', '2025-06-10T00:00:00.000');
    // Acquired after she was entered.
    await db.insert('birds', {'id': 'c', 'name': 'Pepper', 'acquired_date': '2025-08-01T00:00:00.000'});
    await addEvent(db, 'c1', 'c', 'active', '2025-06-10T00:00:00.000');
    // First event isn't 'active' (history starts with a status change).
    await db.insert('birds', {'id': 'd', 'name': 'Olive', 'acquired_date': '2024-01-01T00:00:00.000'});
    await addEvent(db, 'd1', 'd', 'sold', '2025-06-10T00:00:00.000');

    await DatabaseHelper.instance.onUpgrade(db, 7, 8);

    expect(await eventDates(db), {
      'b1': '2025-06-10T00:00:00.000',
      'c1': '2025-06-10T00:00:00.000',
      'd1': '2025-06-10T00:00:00.000',
    });
  });

  test('keeps later status changes where they are', () async {
    final db = await createV7Database();
    await db.insert('birds', {'id': 'e', 'name': 'Hazel', 'acquired_date': '2024-03-01T00:00:00.000'});
    await addEvent(db, 'e1', 'e', 'active', '2025-06-10T00:00:00.000');
    await addEvent(db, 'e2', 'e', 'deceased', '2025-09-01T00:00:00.000');

    await DatabaseHelper.instance.onUpgrade(db, 7, 8);

    expect(await eventDates(db), {
      'e1': '2024-03-01T00:00:00.000',
      'e2': '2025-09-01T00:00:00.000',
    });
  });
}

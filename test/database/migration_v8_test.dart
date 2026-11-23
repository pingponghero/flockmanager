import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flock_manager/database/database_helper.dart';

/// #88: bird status histories written wrongly by older versions are repaired
/// so each bird's history starts when she joined the flock.
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
              flock_id TEXT NOT NULL,
              name TEXT NOT NULL,
              status TEXT DEFAULT 'active',
              acquired_date TEXT,
              created_at TEXT NOT NULL
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

  Future<void> addBird(Database db, String id, {String? acquired, String status = 'active', String created = '2025-06-10T09:00:00.000'}) =>
      db.insert('birds', {
        'id': id,
        'flock_id': 'f',
        'name': id,
        'status': status,
        'acquired_date': acquired,
        'created_at': created,
      });

  Future<void> addEvent(Database db, String id, String bird, String status, String date) =>
      db.insert('bird_status_events', {
        'id': id,
        'bird_id': bird,
        'flock_id': 'f',
        'status': status,
        'event_date': date,
        'created_at': date,
      });

  /// Each bird's history as `status@yyyy-mm-dd`, oldest first.
  Future<Map<String, List<String>>> history(Database db) async {
    final out = <String, List<String>>{};
    for (final r in await db.query('bird_status_events', orderBy: 'event_date ASC')) {
      out.putIfAbsent(r['bird_id'] as String, () => [])
          .add('${r['status']}@${(r['event_date'] as String).substring(0, 10)}');
    }
    return out;
  }

  test('moves the first active event back to the acquired date', () async {
    final db = await createV7Database();
    await addBird(db, 'a', acquired: '2024-03-01T00:00:00.000');
    await addEvent(db, 'a1', 'a', 'active', '2025-06-10T09:30:00.000');

    await DatabaseHelper.instance.onUpgrade(db, 7, 8);

    expect(await history(db), {'a': ['active@2024-03-01']});
  });

  test('leaves correct histories alone', () async {
    final db = await createV7Database();
    // No acquired date, entered the day she arrived.
    await addBird(db, 'b', created: '2025-06-10T00:00:00.000');
    await addEvent(db, 'b1', 'b', 'active', '2025-06-10T00:00:00.000');
    // Acquired after she was entered.
    await addBird(db, 'c', acquired: '2025-08-01T00:00:00.000');
    await addEvent(db, 'c1', 'c', 'active', '2025-06-10T00:00:00.000');

    await DatabaseHelper.instance.onUpgrade(db, 7, 8);

    expect(await history(db), {
      'b': ['active@2025-06-10'],
      'c': ['active@2025-06-10'],
    });
  });

  test('keeps later status changes where they are', () async {
    final db = await createV7Database();
    await addBird(db, 'e', acquired: '2024-03-01T00:00:00.000', status: 'deceased');
    await addEvent(db, 'e1', 'e', 'active', '2025-06-10T00:00:00.000');
    await addEvent(db, 'e2', 'e', 'deceased', '2025-09-01T00:00:00.000');

    await DatabaseHelper.instance.onUpgrade(db, 7, 8);

    expect(await history(db), {'e': ['active@2024-03-01', 'deceased@2025-09-01']});
  });

  group('histories written by older imports (seen in a real export)', () {
    test('an active event after her death moves back to when she joined', () async {
      final db = await createV7Database();
      await addBird(db, 'g', acquired: '2020-06-01T00:00:00.000', status: 'deceased');
      await addEvent(db, 'g1', 'g', 'deceased', '2022-05-01T00:00:00.000');
      await addEvent(db, 'g2', 'g', 'active', '2026-05-23T00:00:00.000');

      await DatabaseHelper.instance.onUpgrade(db, 7, 8);

      expect(await history(db), {'g': ['active@2020-06-01', 'deceased@2022-05-01']});
    });

    test('a spurious late active event is dropped when she already joined', () async {
      final db = await createV7Database();
      await addBird(db, 'h', acquired: '2020-06-01T00:00:00.000', status: 'sold');
      await addEvent(db, 'h1', 'h', 'active', '2020-06-01T00:00:00.000');
      await addEvent(db, 'h2', 'h', 'sold', '2022-05-01T00:00:00.000');
      await addEvent(db, 'h3', 'h', 'active', '2026-05-23T00:00:00.000');

      await DatabaseHelper.instance.onUpgrade(db, 7, 8);

      expect(await history(db), {'h': ['active@2020-06-01', 'sold@2022-05-01']});
    });

    test('a history that starts with a sale gets the joining it was missing', () async {
      final db = await createV7Database();
      await addBird(db, 'i', acquired: '2020-06-01T00:00:00.000', status: 'sold');
      await addEvent(db, 'i1', 'i', 'sold', '2022-05-01T00:00:00.000');

      await DatabaseHelper.instance.onUpgrade(db, 7, 8);

      expect(await history(db), {'i': ['active@2020-06-01', 'sold@2022-05-01']});
    });

    test('a hen who really came back keeps her history', () async {
      final db = await createV7Database();
      await addBird(db, 'j', acquired: '2020-06-01T00:00:00.000');
      await addEvent(db, 'j1', 'j', 'active', '2020-06-01T00:00:00.000');
      await addEvent(db, 'j2', 'j', 'sold', '2021-01-01T00:00:00.000');
      await addEvent(db, 'j3', 'j', 'active', '2021-02-01T00:00:00.000');

      await DatabaseHelper.instance.onUpgrade(db, 7, 8);

      expect(await history(db), {
        'j': ['active@2020-06-01', 'sold@2021-01-01', 'active@2021-02-01'],
      });
    });
  });
}

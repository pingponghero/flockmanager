import 'package:flock_manager/database/tables.dart';
import 'package:flock_manager/services/import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// #88: importing a backup made before the fix brings first 'active' events
/// dated when each bird was entered; import moves them to the acquired date.
void main() {
  setUpAll(sqfliteFfiInit);

  Future<Database> openDb() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(Tables.birds);
    await db.execute(Tables.birdStatusEvents);
    return db;
  }

  Map<String, dynamic> bird(String id, {String? acquired, String status = 'active', String? statusDate}) => {
        'id': id,
        'flock_id': 'f',
        'name': id,
        'acquired_date': acquired,
        'status': status,
        'status_date': statusDate,
        'created_at': '2025-06-10T09:00:00.000',
      };

  Future<Map<String, List<String>>> eventsByBird(Database db) async {
    final out = <String, List<String>>{};
    for (final r in await db.query('bird_status_events', orderBy: 'event_date ASC')) {
      out.putIfAbsent(r['bird_id'] as String, () => []).add('${r['status']}@${r['event_date']}');
    }
    return out;
  }

  test('backups with events: the first active event moves to the acquired date', () async {
    final db = await openDb();
    final birds = [bird('a', acquired: '2024-03-01T00:00:00.000'), bird('b')];
    for (final b in birds) {
      await db.insert('birds', b);
    }
    await db.transaction((txn) => ImportService.writeBirdStatusEvents(txn, birds, [
          for (final id in ['a', 'b'])
            {
              'id': 'e-$id',
              'bird_id': id,
              'flock_id': 'f',
              'status': 'active',
              'event_date': '2025-06-10T09:00:00.000',
              'notes': null,
              'created_at': '2025-06-10T09:00:00.000',
            },
        ]));

    expect(await eventsByBird(db), {
      'a': ['active@2024-03-01T00:00:00.000'],
      'b': ['active@2025-06-10T09:00:00.000'], // no acquired date: unchanged
    });
  });

  test('backups without events: reconstructed history starts at the acquired date', () async {
    final db = await openDb();
    final birds = [
      bird('a', acquired: '2024-03-01T00:00:00.000'),
      bird('c', acquired: '2024-01-01T00:00:00.000', status: 'sold', statusDate: '2025-09-01T00:00:00.000'),
    ];
    for (final b in birds) {
      await db.insert('birds', b);
    }
    await db.transaction((txn) => ImportService.writeBirdStatusEvents(txn, birds, const []));

    expect(await eventsByBird(db), {
      'a': ['active@2024-03-01T00:00:00.000'],
      'c': ['active@2024-01-01T00:00:00.000', 'sold@2025-09-01T00:00:00.000'],
    });
  });
}

// Runs against a real customer export (kept out of git: see
// test/fixtures/README.md). Skips when the export isn't present.
//
//   flutter test test/real_data

import 'package:flock_manager/database/tables.dart';
import 'package:flock_manager/services/import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/export_fixture.dart';

const _name = 'customer_2026-06-03';

void main() {
  final skip = ExportFixture.skipUnless(_name);

  test('importing a 1.1.0 export repairs its bird histories (#88)', () async {
    // Every 'active' event in this export is dated at import time, after
    // real deaths: [deceased 2022, active 2026] for hens acquired in 2020.
    final fx = ExportFixture.load(_name);
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(db.close);
    await db.execute(Tables.birds);
    await db.execute(Tables.birdStatusEvents);
    final birds = fx.birds.map((b) => b.toMap()).toList();
    for (final b in birds) {
      await db.insert('birds', b);
    }

    await db.transaction((txn) => ImportService.writeBirdStatusEvents(
          txn,
          birds,
          fx.statusEvents.map((e) => e.toMap()).toList(),
        ));

    final rows = await db.query('bird_status_events', orderBy: 'event_date ASC');
    final byBird = <String, List<Map<String, Object?>>>{};
    for (final r in rows) {
      byBird.putIfAbsent(r['bird_id'] as String, () => []).add(r);
    }

    for (final bird in fx.birds) {
      final history = byBird[bird.id]!;
      // Every history now starts with her joining…
      expect(history.first['status'], 'active', reason: bird.id);
      // …and ends in her current status.
      final current = bird.status.name == 'active' ? 'active' : bird.status.name;
      expect(history.last['status'], current, reason: bird.id);
    }

    // The flock-size query the app uses (latest event on or before the date
    // is 'active') now finds a real flock in 2021, not ~1 hen.
    int activeOn(String date) => fx.birds.where((b) {
          final before = byBird[b.id]!.where((e) => (e['event_date'] as String).compareTo(date) <= 0);
          return before.isNotEmpty && before.last['status'] == 'active';
        }).length;
    expect(activeOn('2021-06-01T23:59:59'), inInclusiveRange(5, 20));
    expect(activeOn('2025-06-01T23:59:59'), inInclusiveRange(5, 20));
  }, skip: skip);
}

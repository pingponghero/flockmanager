import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/bird_status_event.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flutter_test/flutter_test.dart';

/// The year view rebuilds whenever eggs or birds change, so a big flock with
/// years of daily per-hen logs must stay quick (#1).
void main() {
  const hens = 50, years = 6;
  final today = DateTime(2026, 11, 22);
  final start = DateTime(today.year - years + 1);
  final birds = [
    for (var i = 0; i < hens; i++)
      Bird(id: 'h$i', flockId: 'f', name: 'Hen $i', acquiredDate: start, createdAt: start),
  ];
  // Every hen changes status twice along the way, as real flocks do.
  final events = [
    for (final b in birds) ...[
      BirdStatusEvent(id: '${b.id}a', birdId: b.id, flockId: 'f', status: 'active', eventDate: start, createdAt: start),
      BirdStatusEvent(id: '${b.id}s', birdId: b.id, flockId: 'f', status: 'sold', eventDate: DateTime(2030), createdAt: start),
    ],
  ];
  final logs = <EggLog>[
    for (var d = start; !d.isAfter(today); d = d.add(const Duration(days: 1)))
      for (final b in birds)
        if ((d.day + b.id.length) % 3 != 0)
          EggLog(id: '${b.id}${d.millisecondsSinceEpoch}', date: d, flockId: 'f', birdId: b.id, count: 1, createdAt: d),
  ];

  test('$hens hens × $years years of daily logs builds quickly', () {
    final sw = Stopwatch()..start();
    final builder = YearRingsBuilder(logs: logs, birds: birds, events: events, today: today, latitude: 39);
    final byYear = builder.build(mode: RingMode.years);
    final byHen = builder.build(mode: RingMode.hens);
    final days = builder.buildDays(today.year);
    final one = builder.buildForHen('h0');
    sw.stop();
    // ignore: avoid_print
    print('${logs.length} logs: ${sw.elapsedMilliseconds} ms');

    expect(byYear.rings.length, years);
    expect(byHen.rings.length, hens);
    expect(days.length, 365);
    expect(one.rings.length, years);
    // ~50 ms on a laptop; the limit leaves room for slow CI but catches an
    // accidental blow-up (e.g. re-scanning all logs per day).
    expect(sw.elapsedMilliseconds, lessThan(2000));
  });
}

import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/bird_status_event.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flutter_test/flutter_test.dart';

EggLog _log(DateTime date, int count, {String? birdId, String flockId = 'f1'}) =>
    EggLog(
      id: '${date.toIso8601String()}-$birdId-$count',
      date: date,
      flockId: flockId,
      birdId: birdId,
      count: count,
      createdAt: date,
    );

Bird _hen(
  String id, {
  DateTime? acquired,
  DateTime? hatch,
  BirdSex sex = BirdSex.female,
}) =>
    Bird(
      id: id,
      flockId: 'f1',
      name: id,
      acquiredDate: acquired,
      hatchDate: hatch,
      sex: sex,
      createdAt: acquired ?? DateTime(2020),
    );

BirdStatusEvent _event(String birdId, String status, DateTime date) =>
    BirdStatusEvent(
      id: '$birdId-$status-${date.toIso8601String()}',
      birdId: birdId,
      flockId: 'f1',
      status: status,
      eventDate: date,
      createdAt: date,
    );

YearRingsBuilder _builder({
  required List<EggLog> logs,
  List<Bird> birds = const [],
  List<BirdStatusEvent> events = const [],
  DateTime? today,
}) =>
    YearRingsBuilder(
      logs: logs,
      birds: birds,
      events: events,
      today: today ?? DateTime(2026, 11, 22),
      latitude: 39,
    );

void main() {
  group('day helpers', () {
    test('dayOfYear ignores DST changes', () {
      expect(dayOfYear(DateTime(2026, 1, 1)), 1);
      expect(dayOfYear(DateTime(2026, 3, 9)), 68); // day after US DST start
      expect(dayOfYear(DateTime(2024, 12, 31)), 366);
    });
  });

  group('unlogged days', () {
    test('short gaps count as zero, long gaps are unknown', () {
      // Week 1 (Jan 1–7): logged on the 1st and 4th only, a 2-day gap.
      // Then nothing until Jan 22: a 17-day gap.
      final logs = [
        _log(DateTime(2026, 1, 1), 4),
        _log(DateTime(2026, 1, 4), 2),
        _log(DateTime(2026, 1, 22), 3),
      ];
      final data = _builder(logs: logs).build(mode: RingMode.years);
      final ring = data.rings.single;

      final w0 = ring.blocks[0];
      expect(w0.state, RingBlockState.logged);
      expect(w0.eggs, 6);
      // Jan 1–4 counted (2 and 3 as zeros); Jan 5–7 start the long gap.
      expect(w0.knownDays, 4);

      expect(ring.blocks[1].state, RingBlockState.unknown); // Jan 8–14
      expect(ring.blocks[3].state, RingBlockState.logged); // Jan 22–28
    });

    test('days before the first log are empty, days after today are future', () {
      final logs = [_log(DateTime(2026, 3, 3), 2)];
      final ring = _builder(logs: logs, today: DateTime(2026, 3, 5))
          .build(mode: RingMode.years)
          .rings
          .single;
      expect(ring.blocks[0].state, RingBlockState.empty);
      expect(ring.blocks[8].state, RingBlockState.logged); // Feb 26 – Mar 4
      expect(ring.blocks[20].state, RingBlockState.future);
    });

    test('a long run up to today is unknown, not a string of zeros', () {
      final logs = [_log(DateTime(2026, 6, 1), 5)];
      final ring = _builder(logs: logs, today: DateTime(2026, 6, 30))
          .build(mode: RingMode.years)
          .rings
          .single;
      expect(ring.knownDays, 1);
      expect(ring.eggs, 5);
    });
  });

  group('years mode', () {
    test('one ring per year with logs, oldest first', () {
      final logs = [
        _log(DateTime(2024, 5, 1), 3),
        _log(DateTime(2026, 5, 1), 3),
      ];
      final data = _builder(logs: logs).build(mode: RingMode.years);
      expect(data.rings.map((r) => r.label), ['2024', '2025', '2026']);
      expect(data.availableYears, [2024, 2025, 2026]);
    });

    test('headcount follows status events and laying age', () {
      final birds = [
        _hen('a'),
        _hen('b'),
        _hen('chick', hatch: DateTime(2026, 1, 1)),
        _hen('rooster', sex: BirdSex.male),
      ];
      final events = [
        _event('a', 'active', DateTime(2025, 1, 1)),
        _event('b', 'active', DateTime(2025, 1, 1)),
        _event('b', 'deceased', DateTime(2026, 7, 9)),
        _event('chick', 'active', DateTime(2026, 1, 10)),
        _event('rooster', 'active', DateTime(2025, 1, 1)),
      ];
      final logs = [
        for (var d = DateTime(2026, 1, 1);
            d.isBefore(DateTime(2026, 11, 23));
            d = d.add(const Duration(days: 1)))
          _log(d, 1),
      ];
      final data = _builder(logs: logs, birds: birds, events: events)
          .build(mode: RingMode.years);
      final ring = data.rings.single;

      expect(data.colorScale, RingColorScale.layRate);
      expect(ring.blocks[2].hens, 2); // January: a + b; chick too young
      // Chick turns 20 weeks on May 21 (week 20); b is gone from Jul 9.
      expect(ring.blocks[30].hens, 2); // late July: a + chick
      expect(ring.blocks[22].hens, 3); // early June: a + b + chick
    });

    test('falls back to eggs per day when no birds are entered', () {
      final logs = [
        _log(DateTime(2026, 1, 1), 2),
        _log(DateTime(2026, 6, 1), 8),
      ];
      final data = _builder(logs: logs).build(mode: RingMode.years);
      expect(data.colorScale, RingColorScale.eggsPerDay);
      final june = data.rings.single.blocks[21];
      expect(june.intensity, 1.0);
    });
  });

  group('hens mode', () {
    test('rings per hen in arrival order, with flock totals counted apart', () {
      final birds = [
        _hen('newer', acquired: DateTime(2025, 6, 1)),
        _hen('older', acquired: DateTime(2023, 3, 1)),
      ];
      final logs = [
        _log(DateTime(2026, 4, 1), 1, birdId: 'newer'),
        _log(DateTime(2026, 4, 1), 1, birdId: 'older'),
        _log(DateTime(2026, 4, 2), 1, birdId: 'older'),
        _log(DateTime(2026, 4, 3), 2), // flock total, no hen
      ];
      final data = _builder(logs: logs, birds: birds).build(mode: RingMode.hens);

      expect(data.rings.map((r) => r.label), ['older', 'newer']);
      expect(data.unassignedEggs, 2);
      expect(data.attributedShare, closeTo(0.6, 0.001));
      final older = data.rings.first;
      expect(older.eggs, 2);
      // Apr 1–3 counted (Apr 3 was logged, just not to her).
      expect(older.knownDays, 3);
      expect(older.layRate, closeTo(2 / 3, 0.001));
    });

    test('auto mode picks hens only when most eggs are logged to hens', () {
      final birds = [_hen('a', acquired: DateTime(2025))];
      final perHen = [_log(DateTime(2026, 4, 1), 1, birdId: 'a')];
      final flock = [_log(DateTime(2026, 4, 1), 5)];

      expect(_builder(logs: perHen, birds: birds).build().mode, RingMode.hens);
      expect(_builder(logs: flock, birds: birds).build().mode, RingMode.years);
    });

    test('a hen lost mid-year has no blocks after she left', () {
      final birds = [_hen('a', acquired: DateTime(2025))];
      final events = [
        _event('a', 'active', DateTime(2025, 1, 1)),
        _event('a', 'sold', DateTime(2026, 3, 1)),
      ];
      final logs = [
        _log(DateTime(2026, 1, 5), 1, birdId: 'a'),
        _log(DateTime(2026, 6, 1), 4),
      ];
      final ring = _builder(logs: logs, birds: birds, events: events)
          .build(mode: RingMode.hens)
          .rings
          .single;
      expect(ring.blocks[30].state, RingBlockState.empty);
      expect(ring.blocks[50].state, RingBlockState.empty);
    });
  });

  group('one hen\'s years', () {
    test('her quiet days count as zeros when the flock logged them', () {
      final birds = [_hen('a', acquired: DateTime(2025, 6, 1))];
      final logs = [
        for (var d = DateTime(2026, 1, 1);
            d.isBefore(DateTime(2026, 1, 29));
            d = d.add(const Duration(days: 1))) ...[
          _log(d, 1, birdId: 'other'),
          if (d.day.isEven) _log(d, 1, birdId: 'a'),
        ],
      ];
      final data = _builder(logs: logs, birds: birds).buildForHen('a');

      expect(data.rings.map((r) => r.label), ['2026']);
      expect(data.colorScale, RingColorScale.layRate);
      final w1 = data.rings.single.blocks[1]; // Jan 8–14
      expect(w1.knownDays, 7);
      expect(w1.eggs, 4); // laid on the 8th, 10th, 12th and 14th
    });
  });

  group('days (sunburst)', () {
    test('one point per day with logged, unknown and future states', () {
      final logs = [
        for (var d = DateTime(2026, 10, 1);
            !d.isAfter(DateTime(2026, 11, 22));
            d = d.add(const Duration(days: 1)))
          if (d.day != 15) _log(d, 3),
      ];
      final days = _builder(logs: logs).buildDays(2026);

      expect(days.length, 365);
      expect(days.first.state, RingBlockState.empty);
      final oct15 = days[dayOfYear(DateTime(2026, 10, 15)) - 1];
      expect(oct15.state, RingBlockState.logged); // one-day gap counts as zero
      expect(oct15.eggs, 0);
      final dec1 = days[dayOfYear(DateTime(2026, 12, 1)) - 1];
      expect(dec1.state, RingBlockState.future);
      // Shorter days than the baseline weeks, so a little under 3 a day.
      expect(dec1.expected, inInclusiveRange(2.0, 3.0));
    });

    test('the forecast prefers the same day last year', () {
      final logs = [
        _log(DateTime(2025, 12, 1), 9),
        for (var d = DateTime(2026, 11, 1);
            !d.isAfter(DateTime(2026, 11, 22));
            d = d.add(const Duration(days: 1)))
          _log(d, 2),
      ];
      final days = _builder(logs: logs).buildDays(2026);
      expect(days[dayOfYear(DateTime(2026, 12, 1)) - 1].expected, 9);
    });
  });

  group('headcount sanity', () {
    test('an acquired date earlier than the app entry counts her from then', () {
      final birds = [_hen('a', acquired: DateTime(2025, 1, 1))];
      // Entered into the app (first event) long after she joined.
      final events = [_event('a', 'active', DateTime(2026, 9, 1))];
      final logs = [
        for (var d = DateTime(2026, 3, 1);
            d.isBefore(DateTime(2026, 3, 15));
            d = d.add(const Duration(days: 1)))
          _log(d, 1),
      ];
      final ring = _builder(logs: logs, birds: birds, events: events)
          .build(mode: RingMode.years)
          .rings
          .single;
      expect(ring.blocks[9].hens, 1); // early March
      expect(ring.layRate, closeTo(1.0, 0.001));
      expect(ring.implausibleWeeks, 0);
    });

    test('more eggs than hens hides the lay rate instead of passing 100%', () {
      final birds = [_hen('a')];
      final events = [_event('a', 'active', DateTime(2026, 1, 1))];
      final logs = [
        for (var d = DateTime(2026, 3, 1);
            d.isBefore(DateTime(2026, 3, 15));
            d = d.add(const Duration(days: 1)))
          _log(d, 5),
      ];
      final data = _builder(logs: logs, birds: birds, events: events)
          .build(mode: RingMode.years);
      final ring = data.rings.single;
      expect(ring.blocks[9].layRate, isNull);
      expect(ring.layRate, isNull);
      expect(data.implausibleWeeks, greaterThan(0));
      expect(data.colorScale, RingColorScale.eggsPerDay);
    });
  });

  group('when per-hen views make sense', () {
    test('mostly flock totals hides hens mode and the hen card', () {
      final birds = [_hen('a', acquired: DateTime(2025))];
      final logs = [
        _log(DateTime(2026, 4, 1), 1, birdId: 'a'),
        _log(DateTime(2026, 4, 1), 9),
      ];
      final b = _builder(logs: logs, birds: birds);
      expect(b.build().canShowHens, isFalse);
      expect(b.buildForHen('a').henRingsMeaningful, isFalse);
    });
  });

  group('southern hemisphere', () {
    test('daylight peaks in December and bottoms out in June', () {
      final data = YearRingsBuilder(
        logs: [_log(DateTime(2026, 4, 1), 3)],
        birds: const [],
        events: const [],
        today: DateTime(2026, 11, 22),
        latitude: -35,
      ).build(mode: RingMode.years);
      final hours = data.weeklyDaylight;
      final longest = hours.indexOf(hours.reduce((a, b) => a > b ? a : b));
      final shortest = hours.indexOf(hours.reduce((a, b) => a < b ? a : b));
      expect(longest, anyOf(inInclusiveRange(49, 51), inInclusiveRange(0, 1)));
      expect(shortest, inInclusiveRange(23, 26));
    });
  });

  group('leap years and year boundaries', () {
    test('a leap year has 366 days, and the last week absorbs the extras', () {
      final logs = [
        for (var d = DateTime(2024, 12, 20); d.isBefore(DateTime(2025, 1, 1)); d = d.add(const Duration(days: 1)))
          _log(d, 2),
      ];
      final b = _builder(logs: logs, today: DateTime(2025, 3, 1));
      final days = b.buildDays(2024);
      expect(days.length, 366);
      expect(days.last.date, DateTime(2024, 12, 31));
      expect(days.last.dayOfYear, 366);
      // Week 51 covers Dec 23–31 in a leap year: 9 days, all logged.
      final ring = b.build(mode: RingMode.years).rings.first;
      expect(ring.blocks[51].knownDays, 9);
      expect(ring.blocks[51].eggs, 18);
    });

    test('a long gap across New Year is blank on both sides', () {
      final logs = [_log(DateTime(2025, 12, 20), 3), _log(DateTime(2026, 1, 10), 3)];
      final rings = _builder(logs: logs, today: DateTime(2026, 2, 1)).build(mode: RingMode.years).rings;
      // Dec 21 – Jan 9 is 20 unlogged days: unknown in both years.
      expect(rings.first.blocks[50].state, RingBlockState.logged); // Dec 17–23 has Dec 20
      expect(rings.first.blocks[51].state, RingBlockState.unknown); // Dec 24–31
      expect(rings.last.blocks[0].state, RingBlockState.unknown);
      expect(rings.last.blocks[1].state, RingBlockState.logged); // Jan 8–14 includes Jan 10
    });

    test('forecasting Feb 29 from a year without one does not fail', () {
      // 2027 has no Feb 29; "same day last year" falls back to Mar 1.
      final logs = [
        _log(DateTime(2027, 3, 1), 7),
        for (var d = DateTime(2028, 1, 1); d.isBefore(DateTime(2028, 2, 1)); d = d.add(const Duration(days: 1)))
          _log(d, 2),
      ];
      final days = _builder(logs: logs, today: DateTime(2028, 1, 31)).buildDays(2028);
      final feb29 = days[dayOfYear(DateTime(2028, 2, 29)) - 1];
      expect(feb29.date, DateTime(2028, 2, 29));
      expect(feb29.state, RingBlockState.future);
      expect(feb29.expected, isNotNull);
    });
  });
}

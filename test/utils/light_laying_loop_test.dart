import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/utils/daylight_calculator.dart';
import 'package:flock_manager/utils/light_laying_loop.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ten hens at 39°N that lay more on lengthening days than shortening ones.
YearRingsData _year({required DateTime until, int latitude = 39}) {
  final birds = [
    for (var i = 0; i < 10; i++)
      Bird(id: 'h$i', flockId: 'f', name: 'h$i', createdAt: DateTime(2025)),
  ];
  final logs = <EggLog>[];
  for (var d = DateTime(2026, 1, 1); !d.isAfter(until); d = d.add(const Duration(days: 1))) {
    final doy = dayOfYear(d);
    final h = DaylightCalculator.calculateDaylightHours(doy, latitude);
    final next = DaylightCalculator.calculateDaylightHours(doy + 1, latitude);
    final t = ((h - 9.3) / 5.4).clamp(0.0, 1.0);
    final rate = 0.1 + 0.65 * t + (next > h ? 0.12 : -0.12);
    logs.add(EggLog(
      id: '$d',
      date: d,
      flockId: 'f',
      count: (rate.clamp(0.0, 1.0) * 10).round(),
      createdAt: d,
    ));
  }
  return YearRingsBuilder(
    logs: logs,
    birds: birds,
    events: const [],
    today: until,
    latitude: latitude,
  ).build(mode: RingMode.years);
}

void main() {
  test('spring beats autumn at the same daylight', () {
    final data = _year(until: DateTime(2026, 12, 31));
    final loop = buildLightLayingLoop(data.rings.single, data.weeklyDaylight)!;

    expect(loop.points.length, greaterThanOrEqualTo(50));
    final pair = loop.sameLight!;
    expect(pair.rising.week, inInclusiveRange(8, 16)); // March–April
    expect(pair.falling.week, inInclusiveRange(34, 42)); // September–October
    expect((pair.rising.daylight - pair.falling.daylight).abs(), lessThan(0.6));
    expect(pair.rising.layRate, greaterThan(pair.falling.layRate));
  });

  test('no loop with too few weeks', () {
    final data = _year(until: DateTime(2026, 3, 1));
    expect(buildLightLayingLoop(data.rings.single, data.weeklyDaylight), isNull);
  });

  test('no spring/autumn comparison before autumn has happened', () {
    final data = _year(until: DateTime(2026, 7, 31));
    final loop = buildLightLayingLoop(data.rings.single, data.weeklyDaylight)!;
    expect(loop.sameLight, isNull);
  });
}

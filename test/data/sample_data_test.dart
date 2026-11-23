import 'package:flock_manager/data/test_data.dart';
import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/bird_status_event.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/utils/light_laying_loop.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flutter_test/flutter_test.dart';

/// The debug "load sample data" set is used for demos and store screenshots,
/// so it should hold together the way real data does (#1).
void main() {
  final builder = YearRingsBuilder(
    logs: TestData.eggLogs.map(EggLog.fromMap).toList(),
    birds: TestData.birds.map(Bird.fromMap).toList(),
    events: TestData.birdStatusEvents.map(BirdStatusEvent.fromMap).toList(),
    today: DateTime.now(),
    latitude: 39,
  );

  test('never logs more eggs than there are laying-age hens', () {
    final data = builder.build(mode: RingMode.years);
    expect(data.implausibleWeeks, 0);
    expect(data.colorScale, RingColorScale.layRate);
    for (final ring in data.rings) {
      if (ring.layRate != null) expect(ring.layRate, inInclusiveRange(0.3, 0.85));
    }
  });

  test('spring lays ahead of autumn at the same daylight', () {
    final data = builder.build(mode: RingMode.years);
    // Use whichever year ring has enough weeks for a loop.
    final loops = data.rings
        .map((r) => buildLightLayingLoop(r, data.weeklyDaylight))
        .whereType<LightLayingLoop>()
        .where((l) => l.sameLight != null)
        .toList();
    if (loops.isEmpty) return; // too early in the year for both seasons
    final pair = loops.last.sameLight!;
    expect(pair.rising.layRate, greaterThan(pair.falling.layRate));
  });

  test('lays most in summer, least in winter', () {
    final ring = builder.build(mode: RingMode.years).rings.last;
    double? rateNear(int week) => ring.blocks[week].layRate;
    final june = rateNear(24), december = rateNear(50) ?? rateNear(2);
    if (june == null || december == null) return;
    expect(june, greaterThan(december));
  });
}

import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/bird_status_event.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/providers/bird_provider.dart';
import 'package:flock_manager/providers/bird_status_event_provider.dart';
import 'package:flock_manager/providers/egg_provider.dart';
import 'package:flock_manager/providers/flock_provider.dart';
import 'package:flock_manager/providers/forecast_provider.dart';
import 'package:flock_manager/providers/year_rings_provider.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The year view follows the Stats flock filter (#1); a hen's own rings don't.
class _Flock extends SelectedFlockNotifier {
  _Flock(this.id);
  final String? id;
  @override
  String? build() => id;
}

class _Logs extends EggLogsNotifier {
  _Logs(this.logs);
  final List<EggLog> logs;
  @override
  Future<List<EggLog>> build() async => logs;
}

class _Birds extends BirdsNotifier {
  _Birds(this.birds);
  final List<Bird> birds;
  @override
  Future<List<Bird>> build() async => birds;
}

class _Latitude extends UserLatitudeNotifier {
  @override
  Future<int> build() async => 39;
}

void main() {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));

  EggLog log(String flock, int count, {String? bird}) => EggLog(
        id: '$flock-$bird-$count',
        date: day,
        flockId: flock,
        birdId: bird,
        count: count,
        createdAt: day,
      );

  final birds = [
    Bird(id: 'a1', flockId: 'A', name: 'Pearl', acquiredDate: DateTime(now.year - 1), createdAt: DateTime(now.year - 1)),
    Bird(id: 'b1', flockId: 'B', name: 'Dot', acquiredDate: DateTime(now.year - 1), createdAt: DateTime(now.year - 1)),
  ];
  final logs = [log('A', 3), log('B', 5), log('A', 1, bird: 'a1')];
  final events = [
    for (final b in birds)
      BirdStatusEvent(
        id: 'e-${b.id}',
        birdId: b.id,
        flockId: b.flockId,
        status: 'active',
        eventDate: DateTime(now.year - 1),
        createdAt: DateTime(now.year - 1),
      ),
  ];

  ProviderContainer containerFor(String? flock) {
    final c = ProviderContainer(overrides: [
      selectedFlockIdProvider.overrideWith(() => _Flock(flock)),
      eggLogsProvider.overrideWith(() => _Logs(logs)),
      birdsProvider.overrideWith(() => _Birds(birds)),
      userLatitudeProvider.overrideWith(_Latitude.new),
      // The real provider filters events by the selected flock itself.
      birdStatusEventsProvider.overrideWith((ref) async => flock == null
          ? events
          : events.where((e) => e.flockId == flock).toList()),
      allBirdStatusEventsProvider.overrideWith((ref) async => events),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  int eggsIn(YearRingsData data) => data.rings.fold(0, (s, r) => s + r.eggs);

  test('all flocks counts every flock’s eggs', () async {
    final data = await containerFor(null)
        .read(yearRingsProvider((mode: RingMode.years, year: null)).future);
    expect(eggsIn(data), 9);
  });

  test('one flock counts only its eggs and hens', () async {
    final data = await containerFor('B')
        .read(yearRingsProvider((mode: RingMode.years, year: null)).future);
    expect(eggsIn(data), 5);
    expect(data.maxHens, 1); // Dot only
  });

  test('a hen’s own rings ignore the flock filter', () async {
    // Filter on flock B; Pearl lives in flock A.
    final data = await containerFor('B').read(henYearRingsProvider('a1').future);
    expect(data.rings.single.eggs, 1);
  });
}

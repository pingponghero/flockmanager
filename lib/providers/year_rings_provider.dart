import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/year_rings.dart';
import 'bird_provider.dart';
import 'bird_status_event_provider.dart';
import 'egg_provider.dart';
import 'flock_provider.dart';
import 'forecast_provider.dart';

/// Which rings to draw. A null [mode] lets the data decide (hens when most
/// of the year's eggs were logged to hens, otherwise years); a null [year]
/// means the current year.
typedef YearRingsQuery = ({RingMode? mode, int? year});

/// A builder over the selected flock's logs, birds and status events.
Future<YearRingsBuilder> _selectedFlockBuilder(Ref ref) async {
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final logs = await ref.watch(eggLogsProvider.future);
  final birds = await ref.watch(birdsProvider.future);
  final events = await ref.watch(birdStatusEventsProvider.future);
  final latitude = await ref.watch(userLatitudeProvider.future);

  return YearRingsBuilder(
    logs: selectedFlockId == null
        ? logs
        : logs.where((l) => l.flockId == selectedFlockId).toList(),
    birds: selectedFlockId == null
        ? birds
        : birds.where((b) => b.flockId == selectedFlockId).toList(),
    events: events,
    today: DateTime.now(),
    latitude: latitude,
  );
}

/// Year rings for the selected flock (#1).
///
/// Built from the same sources as the rest of the app, so it refreshes when
/// eggs, birds or the latitude setting change.
final yearRingsProvider =
    FutureProvider.family<YearRingsData, YearRingsQuery>((ref, query) async {
  final builder = await _selectedFlockBuilder(ref);
  return builder.build(mode: query.mode, year: query.year);
});

/// Every day of [year] for the sunburst (#1), for the selected flock.
final yearDaysProvider = FutureProvider.family<
    ({List<DayPoint> days, int latitude}), int>((ref, year) async {
  final builder = await _selectedFlockBuilder(ref);
  return (days: builder.buildDays(year), latitude: builder.latitude);
});

/// One hen's years as rings, for her Eggs tab (#1). Uses her flock's logs to
/// know which days were logged, so her non-laying days count as zeros.
final henYearRingsProvider =
    FutureProvider.family<YearRingsData, String>((ref, birdId) async {
  final logs = await ref.watch(eggLogsProvider.future);
  final birds = await ref.watch(birdsProvider.future);
  // All flocks' events: the Stats flock filter shouldn't hide her history.
  final events = await ref.watch(allBirdStatusEventsProvider.future);
  final latitude = await ref.watch(userLatitudeProvider.future);

  final bird = birds.where((b) => b.id == birdId).firstOrNull;
  final flockId = bird?.flockId;
  return YearRingsBuilder(
    logs: logs.where((l) => l.flockId == flockId).toList(),
    birds: birds.where((b) => b.id == birdId).toList(),
    events: events.where((e) => e.birdId == birdId).toList(),
    today: DateTime.now(),
    latitude: latitude,
  ).buildForHen(birdId);
});

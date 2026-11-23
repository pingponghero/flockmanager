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

/// Year rings for the selected flock (#1).
///
/// Built from the same sources as the rest of the app, so it refreshes when
/// eggs, birds or the latitude setting change.
final yearRingsProvider =
    FutureProvider.family<YearRingsData, YearRingsQuery>((ref, query) async {
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final logs = await ref.watch(eggLogsProvider.future);
  final birds = await ref.watch(birdsProvider.future);
  final events = await ref.watch(birdStatusEventsProvider.future);
  final latitude = await ref.watch(userLatitudeProvider.future);

  final builder = YearRingsBuilder(
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
  return builder.build(mode: query.mode, year: query.year);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bird_status_event.dart';
import '../repositories/bird_status_event_repository.dart';
import 'flock_provider.dart';

/// Repository provider
final birdStatusEventRepositoryProvider =
    Provider<BirdStatusEventRepository>((ref) {
  return BirdStatusEventRepository();
});

/// Provider for all events (respects selected flock filter)
final birdStatusEventsProvider =
    FutureProvider<List<BirdStatusEvent>>((ref) async {
  final repository = ref.read(birdStatusEventRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);

  if (selectedFlockId == null) {
    return repository.getAllEvents();
  } else {
    return repository.getEventsByFlock(selectedFlockId);
  }
});

/// Provider for all events (ignores flock filter)
final allBirdStatusEventsProvider =
    FutureProvider<List<BirdStatusEvent>>((ref) async {
  final repository = ref.read(birdStatusEventRepositoryProvider);
  return repository.getAllEvents();
});

/// Provider for events of a specific bird
final birdStatusEventsByBirdProvider =
    FutureProvider.family<List<BirdStatusEvent>, String>((ref, birdId) async {
  final repository = ref.read(birdStatusEventRepositoryProvider);
  return repository.getEventsByBird(birdId);
});

/// Provider for events of a specific flock
final birdStatusEventsByFlockProvider =
    FutureProvider.family<List<BirdStatusEvent>, String>((ref, flockId) async {
  final repository = ref.read(birdStatusEventRepositoryProvider);
  return repository.getEventsByFlock(flockId);
});

/// Provider for active bird count on a specific date
/// Parameters: (flockId, date) - flockId can be null for all flocks
final flockSizeOnDateProvider =
    FutureProvider.family<int, ({String? flockId, DateTime date})>(
        (ref, params) async {
  final repository = ref.read(birdStatusEventRepositoryProvider);
  return repository.getActiveCountOnDate(params.flockId, params.date);
});

/// Provider for flock size history within a date range
/// Useful for charts showing flock size over time
final flockSizeHistoryProvider = FutureProvider.family<
    List<({DateTime date, int count})>,
    ({String? flockId, DateTime start, DateTime end})>((ref, params) async {
  final repository = ref.read(birdStatusEventRepositoryProvider);
  return repository.getFlockSizeHistory(
    params.flockId,
    params.start,
    params.end,
  );
});

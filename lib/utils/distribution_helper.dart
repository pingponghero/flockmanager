import '../models/bird.dart';

/// Determines if egg distribution should be offered.
///
/// Distribution is offered when:
/// - A specific flock is selected (not "All Flocks")
/// - Egg count is greater than 0
/// - There are 2-10 active birds in the flock
/// - Egg count exactly matches the number of active birds
bool shouldOfferDistribution({
  required int eggCount,
  required List<Bird> activeBirds,
  required String? selectedFlockId,
}) {
  if (selectedFlockId == null) return false; // "All Flocks" mode
  if (eggCount <= 0) return false;
  if (activeBirds.length < 2) return false;
  if (activeBirds.length > 10) return false;
  if (eggCount != activeBirds.length) return false;

  return true;
}

/// Creates an even distribution map (1 egg per bird).
Map<String, int> createEvenDistribution(List<Bird> birds) {
  return {for (final bird in birds) bird.id: 1};
}

/// Furthest back (in missed days) a batch will be spread. Longer gaps are
/// more likely a real break in laying (molt, winter) than missed logging.
const maxMissedDaysToSpread = 7;

/// Returns the days a batch of eggs could be spread across, oldest first
/// and ending with [logDate], or an empty list if spreading shouldn't be
/// offered.
///
/// Spreading is offered when:
/// - The flock has been logged before ([lastLoggedDate] is on or before
///   [logDate]; a zero-count log still counts as logged)
/// - There are 1 to [maxMissedDays] days with no log between the two
/// - The batch is more than one day's plausible lay (more eggs than
///   laying hens), and enough for every day to get at least one egg
List<DateTime> missedDaysToSpread({
  required DateTime logDate,
  required DateTime? lastLoggedDate,
  required int eggCount,
  required int layingHens,
  int maxMissedDays = maxMissedDaysToSpread,
}) {
  if (lastLoggedDate == null) return const [];
  if (layingHens < 1 || eggCount <= layingHens) return const [];

  // Count calendar days in UTC so DST changes don't shift the gap.
  final end = DateTime.utc(logDate.year, logDate.month, logDate.day);
  final start = DateTime.utc(
      lastLoggedDate.year, lastLoggedDate.month, lastLoggedDate.day);
  final missed = end.difference(start).inDays - 1;
  if (missed < 1 || missed > maxMissedDays) return const [];
  if (eggCount < missed + 1) return const [];

  return [
    for (var i = missed; i >= 0; i--)
      DateTime(logDate.year, logDate.month, logDate.day - i),
  ];
}

/// Splits [eggCount] evenly across [days], oldest first. Any remainder goes
/// to the earliest days (10 over 3 days is 4, 3, 3).
Map<DateTime, int> spreadEvenly(int eggCount, List<DateTime> days) {
  final base = eggCount ~/ days.length;
  final remainder = eggCount % days.length;
  return {
    for (var i = 0; i < days.length; i++) days[i]: base + (i < remainder ? 1 : 0),
  };
}

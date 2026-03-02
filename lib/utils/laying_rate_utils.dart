import '../models/bird_status_event.dart';

/// Calculates the number of days a bird was in 'active' status within
/// [rangeStart, rangeEnd].
///
/// Walks the event timeline chronologically. Each 'active' event starts an
/// active period; any other event ends it. If the bird is still active after
/// the last event, the period extends to [rangeEnd].
///
/// Returns at least 1 to avoid division-by-zero when used as a denominator.
int calculateActiveDays(
  List<BirdStatusEvent> events,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  if (events.isEmpty) return 1;

  final sorted = [...events]
    ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

  int totalDays = 0;
  DateTime? activeFrom;

  for (final event in sorted) {
    if (event.status == 'active') {
      activeFrom = event.eventDate;
    } else if (activeFrom != null) {
      totalDays += _daysOverlap(activeFrom, event.eventDate, rangeStart, rangeEnd);
      activeFrom = null;
    }
  }

  // If still active after the last event, count until rangeEnd
  if (activeFrom != null) {
    totalDays += _daysOverlap(activeFrom, rangeEnd, rangeStart, rangeEnd);
  }

  return totalDays < 1 ? 1 : totalDays;
}

/// Returns the number of whole days that [start, end) overlaps with
/// [rangeStart, rangeEnd].
int _daysOverlap(
  DateTime start,
  DateTime end,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final clampedStart = start.isAfter(rangeStart) ? start : rangeStart;
  final clampedEnd = end.isBefore(rangeEnd) ? end : rangeEnd;
  if (clampedStart.isAfter(clampedEnd)) return 0;
  return clampedEnd.difference(clampedStart).inDays;
}

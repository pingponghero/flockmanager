import '../models/egg_log.dart';

/// Represents a group of egg logs that may have been distributed together.
class EggLogGroup {
  final DateTime date;
  final String flockId;
  final DateTime createdAt;
  final List<EggLog> logs;

  EggLogGroup({
    required this.date,
    required this.flockId,
    required this.createdAt,
    required this.logs,
  });

  /// True if this group represents a distributed set.
  /// A distributed set has multiple logs, all with non-null birdId.
  bool get isDistributed => logs.length > 1 && logs.every((log) => log.birdId != null);

  /// Total eggs in this group.
  int get totalCount => logs.fold(0, (sum, log) => sum + log.count);

  /// Display timestamp (from first log).
  DateTime get displayTime => logs.first.createdAt;

  /// The first log in the group (for single-log groups).
  EggLog get firstLog => logs.first;
}

/// Groups egg logs that were created together (distributed).
/// Logs are considered part of the same group if:
/// - Same date
/// - Same flock_id
/// - created_at within 2 seconds of each other
List<EggLogGroup> groupEggLogs(List<EggLog> logs) {
  if (logs.isEmpty) return [];

  // Sort by created_at descending
  final sorted = List<EggLog>.from(logs)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final groups = <EggLogGroup>[];
  var currentGroup = <EggLog>[sorted.first];

  for (var i = 1; i < sorted.length; i++) {
    final current = sorted[i];
    final previous = currentGroup.last;

    final sameDate = _isSameDay(current.date, previous.date);
    final sameFlock = current.flockId == previous.flockId;
    final closeTimestamp =
        previous.createdAt.difference(current.createdAt).abs() <=
            const Duration(seconds: 2);

    if (sameDate && sameFlock && closeTimestamp) {
      currentGroup.add(current);
    } else {
      // Finalize previous group
      groups.add(EggLogGroup(
        date: currentGroup.first.date,
        flockId: currentGroup.first.flockId,
        createdAt: currentGroup.first.createdAt,
        logs: List.unmodifiable(currentGroup),
      ));
      currentGroup = [current];
    }
  }

  // Don't forget the last group
  groups.add(EggLogGroup(
    date: currentGroup.first.date,
    flockId: currentGroup.first.flockId,
    createdAt: currentGroup.first.createdAt,
    logs: List.unmodifiable(currentGroup),
  ));

  return groups;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

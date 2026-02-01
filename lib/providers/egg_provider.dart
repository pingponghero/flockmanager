import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/egg_log.dart';
import '../models/enums.dart';
import '../repositories/egg_repository.dart';
import 'flock_provider.dart';
import 'notification_provider.dart';

/// Repository provider
final eggRepositoryProvider = Provider<EggRepository>((ref) {
  return EggRepository();
});

/// Async notifier for managing egg logs
class EggLogsNotifier extends AsyncNotifier<List<EggLog>> {
  @override
  Future<List<EggLog>> build() async {
    return _fetchEggLogs();
  }

  Future<List<EggLog>> _fetchEggLogs() async {
    final repository = ref.read(eggRepositoryProvider);
    return repository.getAllEggLogs();
  }

  /// Add a new egg log
  Future<void> addEggLog(EggLog log) async {
    final repository = ref.read(eggRepositoryProvider);
    await repository.insertEggLog(log);
    ref.invalidateSelf();
    // Invalidate related providers
    _invalidateEggCountProviders();
    // Reschedule egg reminder for tomorrow (eggs logged today)
    // Wrapped in try-catch to handle notification permission errors gracefully
    try {
      await ref.read(notificationSettingsProvider.notifier).onEggsLogged();
    } catch (_) {
      // Ignore notification errors - egg save should still succeed
    }
  }

  /// Add distributed egg logs (one per bird with same timestamp)
  Future<List<EggLog>> addDistributedEggLogs({
    required DateTime date,
    required String flockId,
    required Map<String, int> distribution,
    EggSize? size,
    EggQuality? quality,
    String? notes,
  }) async {
    final repository = ref.read(eggRepositoryProvider);
    final logs = await repository.insertDistributedEggLogs(
      date: date,
      flockId: flockId,
      distribution: distribution,
      size: size,
      quality: quality,
      notes: notes,
    );
    ref.invalidateSelf();
    // Invalidate related providers
    _invalidateEggCountProviders();
    // Reschedule egg reminder for tomorrow (eggs logged today)
    // Wrapped in try-catch to handle notification permission errors gracefully
    try {
      await ref.read(notificationSettingsProvider.notifier).onEggsLogged();
    } catch (_) {
      // Ignore notification errors - egg save should still succeed
    }
    return logs;
  }

  /// Update an existing egg log
  Future<void> updateEggLog(EggLog log) async {
    final repository = ref.read(eggRepositoryProvider);
    await repository.updateEggLog(log);
    ref.invalidateSelf();
    _invalidateEggCountProviders();
  }

  /// Delete an egg log
  Future<void> deleteEggLog(String id) async {
    final repository = ref.read(eggRepositoryProvider);
    await repository.deleteEggLog(id);
    ref.invalidateSelf();
    _invalidateEggCountProviders();
  }

  /// Refresh the egg logs
  Future<void> refresh() async {
    ref.invalidateSelf();
    _invalidateEggCountProviders();
  }

  void _invalidateEggCountProviders() {
    // Base providers
    ref.invalidate(todayEggCountProvider);
    ref.invalidate(weekEggCountProvider);
    ref.invalidate(monthEggCountProvider);
    ref.invalidate(totalEggCountProvider);
    // Flock-filtered providers (used by home screen)
    ref.invalidate(todayEggCountByFlockProvider);
    ref.invalidate(yesterdayEggCountByFlockProvider);
    ref.invalidate(weekEggCountByFlockProvider);
    ref.invalidate(monthEggCountByFlockProvider);
    // Activity feed and charts
    ref.invalidate(recentEggLogsProvider);
    ref.invalidate(last7DaysEggCountsProvider);
    ref.invalidate(checkInStreakProvider);
    // History screen providers (family providers - invalidates all instances)
    ref.invalidate(eggLogsByDateProvider);
    ref.invalidate(dailyEggCountsProvider);
    ref.invalidate(eggHistoryProvider);
  }
}

/// Provider for all egg logs
final eggLogsProvider =
    AsyncNotifierProvider<EggLogsNotifier, List<EggLog>>(() {
  return EggLogsNotifier();
});

/// Provider for today's egg count
final todayEggCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return repository.getEggCountByDateRange(today, today);
});

/// Provider for today's egg count filtered by selected flock
final todayEggCountByFlockProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (selectedFlockId == null) {
    return repository.getEggCountByDateRange(today, today);
  }
  return repository.getEggCountByFlockAndDateRange(selectedFlockId, today, today);
});

/// Provider for yesterday's egg count (for comparison)
final yesterdayEggCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  return repository.getEggCountByDateRange(yesterday, yesterday);
});

/// Provider for yesterday's egg count filtered by selected flock
final yesterdayEggCountByFlockProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  if (selectedFlockId == null) {
    return repository.getEggCountByDateRange(yesterday, yesterday);
  }
  return repository.getEggCountByFlockAndDateRange(selectedFlockId, yesterday, yesterday);
});

/// Provider for this week's egg count (current week, Mon-Sun or Sun-Sat)
final weekEggCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Start of week (Sunday)
  final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
  return repository.getEggCountByDateRange(startOfWeek, today);
});

/// Provider for this week's egg count filtered by selected flock
final weekEggCountByFlockProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfWeek = today.subtract(Duration(days: today.weekday % 7));

  if (selectedFlockId == null) {
    return repository.getEggCountByDateRange(startOfWeek, today);
  }
  return repository.getEggCountByFlockAndDateRange(selectedFlockId, startOfWeek, today);
});

/// Provider for this month's egg count
final monthEggCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfMonth = DateTime(now.year, now.month, 1);
  return repository.getEggCountByDateRange(startOfMonth, today);
});

/// Provider for this month's egg count filtered by selected flock
final monthEggCountByFlockProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfMonth = DateTime(now.year, now.month, 1);

  if (selectedFlockId == null) {
    return repository.getEggCountByDateRange(startOfMonth, today);
  }
  return repository.getEggCountByFlockAndDateRange(selectedFlockId, startOfMonth, today);
});

/// Provider for total egg count
final totalEggCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getTotalEggCount();
});

/// Provider for total egg count by flock
final totalEggCountByFlockProvider =
    FutureProvider.family<int, String>((ref, flockId) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getTotalEggCountByFlock(flockId);
});

/// Provider for total egg count by bird
final totalEggCountByBirdProvider =
    FutureProvider.family<int, String>((ref, birdId) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getTotalEggCountByBird(birdId);
});

/// Provider for egg logs by date
final eggLogsByDateProvider =
    FutureProvider.family<List<EggLog>, DateTime>((ref, date) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  return repository.getEggLogsByDate(date, flockId: selectedFlockId);
});

/// Provider for egg logs in a specific flock
final eggLogsByFlockProvider =
    FutureProvider.family<List<EggLog>, String>((ref, flockId) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getEggLogsByFlock(flockId);
});

/// Provider for egg logs for a specific bird
final eggLogsByBirdProvider =
    FutureProvider.family<List<EggLog>, String>((ref, birdId) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getEggLogsByBird(birdId);
});

/// Provider for a single egg log by ID
final eggLogByIdProvider =
    FutureProvider.family<EggLog?, String>((ref, id) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getEggLogById(id);
});

/// Date range parameter for history provider
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && start == other.start && end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// Provider for egg logs in a date range
final eggHistoryProvider =
    FutureProvider.family<List<EggLog>, DateRange>((ref, range) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getEggLogsByDateRange(range.start, range.end);
});

/// Provider for daily egg counts in a date range (for charts)
final dailyEggCountsProvider =
    FutureProvider.family<Map<DateTime, int>, DateRange>((ref, range) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  return repository.getDailyEggCounts(range.start, range.end, flockId: selectedFlockId);
});

/// Provider for last 7 days egg counts (for spark line)
final last7DaysEggCountsProvider =
    FutureProvider<Map<DateTime, int>>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = today.subtract(const Duration(days: 6));
  return repository.getDailyEggCounts(sevenDaysAgo, today);
});

/// Provider for 7-day rolling average (excludes today)
final weeklyAverageEggCountProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = today.subtract(const Duration(days: 7));
  final yesterday = today.subtract(const Duration(days: 1));

  // Get total eggs for the 7 days before today
  final total = selectedFlockId == null
      ? await repository.getEggCountByDateRange(sevenDaysAgo, yesterday)
      : await repository.getEggCountByFlockAndDateRange(
          selectedFlockId, sevenDaysAgo, yesterday);

  return total / 7;
});

/// Provider for the last logged flock ID (for defaults)
final lastLoggedFlockIdProvider = FutureProvider<String?>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getLastLoggedFlockId();
});

/// Provider for yesterday's egg count for a specific flock (for default value in quick log)
final yesterdayCountForFlockProvider =
    FutureProvider.family<int, String>((ref, flockId) async {
  final repository = ref.read(eggRepositoryProvider);
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  return repository.getEggCountForDateAndFlock(yesterday, flockId);
});

/// Provider for recent egg logs (for home screen activity feed)
final recentEggLogsProvider =
    FutureProvider.autoDispose<List<EggLog>>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final logs = await repository.getAllEggLogs();
  // Return the 5 most recent logs
  return logs.take(5).toList();
});

/// Provider for check-in streak (consecutive days with any egg log entry)
/// Uses the same logic as achievements - reuses repository method
final checkInStreakProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getCurrentLoggingStreak();
});

/// Provider for longest streak ever achieved
final longestStreakProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getLongestStreak();
});

/// Provider for total days with egg logs
final totalLoggedDaysProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  return repository.getDistinctLogDays();
});

// ==================== EGG DISTRIBUTION SETTINGS ====================

const _keyAutoDistributeEggs = 'auto_distribute_eggs';

/// Notifier for auto-distribute eggs setting
class AutoDistributeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoDistributeEggs) ?? false;
  }

  Future<void> setAutoDistribute(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDistributeEggs, value);
    state = AsyncData(value);
  }
}

/// Provider for auto-distribute eggs setting
final autoDistributeEggsProvider =
    AsyncNotifierProvider<AutoDistributeNotifier, bool>(() {
  return AutoDistributeNotifier();
});

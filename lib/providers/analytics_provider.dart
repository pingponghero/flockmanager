import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bird.dart';
import '../models/egg_log.dart';
import '../repositories/bird_repository.dart';
import '../repositories/egg_repository.dart';
import 'flock_provider.dart';

/// Analytics period for filtering data
enum AnalyticsPeriod {
  week,
  month,
  year,
  allTime;

  String get displayName => switch (this) {
        AnalyticsPeriod.week => 'This Week',
        AnalyticsPeriod.month => 'This Month',
        AnalyticsPeriod.year => 'This Year',
        AnalyticsPeriod.allTime => 'All Time',
      };

  DateRange get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case AnalyticsPeriod.week:
        // Start from Sunday
        final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
        return DateRange(startOfWeek, today);
      case AnalyticsPeriod.month:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateRange(startOfMonth, today);
      case AnalyticsPeriod.year:
        final startOfYear = DateTime(now.year, 1, 1);
        return DateRange(startOfYear, today);
      case AnalyticsPeriod.allTime:
        // Start from a very early date
        return DateRange(DateTime(2020, 1, 1), today);
    }
  }
}

/// Date range helper class
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  int get dayCount => end.difference(start).inDays + 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && start == other.start && end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// Bird egg statistics
class BirdEggStats {
  final Bird bird;
  final int eggCount;
  final double percentage;
  final double layingRate; // eggs per 7 days average

  const BirdEggStats({
    required this.bird,
    required this.eggCount,
    required this.percentage,
    required this.layingRate,
  });

  bool get isFreeloader => eggCount == 0;
  bool get isTopLayer => layingRate >= 5; // 5+ eggs per week is good
}

/// Daily egg count for charts
class DailyEggCount {
  final DateTime date;
  final int count;

  const DailyEggCount({required this.date, required this.count});
}

/// Analytics summary data
class AnalyticsSummary {
  final int totalEggs;
  final double dailyAverage;
  final int bestDayCount;
  final DateTime? bestDayDate;
  final int worstDayCount;
  final DateTime? worstDayDate;
  final int daysWithData;
  final int daysWithoutData;
  final double periodChange; // percentage change vs previous period
  final bool hasPreviousPeriodData; // whether comparison data exists
  final List<BirdEggStats> birdStats;
  final List<DailyEggCount> dailyCounts;

  const AnalyticsSummary({
    required this.totalEggs,
    required this.dailyAverage,
    required this.bestDayCount,
    this.bestDayDate,
    required this.worstDayCount,
    this.worstDayDate,
    required this.daysWithData,
    required this.daysWithoutData,
    required this.periodChange,
    required this.hasPreviousPeriodData,
    required this.birdStats,
    required this.dailyCounts,
  });

  // Keep for backwards compatibility
  double get weekOverWeekChange => periodChange;

  List<BirdEggStats> get topLayers =>
      birdStats.where((s) => s.isTopLayer).toList()
        ..sort((a, b) => b.eggCount.compareTo(a.eggCount));

  List<BirdEggStats> get freeloaders =>
      birdStats.where((s) => s.isFreeloader).toList();

  int get activeBirdCount => birdStats.length;
}

/// Selected analytics period notifier
class AnalyticsPeriodNotifier extends Notifier<AnalyticsPeriod> {
  @override
  AnalyticsPeriod build() => AnalyticsPeriod.week;

  void setPeriod(AnalyticsPeriod period) => state = period;
}

/// Selected analytics period provider
final analyticsPeriodProvider =
    NotifierProvider<AnalyticsPeriodNotifier, AnalyticsPeriod>(
        AnalyticsPeriodNotifier.new);

/// Repository providers
final _eggRepositoryProvider = Provider<EggRepository>((ref) {
  return EggRepository();
});

final _birdRepositoryProvider = Provider<BirdRepository>((ref) {
  return BirdRepository();
});

/// Main analytics provider
final analyticsProvider = FutureProvider<AnalyticsSummary>((ref) async {
  final period = ref.watch(analyticsPeriodProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);

  final eggRepo = ref.read(_eggRepositoryProvider);
  final birdRepo = ref.read(_birdRepositoryProvider);

  // For allTime, use actual first egg date instead of hardcoded 2020
  DateRange dateRange;
  if (period == AnalyticsPeriod.allTime) {
    final firstEggDate = await eggRepo.getFirstEggLogDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // If no eggs yet, default to today (will show empty stats)
    final start = firstEggDate != null
        ? DateTime(firstEggDate.year, firstEggDate.month, firstEggDate.day)
        : today;
    dateRange = DateRange(start, today);
  } else {
    dateRange = period.dateRange;
  }

  // Get all egg logs for the period
  List<EggLog> logs = await eggRepo.getEggLogsByDateRange(
    dateRange.start,
    dateRange.end,
  );

  // Filter by flock if selected
  if (selectedFlockId != null) {
    logs = logs.where((log) => log.flockId == selectedFlockId).toList();
  }

  // Get active hens (exclude males from egg production stats)
  List<Bird> birds;
  if (selectedFlockId != null) {
    birds = await birdRepo.getActiveBirdsByFlock(selectedFlockId);
  } else {
    birds = await birdRepo.getActiveBirds();
  }
  birds = birds.where((b) => !b.isRooster).toList();

  // Calculate total eggs
  final totalEggs = logs.fold<int>(0, (sum, log) => sum + log.count);

  // Calculate daily counts
  final dailyCountsMap = <DateTime, int>{};
  for (final log in logs) {
    final date = DateTime(log.date.year, log.date.month, log.date.day);
    dailyCountsMap[date] = (dailyCountsMap[date] ?? 0) + log.count;
  }

  // Fill in missing days with 0
  final dailyCounts = <DailyEggCount>[];
  for (var day = dateRange.start;
      !day.isAfter(dateRange.end);
      day = day.add(const Duration(days: 1))) {
    final date = DateTime(day.year, day.month, day.day);
    dailyCounts.add(DailyEggCount(
      date: date,
      count: dailyCountsMap[date] ?? 0,
    ));
  }

  // Find best and worst days
  int bestDayCount = 0;
  DateTime? bestDayDate;
  int worstDayCount = totalEggs > 0 ? dailyCounts.first.count : 0;
  DateTime? worstDayDate = dailyCounts.isNotEmpty ? dailyCounts.first.date : null;

  for (final dc in dailyCounts) {
    if (dc.count > bestDayCount) {
      bestDayCount = dc.count;
      bestDayDate = dc.date;
    }
    if (dc.count < worstDayCount || worstDayDate == null) {
      worstDayCount = dc.count;
      worstDayDate = dc.date;
    }
  }

  // Calculate days with/without data
  final daysWithData = dailyCountsMap.length;
  final daysWithoutData = dateRange.dayCount - daysWithData;

  // Calculate daily average
  final dailyAverage =
      dateRange.dayCount > 0 ? totalEggs / dateRange.dayCount : 0.0;

  // Calculate period over period change
  final periodChangeResult = await _calculatePeriodChange(
    eggRepo,
    selectedFlockId,
    period,
  );

  // Calculate per-bird stats
  final birdStats = await _calculateBirdStats(
    birds,
    logs,
    dateRange.dayCount,
  );

  return AnalyticsSummary(
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    bestDayCount: bestDayCount,
    bestDayDate: bestDayDate,
    worstDayCount: worstDayCount,
    worstDayDate: worstDayDate,
    daysWithData: daysWithData,
    daysWithoutData: daysWithoutData,
    periodChange: periodChangeResult.change,
    hasPreviousPeriodData: periodChangeResult.hasPreviousData,
    birdStats: birdStats,
    dailyCounts: dailyCounts,
  );
});

/// Result of period change calculation
class PeriodChangeResult {
  final double change;
  final bool hasPreviousData;

  const PeriodChangeResult(this.change, this.hasPreviousData);
}

Future<PeriodChangeResult> _calculatePeriodChange(
  EggRepository eggRepo,
  String? flockId,
  AnalyticsPeriod period,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  late DateTime currentStart, currentEnd, previousStart, previousEnd;

  switch (period) {
    case AnalyticsPeriod.week:
      // Current week (from Sunday)
      currentStart = today.subtract(Duration(days: today.weekday % 7));
      currentEnd = today;
      // Previous week
      previousStart = currentStart.subtract(const Duration(days: 7));
      previousEnd = currentStart.subtract(const Duration(days: 1));

    case AnalyticsPeriod.month:
      // Current month
      currentStart = DateTime(now.year, now.month, 1);
      currentEnd = today;
      // Previous month
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      previousStart = DateTime(prevYear, prevMonth, 1);
      previousEnd = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));

    case AnalyticsPeriod.year:
      // Current year
      currentStart = DateTime(now.year, 1, 1);
      currentEnd = today;
      // Previous year
      previousStart = DateTime(now.year - 1, 1, 1);
      previousEnd = DateTime(now.year, 1, 1).subtract(const Duration(days: 1));

    case AnalyticsPeriod.allTime:
      // For all time, fall back to week over week
      currentStart = today.subtract(Duration(days: today.weekday % 7));
      currentEnd = today;
      previousStart = currentStart.subtract(const Duration(days: 7));
      previousEnd = currentStart.subtract(const Duration(days: 1));
  }

  // Check if we have data in the previous period
  final firstEggDate = await eggRepo.getFirstEggLogDate();
  if (firstEggDate == null || firstEggDate.isAfter(previousEnd)) {
    // No data exists for the previous period
    return const PeriodChangeResult(0.0, false);
  }

  int currentCount;
  int previousCount;

  if (flockId != null) {
    currentCount = await eggRepo.getEggCountByFlockAndDateRange(
      flockId,
      currentStart,
      currentEnd,
    );
    previousCount = await eggRepo.getEggCountByFlockAndDateRange(
      flockId,
      previousStart,
      previousEnd,
    );
  } else {
    currentCount = await eggRepo.getEggCountByDateRange(
      currentStart,
      currentEnd,
    );
    previousCount = await eggRepo.getEggCountByDateRange(
      previousStart,
      previousEnd,
    );
  }

  if (previousCount == 0) {
    return PeriodChangeResult(currentCount > 0 ? 100.0 : 0.0, false);
  }

  final change = ((currentCount - previousCount) / previousCount) * 100;
  return PeriodChangeResult(change, true);
}

Future<List<BirdEggStats>> _calculateBirdStats(
  List<Bird> birds,
  List<EggLog> logs,
  int dayCount,
) async {
  // Count eggs per bird
  final eggsByBird = <String, int>{};
  int totalAttributedEggs = 0;

  for (final log in logs) {
    if (log.birdId != null) {
      eggsByBird[log.birdId!] = (eggsByBird[log.birdId!] ?? 0) + log.count;
      totalAttributedEggs += log.count;
    }
  }

  // Calculate stats for each bird
  final stats = <BirdEggStats>[];
  for (final bird in birds) {
    final eggCount = eggsByBird[bird.id] ?? 0;
    final percentage = totalAttributedEggs > 0
        ? (eggCount / totalAttributedEggs) * 100
        : 0.0;

    // Laying rate: eggs per 7 days
    final weeks = dayCount / 7;
    final layingRate = weeks > 0 ? eggCount / weeks : 0.0;

    stats.add(BirdEggStats(
      bird: bird,
      eggCount: eggCount,
      percentage: percentage,
      layingRate: layingRate,
    ));
  }

  // Sort by egg count descending
  stats.sort((a, b) => b.eggCount.compareTo(a.eggCount));

  return stats;
}

/// Provider for top layers only
final topLayersProvider = FutureProvider<List<BirdEggStats>>((ref) async {
  final analytics = await ref.watch(analyticsProvider.future);
  return analytics.topLayers.take(5).toList();
});

/// Provider for freeloaders only
final freeloadersProvider = FutureProvider<List<BirdEggStats>>((ref) async {
  final analytics = await ref.watch(analyticsProvider.future);
  return analytics.freeloaders;
});

/// Provider for daily egg counts (for charts)
final dailyEggCountsAnalyticsProvider =
    FutureProvider<List<DailyEggCount>>((ref) async {
  final analytics = await ref.watch(analyticsProvider.future);
  return analytics.dailyCounts;
});

/// Provider for production trend
final productionTrendProvider = FutureProvider<double>((ref) async {
  final analytics = await ref.watch(analyticsProvider.future);
  return analytics.weekOverWeekChange;
});

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
  final double weekOverWeekChange; // percentage change
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
    required this.weekOverWeekChange,
    required this.birdStats,
    required this.dailyCounts,
  });

  List<BirdEggStats> get topLayers =>
      birdStats.where((s) => s.isTopLayer).toList()
        ..sort((a, b) => b.eggCount.compareTo(a.eggCount));

  List<BirdEggStats> get freeloaders =>
      birdStats.where((s) => s.isFreeloader).toList();

  int get activeBirdCount => birdStats.length;
}

/// Selected analytics period provider
final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.week);

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

  final dateRange = period.dateRange;

  // Get all egg logs for the period
  List<EggLog> logs = await eggRepo.getEggLogsByDateRange(
    dateRange.start,
    dateRange.end,
  );

  // Filter by flock if selected
  if (selectedFlockId != null) {
    logs = logs.where((log) => log.flockId == selectedFlockId).toList();
  }

  // Get active birds
  List<Bird> birds;
  if (selectedFlockId != null) {
    birds = await birdRepo.getActiveBirdsByFlock(selectedFlockId);
  } else {
    birds = await birdRepo.getActiveBirds();
  }

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

  // Calculate week over week change
  final weekOverWeekChange = await _calculateWeekOverWeekChange(
    eggRepo,
    selectedFlockId,
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
    weekOverWeekChange: weekOverWeekChange,
    birdStats: birdStats,
    dailyCounts: dailyCounts,
  );
});

Future<double> _calculateWeekOverWeekChange(
  EggRepository eggRepo,
  String? flockId,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Current week (from Sunday)
  final startOfCurrentWeek = today.subtract(Duration(days: today.weekday % 7));
  final currentWeekEnd = today;

  // Previous week
  final startOfPreviousWeek = startOfCurrentWeek.subtract(const Duration(days: 7));
  final previousWeekEnd = startOfCurrentWeek.subtract(const Duration(days: 1));

  int currentWeekCount;
  int previousWeekCount;

  if (flockId != null) {
    currentWeekCount = await eggRepo.getEggCountByFlockAndDateRange(
      flockId,
      startOfCurrentWeek,
      currentWeekEnd,
    );
    previousWeekCount = await eggRepo.getEggCountByFlockAndDateRange(
      flockId,
      startOfPreviousWeek,
      previousWeekEnd,
    );
  } else {
    currentWeekCount = await eggRepo.getEggCountByDateRange(
      startOfCurrentWeek,
      currentWeekEnd,
    );
    previousWeekCount = await eggRepo.getEggCountByDateRange(
      startOfPreviousWeek,
      previousWeekEnd,
    );
  }

  if (previousWeekCount == 0) {
    return currentWeekCount > 0 ? 100.0 : 0.0;
  }

  return ((currentWeekCount - previousWeekCount) / previousWeekCount) * 100;
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

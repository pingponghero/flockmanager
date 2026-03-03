import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/bird.dart';
import '../models/bird_status_event.dart';
import '../models/egg_log.dart';
import '../repositories/bird_repository.dart';
import '../repositories/egg_repository.dart';
import '../utils/laying_rate_utils.dart';
import 'bird_status_event_provider.dart';
import 'flock_provider.dart';

/// Analytics period for filtering data
enum AnalyticsPeriod {
  week,
  month,
  year,
  allTime;

  String get displayName => switch (this) {
        AnalyticsPeriod.week => 'Last 7 Days',
        AnalyticsPeriod.month => 'This Month',
        AnalyticsPeriod.year => 'This Year',
        AnalyticsPeriod.allTime => 'All Time',
      };

  DateRange get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case AnalyticsPeriod.week:
        // Last 7 days (today is day 7)
        final start = today.subtract(const Duration(days: 6));
        return DateRange(start, today);
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
  final int activeDays;

  const BirdEggStats({
    required this.bird,
    required this.eggCount,
    required this.percentage,
    required this.activeDays,
  });

  bool get isFreeloader => eggCount == 0;
  double get layingRate => activeDays > 0 ? eggCount / (activeDays / 7) : 0.0;
  bool get isTopLayer => layingRate >= 5; // 5+ eggs per week is good
}

/// Daily egg count for charts
class DailyEggCount {
  final DateTime date;
  final int count;

  const DailyEggCount({required this.date, required this.count});
}

/// Granularity for chart data aggregation
enum ChartGranularity {
  daily,
  weekly,
  monthly;

  String get yAxisLabel => switch (this) {
        ChartGranularity.daily => 'eggs/day',
        ChartGranularity.weekly => 'avg eggs/day',
        ChartGranularity.monthly => 'avg eggs/day',
      };
}

/// Chart data point that can represent daily counts or period averages
class ChartDataPoint {
  final DateTime startDate;
  final DateTime endDate;
  final double value; // count for daily, average for weekly/monthly
  final int totalEggs; // total eggs in the period (for tooltip)
  final int dayCount; // number of days in the period

  const ChartDataPoint({
    required this.startDate,
    required this.endDate,
    required this.value,
    required this.totalEggs,
    required this.dayCount,
  });

  String get label {
    if (startDate == endDate) {
      return DateFormat.MMMd().format(startDate);
    }
    // For weekly/monthly, show range
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${DateFormat.MMMd().format(startDate)}-${endDate.day}';
    }
    return '${DateFormat.MMMd().format(startDate)}-${DateFormat.MMMd().format(endDate)}';
  }
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
  final DateTime? comparisonEndDate; // end date of previous period for display
  final List<BirdEggStats> birdStats;
  final List<DailyEggCount> dailyCounts;
  final List<ChartDataPoint> chartData;
  final ChartGranularity chartGranularity;

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
    this.comparisonEndDate,
    required this.birdStats,
    required this.dailyCounts,
    required this.chartData,
    required this.chartGranularity,
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
  birds = birds.where((b) => b.isEggProducer).toList();

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

  // Fetch bird status events for per-bird active day calculations
  final eventRepo = ref.read(birdStatusEventRepositoryProvider);
  final allEvents = await eventRepo.getAllEvents();

  // Calculate per-bird stats
  final birdStats = await _calculateBirdStats(
    birds,
    logs,
    dateRange,
    allEvents,
  );

  // Calculate chart data with appropriate granularity
  final (chartData, chartGranularity) = _aggregateChartData(
    dailyCounts,
    period,
    dateRange,
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
    comparisonEndDate: periodChangeResult.comparisonEndDate,
    birdStats: birdStats,
    dailyCounts: dailyCounts,
    chartData: chartData,
    chartGranularity: chartGranularity,
  );
});

/// Result of period change calculation
class PeriodChangeResult {
  final double change;
  final bool hasPreviousData;
  final DateTime? comparisonEndDate; // The end date of the previous period

  const PeriodChangeResult(this.change, this.hasPreviousData, [this.comparisonEndDate]);
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
      // Last 7 days (today is day 7)
      currentStart = today.subtract(const Duration(days: 6));
      currentEnd = today;
      // Compare to previous 7 days
      previousStart = today.subtract(const Duration(days: 13));
      previousEnd = today.subtract(const Duration(days: 7));

    case AnalyticsPeriod.month:
      // Current month (1st to today)
      currentStart = DateTime(now.year, now.month, 1);
      currentEnd = today;
      // Compare to same days last month (1st to same day of month)
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      previousStart = DateTime(prevYear, prevMonth, 1);
      // Handle months with fewer days (e.g., comparing Mar 31 to Feb)
      final daysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
      final prevDay = now.day > daysInPrevMonth ? daysInPrevMonth : now.day;
      previousEnd = DateTime(prevYear, prevMonth, prevDay);

    case AnalyticsPeriod.year:
      // Current year (Jan 1 to today)
      currentStart = DateTime(now.year, 1, 1);
      currentEnd = today;
      // Compare to same days last year (Jan 1 to same month/day)
      previousStart = DateTime(now.year - 1, 1, 1);
      // Handle leap year edge case (Feb 29)
      final prevYearDay = (now.month == 2 && now.day == 29) ? 28 : now.day;
      previousEnd = DateTime(now.year - 1, now.month, prevYearDay);

    case AnalyticsPeriod.allTime:
      // For all time, fall back to week over week with same-day comparison
      currentStart = today.subtract(Duration(days: today.weekday % 7));
      currentEnd = today;
      previousStart = currentStart.subtract(const Duration(days: 7));
      previousEnd = today.subtract(const Duration(days: 7));
  }

  // Check if we have data in the previous period
  final firstEggDate = await eggRepo.getFirstEggLogDate();
  if (firstEggDate == null || firstEggDate.isAfter(previousEnd)) {
    // No data exists for the previous period
    return const PeriodChangeResult(0.0, false, null);
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
    return PeriodChangeResult(currentCount > 0 ? 100.0 : 0.0, false, previousEnd);
  }

  final change = ((currentCount - previousCount) / previousCount) * 100;
  return PeriodChangeResult(change, true, previousEnd);
}

Future<List<BirdEggStats>> _calculateBirdStats(
  List<Bird> birds,
  List<EggLog> logs,
  DateRange dateRange,
  List<BirdStatusEvent> allEvents,
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

  // Group events by bird for active-day lookups
  final eventsByBird = <String, List<BirdStatusEvent>>{};
  for (final event in allEvents) {
    eventsByBird.putIfAbsent(event.birdId, () => []).add(event);
  }

  // Calculate stats for each bird
  final stats = <BirdEggStats>[];
  for (final bird in birds) {
    final eggCount = eggsByBird[bird.id] ?? 0;
    final percentage = totalAttributedEggs > 0
        ? (eggCount / totalAttributedEggs) * 100
        : 0.0;

    // Active days for laying rate display
    final birdEvents = eventsByBird[bird.id] ?? [];
    final activeDays = birdEvents.isNotEmpty
        ? calculateActiveDays(birdEvents, dateRange.start, dateRange.end)
        : dateRange.dayCount;

    stats.add(BirdEggStats(
      bird: bird,
      eggCount: eggCount,
      percentage: percentage,
      activeDays: activeDays,
    ));
  }

  // Sort by egg count descending
  stats.sort((a, b) => b.eggCount.compareTo(a.eggCount));

  return stats;
}

/// Aggregate daily counts into chart data with appropriate granularity
(List<ChartDataPoint>, ChartGranularity) _aggregateChartData(
  List<DailyEggCount> dailyCounts,
  AnalyticsPeriod period,
  DateRange dateRange,
) {
  if (dailyCounts.isEmpty) {
    return ([], ChartGranularity.daily);
  }

  // Determine granularity based on period and data range
  final weeksOfData = dateRange.dayCount / 7;

  ChartGranularity granularity;
  switch (period) {
    case AnalyticsPeriod.week:
    case AnalyticsPeriod.month:
      granularity = ChartGranularity.daily;
    case AnalyticsPeriod.year:
      granularity = ChartGranularity.weekly;
    case AnalyticsPeriod.allTime:
      // Weekly if under ~2 years, monthly beyond that
      granularity = weeksOfData > 104 ? ChartGranularity.monthly : ChartGranularity.weekly;
  }

  // For daily, convert directly
  if (granularity == ChartGranularity.daily) {
    return (
      dailyCounts.map((dc) => ChartDataPoint(
        startDate: dc.date,
        endDate: dc.date,
        value: dc.count.toDouble(),
        totalEggs: dc.count,
        dayCount: 1,
      )).toList(),
      granularity,
    );
  }

  // For weekly/monthly, aggregate
  final chartData = <ChartDataPoint>[];

  if (granularity == ChartGranularity.weekly) {
    // Group by ISO week (Monday-based for consistency)
    var currentWeekStart = _getWeekStart(dailyCounts.first.date);
    var weekEggs = 0;
    var weekDays = 0;
    DateTime? weekEnd;

    for (final dc in dailyCounts) {
      final dayWeekStart = _getWeekStart(dc.date);

      if (dayWeekStart != currentWeekStart) {
        // Save previous week
        if (weekDays > 0) {
          chartData.add(ChartDataPoint(
            startDate: currentWeekStart,
            endDate: weekEnd ?? currentWeekStart,
            value: weekEggs / weekDays, // average eggs per day
            totalEggs: weekEggs,
            dayCount: weekDays,
          ));
        }
        // Start new week
        currentWeekStart = dayWeekStart;
        weekEggs = 0;
        weekDays = 0;
      }

      weekEggs += dc.count;
      weekDays++;
      weekEnd = dc.date;
    }

    // Don't forget the last week
    if (weekDays > 0) {
      chartData.add(ChartDataPoint(
        startDate: currentWeekStart,
        endDate: weekEnd ?? currentWeekStart,
        value: weekEggs / weekDays,
        totalEggs: weekEggs,
        dayCount: weekDays,
      ));
    }
  } else {
    // Monthly aggregation
    var currentMonth = DateTime(dailyCounts.first.date.year, dailyCounts.first.date.month, 1);
    var monthEggs = 0;
    var monthDays = 0;
    DateTime? monthEnd;

    for (final dc in dailyCounts) {
      final dayMonth = DateTime(dc.date.year, dc.date.month, 1);

      if (dayMonth != currentMonth) {
        // Save previous month
        if (monthDays > 0) {
          chartData.add(ChartDataPoint(
            startDate: currentMonth,
            endDate: monthEnd ?? currentMonth,
            value: monthEggs / monthDays,
            totalEggs: monthEggs,
            dayCount: monthDays,
          ));
        }
        // Start new month
        currentMonth = dayMonth;
        monthEggs = 0;
        monthDays = 0;
      }

      monthEggs += dc.count;
      monthDays++;
      monthEnd = dc.date;
    }

    // Don't forget the last month
    if (monthDays > 0) {
      chartData.add(ChartDataPoint(
        startDate: currentMonth,
        endDate: monthEnd ?? currentMonth,
        value: monthEggs / monthDays,
        totalEggs: monthEggs,
        dayCount: monthDays,
      ));
    }
  }

  return (chartData, granularity);
}

/// Get the Monday of the week containing the given date
DateTime _getWeekStart(DateTime date) {
  // weekday: 1 = Monday, 7 = Sunday
  final daysFromMonday = date.weekday - 1;
  return DateTime(date.year, date.month, date.day - daysFromMonday);
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/bird_status_event_repository.dart';
import '../repositories/egg_repository.dart';
import 'analytics_provider.dart';
import 'flock_provider.dart';

/// Time scale for the golden egg chart display.
enum ChartTimeScale {
  daily, // Show individual days (week/month view)
  monthly, // Show months (year/allTime view)
}

/// Data for a single day's egg count.
class DailyEggData {
  final DateTime date;
  final int count;
  final int dayIndex; // 0-based index for chart positioning

  const DailyEggData({
    required this.date,
    required this.count,
    required this.dayIndex,
  });
}

/// Data for a week's egg count (used in weekly view).
class WeeklyEggData {
  final DateTime weekStart;
  final int totalCount;
  final double dailyAverage;
  final int daysWithData;

  const WeeklyEggData({
    required this.weekStart,
    required this.totalCount,
    required this.dailyAverage,
    required this.daysWithData,
  });
}

/// Data for a month's egg count (used in yearly view).
class MonthlyEggData {
  final int month; // 1-12
  final int year;
  final int totalCount;
  final int daysRecorded;
  final double dailyAverage;
  final bool isActual; // true if real data, false if forecast
  final double avgFlockSize; // average active bird count during the month

  const MonthlyEggData({
    required this.month,
    required this.year,
    required this.totalCount,
    required this.daysRecorded,
    required this.dailyAverage,
    required this.isActual,
    this.avgFlockSize = 0,
  });

  /// Check if this month has enough data (15+ days) to be considered complete.
  bool get isComplete => daysRecorded >= 15;
}

/// Complete chart data for golden egg visualization.
class GoldenEggChartData {
  final ChartTimeScale timeScale;
  final List<DailyEggData> dailyCounts;
  final List<WeeklyEggData> weeklyCounts;
  final List<MonthlyEggData> monthlyCounts;
  final List<MonthlyEggData> prevYearMonthlyCounts; // Previous year for ghost layer
  final int totalEggs;
  final double dailyAverage;
  final int daysOfData;
  final int maxDailyCount;
  final double allTimeDailyAverage; // For forecasting based on all historical data
  final int activeFlockSize; // Current active bird count for projecting forward

  const GoldenEggChartData({
    required this.timeScale,
    this.dailyCounts = const [],
    this.weeklyCounts = const [],
    this.monthlyCounts = const [],
    this.prevYearMonthlyCounts = const [],
    required this.totalEggs,
    required this.dailyAverage,
    required this.daysOfData,
    required this.maxDailyCount,
    this.allTimeDailyAverage = 0,
    this.activeFlockSize = 0,
  });

  /// Empty chart data for when there's no data.
  static const empty = GoldenEggChartData(
    timeScale: ChartTimeScale.daily,
    totalEggs: 0,
    dailyAverage: 0,
    daysOfData: 0,
    maxDailyCount: 0,
    allTimeDailyAverage: 0,
    activeFlockSize: 0,
  );
}

/// Repository provider for egg data access.
final eggRepositoryProvider = Provider<EggRepository>((ref) {
  return EggRepository();
});

/// Repository provider for bird status event data access.
final birdStatusEventRepositoryProvider =
    Provider<BirdStatusEventRepository>((ref) {
  return BirdStatusEventRepository();
});

/// Main chart data provider - uses the analytics period selector.
final goldenEggChartDataProvider =
    FutureProvider<GoldenEggChartData>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final statusEventRepo = ref.read(birdStatusEventRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final period = ref.watch(analyticsPeriodProvider);

  // Get all egg logs for the selected flock
  final logs = selectedFlockId != null
      ? await repository.getEggLogsByFlock(selectedFlockId)
      : await repository.getAllEggLogs();

  if (logs.isEmpty) {
    return GoldenEggChartData.empty;
  }

  // Get current active flock size
  final activeFlockSize = await statusEventRepo.getActiveCountOnDate(
    selectedFlockId,
    DateTime.now(),
  );

  // Aggregate by date
  final dailyMap = <DateTime, int>{};
  for (final log in logs) {
    final date = _dateOnly(log.date);
    dailyMap[date] = (dailyMap[date] ?? 0) + log.count;
  }

  // Calculate all-time daily average for forecasting
  final allTimeTotal = dailyMap.values.fold(0, (sum, count) => sum + count);
  final allTimeDaysWithData = dailyMap.values.where((c) => c > 0).length;
  final allTimeDailyAverage = allTimeDaysWithData > 0
      ? allTimeTotal / allTimeDaysWithData
      : 0.0;

  // Build chart data based on selected period
  switch (period) {
    case AnalyticsPeriod.week:
      return _buildWeekChartData(dailyMap, allTimeDailyAverage, activeFlockSize);
    case AnalyticsPeriod.month:
      return _buildMonthChartData(dailyMap, allTimeDailyAverage, activeFlockSize);
    case AnalyticsPeriod.year:
      return _buildYearChartData(
        dailyMap,
        allTimeDailyAverage,
        activeFlockSize,
        statusEventRepo,
        selectedFlockId,
      );
    case AnalyticsPeriod.allTime:
      return _buildAllTimeChartData(
        dailyMap,
        allTimeDailyAverage,
        activeFlockSize,
        statusEventRepo,
        selectedFlockId,
      );
  }
});

/// Build chart data for "This Week" - daily view showing 7 days.
GoldenEggChartData _buildWeekChartData(
  Map<DateTime, int> dailyMap,
  double allTimeDailyAverage,
  int activeFlockSize,
) {
  final now = DateTime.now();
  final today = _dateOnly(now);

  // Get start of current week (Sunday)
  final weekStart = today.subtract(Duration(days: today.weekday % 7));

  final dailyCounts = <DailyEggData>[];
  var totalEggs = 0;

  for (var i = 0; i < 7; i++) {
    final date = weekStart.add(Duration(days: i));
    final count = dailyMap[date] ?? 0;
    totalEggs += count;
    dailyCounts.add(DailyEggData(
      date: date,
      count: count,
      dayIndex: i,
    ));
  }

  final daysWithData = dailyCounts.where((d) => d.count > 0).length;
  final dailyAverage = daysWithData > 0 ? totalEggs / daysWithData : 0.0;
  final maxDailyCount = dailyCounts.isEmpty
      ? 0
      : dailyCounts.map((d) => d.count).reduce((a, b) => a > b ? a : b);

  return GoldenEggChartData(
    timeScale: ChartTimeScale.daily,
    dailyCounts: dailyCounts,
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: daysWithData,
    maxDailyCount: maxDailyCount,
    allTimeDailyAverage: allTimeDailyAverage,
    activeFlockSize: activeFlockSize,
  );
}

/// Build chart data for "This Month" - daily view showing days in current month.
GoldenEggChartData _buildMonthChartData(
  Map<DateTime, int> dailyMap,
  double allTimeDailyAverage,
  int activeFlockSize,
) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

  final dailyCounts = <DailyEggData>[];
  var totalEggs = 0;

  for (var i = 0; i < daysInMonth; i++) {
    final date = monthStart.add(Duration(days: i));
    final count = dailyMap[date] ?? 0;
    totalEggs += count;
    dailyCounts.add(DailyEggData(
      date: date,
      count: count,
      dayIndex: i,
    ));
  }

  final daysWithData = dailyCounts.where((d) => d.count > 0).length;
  final dailyAverage = daysWithData > 0 ? totalEggs / daysWithData : 0.0;
  final maxDailyCount = dailyCounts.isEmpty
      ? 0
      : dailyCounts.map((d) => d.count).reduce((a, b) => a > b ? a : b);

  return GoldenEggChartData(
    timeScale: ChartTimeScale.daily,
    dailyCounts: dailyCounts,
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: daysWithData,
    maxDailyCount: maxDailyCount,
    allTimeDailyAverage: allTimeDailyAverage,
    activeFlockSize: activeFlockSize,
  );
}

/// Build chart data for "This Year" - monthly view showing 12 months.
/// Also collects previous year data for ghost layer comparison.
Future<GoldenEggChartData> _buildYearChartData(
  Map<DateTime, int> dailyMap,
  double allTimeDailyAverage,
  int activeFlockSize,
  BirdStatusEventRepository statusEventRepo,
  String? flockId,
) async {
  final now = DateTime.now();
  final currentYear = now.year;
  final prevYear = currentYear - 1;

  final monthlyCounts = <MonthlyEggData>[];
  final prevYearMonthlyCounts = <MonthlyEggData>[];
  var totalEggs = 0;
  var totalDaysWithData = 0;

  for (var m = 1; m <= 12; m++) {
    // Current year data
    final daysInMonth = DateTime(currentYear, m + 1, 0).day;
    var monthTotal = 0;
    var daysRecorded = 0;

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(currentYear, m, d);
      final count = dailyMap[date];
      if (count != null) {
        monthTotal += count;
        daysRecorded++;
      }
    }

    totalEggs += monthTotal;
    totalDaysWithData += daysRecorded;

    // Calculate average flock size for this month
    final avgFlockSize = await _calculateMonthlyAvgFlockSize(
      statusEventRepo,
      flockId,
      currentYear,
      m,
      daysRecorded,
    );

    monthlyCounts.add(MonthlyEggData(
      month: m,
      year: currentYear,
      totalCount: monthTotal,
      daysRecorded: daysRecorded,
      dailyAverage: daysRecorded > 0 ? monthTotal / daysRecorded : 0,
      isActual: daysRecorded > 0,
      avgFlockSize: avgFlockSize,
    ));

    // Previous year data (for ghost layer)
    final prevDaysInMonth = DateTime(prevYear, m + 1, 0).day;
    var prevMonthTotal = 0;
    var prevDaysRecorded = 0;

    for (var d = 1; d <= prevDaysInMonth; d++) {
      final date = DateTime(prevYear, m, d);
      final count = dailyMap[date];
      if (count != null) {
        prevMonthTotal += count;
        prevDaysRecorded++;
      }
    }

    prevYearMonthlyCounts.add(MonthlyEggData(
      month: m,
      year: prevYear,
      totalCount: prevMonthTotal,
      daysRecorded: prevDaysRecorded,
      dailyAverage: prevDaysRecorded > 0 ? prevMonthTotal / prevDaysRecorded : 0,
      isActual: prevDaysRecorded > 0,
    ));
  }

  final dailyAverage = totalDaysWithData > 0 ? totalEggs / totalDaysWithData : 0.0;
  final maxMonthlyCount = monthlyCounts.isEmpty
      ? 0
      : monthlyCounts.map((m) => m.totalCount).reduce((a, b) => a > b ? a : b);

  return GoldenEggChartData(
    timeScale: ChartTimeScale.monthly,
    monthlyCounts: monthlyCounts,
    prevYearMonthlyCounts: prevYearMonthlyCounts,
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: totalDaysWithData,
    maxDailyCount: maxMonthlyCount,
    allTimeDailyAverage: allTimeDailyAverage,
    activeFlockSize: activeFlockSize,
  );
}

/// Build chart data for "All Time" - radial view with current year + previous year ghost.
/// For the radial chart, we separate current year (monthlyCounts) from previous year (prevYearMonthlyCounts).
Future<GoldenEggChartData> _buildAllTimeChartData(
  Map<DateTime, int> dailyMap,
  double allTimeDailyAverage,
  int activeFlockSize,
  BirdStatusEventRepository statusEventRepo,
  String? flockId,
) async {
  if (dailyMap.isEmpty) {
    return GoldenEggChartData.empty;
  }

  final now = DateTime.now();
  final currentYear = now.year;
  final prevYear = currentYear - 1;

  final monthlyCounts = <MonthlyEggData>[];
  final prevYearMonthlyCounts = <MonthlyEggData>[];
  var totalEggs = 0;
  var totalDaysWithData = 0;

  // Build current year data (12 months)
  for (var m = 1; m <= 12; m++) {
    final daysInMonth = DateTime(currentYear, m + 1, 0).day;
    var monthTotal = 0;
    var daysRecorded = 0;

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(currentYear, m, d);
      final count = dailyMap[date];
      if (count != null) {
        monthTotal += count;
        daysRecorded++;
      }
    }

    totalEggs += monthTotal;
    totalDaysWithData += daysRecorded;

    final avgFlockSize = await _calculateMonthlyAvgFlockSize(
      statusEventRepo,
      flockId,
      currentYear,
      m,
      daysRecorded,
    );

    monthlyCounts.add(MonthlyEggData(
      month: m,
      year: currentYear,
      totalCount: monthTotal,
      daysRecorded: daysRecorded,
      dailyAverage: daysRecorded > 0 ? monthTotal / daysRecorded : 0,
      isActual: daysRecorded > 0,
      avgFlockSize: avgFlockSize,
    ));
  }

  // Build previous year data (12 months) for ghost layer
  for (var m = 1; m <= 12; m++) {
    final daysInMonth = DateTime(prevYear, m + 1, 0).day;
    var monthTotal = 0;
    var daysRecorded = 0;

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(prevYear, m, d);
      final count = dailyMap[date];
      if (count != null) {
        monthTotal += count;
        daysRecorded++;
      }
    }

    // Add to total for all-time stats
    totalEggs += monthTotal;
    totalDaysWithData += daysRecorded;

    prevYearMonthlyCounts.add(MonthlyEggData(
      month: m,
      year: prevYear,
      totalCount: monthTotal,
      daysRecorded: daysRecorded,
      dailyAverage: daysRecorded > 0 ? monthTotal / daysRecorded : 0,
      isActual: daysRecorded > 0,
    ));
  }

  final dailyAverage = totalDaysWithData > 0 ? totalEggs / totalDaysWithData : 0.0;
  final maxMonthlyCount = monthlyCounts.isEmpty
      ? 0
      : monthlyCounts.map((m) => m.totalCount).reduce((a, b) => a > b ? a : b);

  return GoldenEggChartData(
    timeScale: ChartTimeScale.monthly,
    monthlyCounts: monthlyCounts,
    prevYearMonthlyCounts: prevYearMonthlyCounts,
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: totalDaysWithData,
    maxDailyCount: maxMonthlyCount,
    allTimeDailyAverage: allTimeDailyAverage,
    activeFlockSize: activeFlockSize,
  );
}

/// Calculate the average flock size for a given month.
/// Uses the mid-month date as a reasonable approximation.
Future<double> _calculateMonthlyAvgFlockSize(
  BirdStatusEventRepository statusEventRepo,
  String? flockId,
  int year,
  int month,
  int daysRecorded,
) async {
  if (daysRecorded == 0) return 0;

  // Use mid-month as a reasonable approximation for average flock size
  final midMonth = DateTime(year, month, 15);
  final count = await statusEventRepo.getActiveCountOnDate(flockId, midMonth);
  return count.toDouble();
}

/// Helper to strip time from DateTime.
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

// ==================== Latitude Provider ====================

const _latitudeKey = 'user_latitude';
const _defaultLatitude = 39; // Central US

/// Notifier for user latitude setting.
class UserLatitudeNotifier extends Notifier<int> {
  @override
  int build() {
    _loadLatitude();
    return _defaultLatitude;
  }

  Future<void> _loadLatitude() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getInt(_latitudeKey) ?? _defaultLatitude;
    state = latitude;
  }

  Future<void> setLatitude(int latitude) async {
    final clamped = latitude.clamp(-60, 60);
    state = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_latitudeKey, clamped);
  }
}

/// Provider for user latitude setting (-60 to 60).
final userLatitudeProvider =
    NotifierProvider<UserLatitudeNotifier, int>(UserLatitudeNotifier.new);

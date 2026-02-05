import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  const MonthlyEggData({
    required this.month,
    required this.year,
    required this.totalCount,
    required this.daysRecorded,
    required this.dailyAverage,
    required this.isActual,
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
  final int totalEggs;
  final double dailyAverage;
  final int daysOfData;
  final int maxDailyCount;

  const GoldenEggChartData({
    required this.timeScale,
    this.dailyCounts = const [],
    this.weeklyCounts = const [],
    this.monthlyCounts = const [],
    required this.totalEggs,
    required this.dailyAverage,
    required this.daysOfData,
    required this.maxDailyCount,
  });

  /// Empty chart data for when there's no data.
  static const empty = GoldenEggChartData(
    timeScale: ChartTimeScale.daily,
    totalEggs: 0,
    dailyAverage: 0,
    daysOfData: 0,
    maxDailyCount: 0,
  );
}

/// Repository provider for egg data access.
final eggRepositoryProvider = Provider<EggRepository>((ref) {
  return EggRepository();
});

/// Main chart data provider - uses the analytics period selector.
final goldenEggChartDataProvider =
    FutureProvider<GoldenEggChartData>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final period = ref.watch(analyticsPeriodProvider);

  // Get all egg logs for the selected flock
  final logs = selectedFlockId != null
      ? await repository.getEggLogsByFlock(selectedFlockId)
      : await repository.getAllEggLogs();

  if (logs.isEmpty) {
    return GoldenEggChartData.empty;
  }

  // Aggregate by date
  final dailyMap = <DateTime, int>{};
  for (final log in logs) {
    final date = _dateOnly(log.date);
    dailyMap[date] = (dailyMap[date] ?? 0) + log.count;
  }

  // Build chart data based on selected period
  switch (period) {
    case AnalyticsPeriod.week:
      return _buildWeekChartData(dailyMap);
    case AnalyticsPeriod.month:
      return _buildMonthChartData(dailyMap);
    case AnalyticsPeriod.year:
      return _buildYearChartData(dailyMap);
    case AnalyticsPeriod.allTime:
      return _buildAllTimeChartData(dailyMap);
  }
});

/// Build chart data for "This Week" - daily view showing 7 days.
GoldenEggChartData _buildWeekChartData(Map<DateTime, int> dailyMap) {
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
  );
}

/// Build chart data for "This Month" - daily view showing days in current month.
GoldenEggChartData _buildMonthChartData(Map<DateTime, int> dailyMap) {
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
  );
}

/// Build chart data for "This Year" - monthly view showing 12 months.
GoldenEggChartData _buildYearChartData(Map<DateTime, int> dailyMap) {
  final now = DateTime.now();

  final monthlyCounts = <MonthlyEggData>[];
  var totalEggs = 0;
  var totalDaysWithData = 0;

  for (var m = 1; m <= 12; m++) {
    final daysInMonth = DateTime(now.year, m + 1, 0).day;
    var monthTotal = 0;
    var daysRecorded = 0;

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(now.year, m, d);
      final count = dailyMap[date];
      if (count != null) {
        monthTotal += count;
        daysRecorded++;
      }
    }

    totalEggs += monthTotal;
    totalDaysWithData += daysRecorded;

    monthlyCounts.add(MonthlyEggData(
      month: m,
      year: now.year,
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
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: totalDaysWithData,
    maxDailyCount: maxMonthlyCount,
  );
}

/// Build chart data for "All Time" - monthly view showing all available months.
GoldenEggChartData _buildAllTimeChartData(Map<DateTime, int> dailyMap) {
  if (dailyMap.isEmpty) {
    return GoldenEggChartData.empty;
  }

  // Find date range
  final dates = dailyMap.keys.toList()..sort();
  final firstDate = dates.first;
  final lastDate = dates.last;

  final monthlyCounts = <MonthlyEggData>[];
  var totalEggs = 0;
  var totalDaysWithData = 0;

  // Iterate through all months from first to last
  var current = DateTime(firstDate.year, firstDate.month, 1);
  final end = DateTime(lastDate.year, lastDate.month + 1, 0);

  while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
    final year = current.year;
    final month = current.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    var monthTotal = 0;
    var daysRecorded = 0;

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final count = dailyMap[date];
      if (count != null) {
        monthTotal += count;
        daysRecorded++;
      }
    }

    totalEggs += monthTotal;
    totalDaysWithData += daysRecorded;

    monthlyCounts.add(MonthlyEggData(
      month: month,
      year: year,
      totalCount: monthTotal,
      daysRecorded: daysRecorded,
      dailyAverage: daysRecorded > 0 ? monthTotal / daysRecorded : 0,
      isActual: daysRecorded > 0,
    ));

    // Move to next month
    current = DateTime(year, month + 1, 1);
  }

  final dailyAverage = totalDaysWithData > 0 ? totalEggs / totalDaysWithData : 0.0;
  final maxMonthlyCount = monthlyCounts.isEmpty
      ? 0
      : monthlyCounts.map((m) => m.totalCount).reduce((a, b) => a > b ? a : b);

  return GoldenEggChartData(
    timeScale: ChartTimeScale.monthly,
    monthlyCounts: monthlyCounts,
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: totalDaysWithData,
    maxDailyCount: maxMonthlyCount,
  );
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

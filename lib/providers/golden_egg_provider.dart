import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/egg_repository.dart';
import 'flock_provider.dart';

/// Time scale for the golden egg chart based on data volume.
enum ChartTimeScale {
  daily, // Days 1-30: Individual days
  weekly, // Days 31-89: Weekly buckets
  yearly, // Days 90+: Full year with months
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

/// Provider that counts total days with egg log data.
final _daysWithEggDataProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);

  final logs = selectedFlockId != null
      ? await repository.getEggLogsByFlock(selectedFlockId)
      : await repository.getAllEggLogs();

  // Count unique dates
  final uniqueDates = logs.map((log) => _dateOnly(log.date)).toSet();
  return uniqueDates.length;
});

/// Determines which time scale to use based on data volume.
final goldenEggTimeScaleProvider = FutureProvider<ChartTimeScale>((ref) async {
  final daysOfData = await ref.watch(_daysWithEggDataProvider.future);

  if (daysOfData < 31) return ChartTimeScale.daily;
  if (daysOfData < 90) return ChartTimeScale.weekly;
  return ChartTimeScale.yearly;
});

/// Main chart data provider.
final goldenEggChartDataProvider =
    FutureProvider<GoldenEggChartData>((ref) async {
  final repository = ref.read(eggRepositoryProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final timeScale = await ref.watch(goldenEggTimeScaleProvider.future);

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

  final totalEggs = dailyMap.values.fold(0, (sum, count) => sum + count);
  final daysOfData = dailyMap.length;
  final dailyAverage = daysOfData > 0 ? totalEggs / daysOfData : 0.0;
  final maxDailyCount =
      dailyMap.values.isEmpty ? 0 : dailyMap.values.reduce((a, b) => a > b ? a : b);

  switch (timeScale) {
    case ChartTimeScale.daily:
      return _buildDailyChartData(
        dailyMap,
        totalEggs,
        dailyAverage,
        daysOfData,
        maxDailyCount,
      );
    case ChartTimeScale.weekly:
      return _buildWeeklyChartData(
        dailyMap,
        totalEggs,
        dailyAverage,
        daysOfData,
        maxDailyCount,
      );
    case ChartTimeScale.yearly:
      return _buildYearlyChartData(
        dailyMap,
        totalEggs,
        dailyAverage,
        daysOfData,
        maxDailyCount,
      );
  }
});

/// Build chart data for daily view (last 30 days).
GoldenEggChartData _buildDailyChartData(
  Map<DateTime, int> dailyMap,
  int totalEggs,
  double dailyAverage,
  int daysOfData,
  int maxDailyCount,
) {
  final now = DateTime.now();
  final today = _dateOnly(now);

  // Get last 30 days (or fewer if less data)
  final daysToShow = daysOfData.clamp(1, 30);
  final dailyCounts = <DailyEggData>[];

  for (var i = 0; i < daysToShow; i++) {
    final date = today.subtract(Duration(days: i));
    final count = dailyMap[date] ?? 0;
    dailyCounts.add(DailyEggData(
      date: date,
      count: count,
      dayIndex: i,
    ));
  }

  // Reverse so oldest is first
  dailyCounts.sort((a, b) => a.date.compareTo(b.date));
  for (var i = 0; i < dailyCounts.length; i++) {
    dailyCounts[i] = DailyEggData(
      date: dailyCounts[i].date,
      count: dailyCounts[i].count,
      dayIndex: i,
    );
  }

  return GoldenEggChartData(
    timeScale: ChartTimeScale.daily,
    dailyCounts: dailyCounts,
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: daysOfData,
    maxDailyCount: maxDailyCount,
  );
}

/// Build chart data for weekly view.
GoldenEggChartData _buildWeeklyChartData(
  Map<DateTime, int> dailyMap,
  int totalEggs,
  double dailyAverage,
  int daysOfData,
  int maxDailyCount,
) {
  // Placeholder - will be implemented later
  return GoldenEggChartData(
    timeScale: ChartTimeScale.weekly,
    weeklyCounts: [],
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: daysOfData,
    maxDailyCount: maxDailyCount,
  );
}

/// Build chart data for yearly view.
GoldenEggChartData _buildYearlyChartData(
  Map<DateTime, int> dailyMap,
  int totalEggs,
  double dailyAverage,
  int daysOfData,
  int maxDailyCount,
) {
  // Placeholder - will be implemented later
  return GoldenEggChartData(
    timeScale: ChartTimeScale.yearly,
    monthlyCounts: [],
    totalEggs: totalEggs,
    dailyAverage: dailyAverage,
    daysOfData: daysOfData,
    maxDailyCount: maxDailyCount,
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
    final clamped = latitude.clamp(20, 60);
    state = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_latitudeKey, clamped);
  }
}

/// Provider for user latitude setting (20-60°N).
final userLatitudeProvider =
    NotifierProvider<UserLatitudeNotifier, int>(UserLatitudeNotifier.new);

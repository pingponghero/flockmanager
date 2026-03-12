import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/bird_status_event_repository.dart';
import '../repositories/egg_repository.dart';
import '../utils/daylight_calculator.dart';
import 'flock_provider.dart';

// ==================== Latitude Provider ====================

const _latitudeKey = 'user_latitude';

/// Estimate latitude from UTC offset. Not precise, but a better
/// default than hardcoding — gets the right hemisphere at least.
int _defaultLatitude() {
  final h = DateTime.now().timeZoneOffset.inHours;
  if (h >= -10 && h <= -3) return 38; // Americas
  if (h >= 0 && h <= 3) return 48; // Europe / Africa
  if (h >= 4 && h <= 9) return 30; // Asia
  if (h >= 10) return -35; // Australia / NZ
  return 35;
}

class UserLatitudeNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_latitudeKey) ?? _defaultLatitude();
  }

  Future<void> setLatitude(int latitude) async {
    final clamped = latitude.clamp(-60, 60);
    state = AsyncData(clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_latitudeKey, clamped);
  }
}

final userLatitudeProvider =
    AsyncNotifierProvider<UserLatitudeNotifier, int>(UserLatitudeNotifier.new);

// ==================== Forecast Models ====================

/// Per-month forecast data.
class MonthForecast {
  final int month; // 1-12
  final int year;
  final int actualEggs;
  final int forecastEggs; // projected total for the full month
  final double perHenRate; // eggs/hen/day for this month
  final double daylightHours;
  final bool isActual; // has real data
  final bool isComplete; // month is in the past with 15+ days data
  final int daysRecorded;

  const MonthForecast({
    required this.month,
    required this.year,
    required this.actualEggs,
    required this.forecastEggs,
    required this.perHenRate,
    required this.daylightHours,
    required this.isActual,
    required this.isComplete,
    required this.daysRecorded,
  });
}

/// Complete forecast result.
class ForecastResult {
  /// Current per-hen daily rate (from recent data).
  final double currentPerHenRate;

  /// Current whole-flock daily rate.
  final double currentDailyRate;

  /// Projected eggs for the next 7 days.
  final int projectedWeek;

  /// Projected eggs for the next 30 days.
  final int projectedMonth;

  /// Projected eggs for the full current year (actual + forecast).
  final int projectedYear;

  /// Monthly breakdown with actual + forecast.
  final List<MonthForecast> monthlyForecasts;

  /// Current active hen count used for projections.
  final int activeHens;

  /// User latitude used for daylight calculations.
  final int latitude;

  /// Whether there's enough data to forecast.
  final bool hasEnoughData;

  const ForecastResult({
    required this.currentPerHenRate,
    required this.currentDailyRate,
    required this.projectedWeek,
    required this.projectedMonth,
    required this.projectedYear,
    required this.monthlyForecasts,
    required this.activeHens,
    required this.latitude,
    required this.hasEnoughData,
  });

  static final empty = ForecastResult(
    currentPerHenRate: 0,
    currentDailyRate: 0,
    projectedWeek: 0,
    projectedMonth: 0,
    projectedYear: 0,
    monthlyForecasts: [],
    activeHens: 0,
    latitude: _defaultLatitude(),
    hasEnoughData: false,
  );
}

// ==================== Forecast Provider ====================

final forecastProvider = FutureProvider<ForecastResult>((ref) async {
  final eggRepo = EggRepository();
  final statusEventRepo = BirdStatusEventRepository();
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final latitude = await ref.watch(userLatitudeProvider.future);

  // Get all egg logs
  final logs = selectedFlockId != null
      ? await eggRepo.getEggLogsByFlock(selectedFlockId)
      : await eggRepo.getAllEggLogs();

  if (logs.isEmpty) return ForecastResult.empty;

  // Get current active hen count
  final activeHens = await statusEventRepo.getActiveCountOnDate(
    selectedFlockId,
    DateTime.now(),
  );

  if (activeHens == 0) return ForecastResult.empty;

  // Aggregate daily totals
  final dailyMap = <DateTime, int>{};
  for (final log in logs) {
    final date = DateTime(log.date.year, log.date.month, log.date.day);
    dailyMap[date] = (dailyMap[date] ?? 0) + log.count;
  }

  final now = DateTime.now();
  final currentYear = now.year;
  final daylightCurve = DaylightCalculator.getMonthlyDaylightCurve(latitude);
  final daysPerMonth = _daysPerMonth(currentYear);

  // Build monthly actuals with per-hen rates
  final actualRates = <int, double>{}; // 0-indexed month -> eggs/hen/day
  final monthlyForecasts = <MonthForecast>[];

  // Pre-aggregate monthly totals and days recorded
  final monthTotals = List<int>.filled(12, 0);
  final monthDaysRecorded = List<int>.filled(12, 0);
  for (var m = 1; m <= 12; m++) {
    for (var d = 1; d <= daysPerMonth[m - 1]; d++) {
      final date = DateTime(currentYear, m, d);
      final count = dailyMap[date];
      if (count != null) {
        monthTotals[m - 1] += count;
        monthDaysRecorded[m - 1]++;
      }
    }
  }

  // Batch-fetch mid-month flock sizes for all 12 months in one query
  final midMonthDates = [
    for (var m = 1; m <= 12; m++) DateTime(currentYear, m, 15),
  ];
  final flockSizes = await statusEventRepo.getActiveCountsOnDates(
    selectedFlockId,
    midMonthDates,
  );

  for (var m = 1; m <= 12; m++) {
    final monthTotal = monthTotals[m - 1];
    final daysRecorded = monthDaysRecorded[m - 1];
    final avgFlockSize = flockSizes[midMonthDates[m - 1]] ?? 0;

    // Calculate per-hen rate if we have enough data (10+ days)
    if (daysRecorded >= 10 && monthTotal > 0 && avgFlockSize > 0) {
      final birdDays = avgFlockSize * daysRecorded;
      actualRates[m - 1] = monthTotal / birdDays;
    }

    final isComplete = m < now.month || (m == now.month && daysRecorded >= 15);
    monthlyForecasts.add(MonthForecast(
      month: m,
      year: currentYear,
      actualEggs: monthTotal,
      forecastEggs: 0, // filled in below
      perHenRate: 0,
      daylightHours: daylightCurve[m - 1],
      isActual: daysRecorded > 0,
      isComplete: isComplete,
      daysRecorded: daysRecorded,
    ));
  }

  // Backfill from prior years for months without current-year data.
  // Uses recency-weighted average: recent years count more than older ones.
  // Weight = 1/yearsAgo (last year = 1.0, 2 years ago = 0.5, 3 = 0.33).
  // Current year rates (set above) always take precedence.
  final priorYears = dailyMap.keys
      .map((d) => d.year)
      .where((y) => y != currentYear)
      .toSet()
      .toList()
    ..sort();

  // Collect per-hen rates from all prior years, keyed by month.
  // Pre-aggregate totals, then batch-fetch all needed flock sizes.
  final priorRates = <int, List<({double rate, int year})>>{};

  // First pass: aggregate egg totals per prior-year month
  final priorMonthData = <(int year, int monthIdx), ({int total, int days})>{};
  final priorMidMonthDates = <DateTime>[];

  for (final year in priorYears) {
    final yearDaysPerMonth = _daysPerMonth(year);

    for (var m = 1; m <= 12; m++) {
      if (actualRates.containsKey(m - 1)) continue; // current year wins

      var monthTotal = 0;
      var daysRecorded = 0;
      for (var d = 1; d <= yearDaysPerMonth[m - 1]; d++) {
        final date = DateTime(year, m, d);
        final count = dailyMap[date];
        if (count != null) {
          monthTotal += count;
          daysRecorded++;
        }
      }

      if (daysRecorded >= 10 && monthTotal > 0) {
        final midMonth = DateTime(year, m, 15);
        priorMonthData[(year, m - 1)] =
            (total: monthTotal, days: daysRecorded);
        priorMidMonthDates.add(midMonth);
      }
    }
  }

  // Batch-fetch all prior-year flock sizes in one query
  final priorFlockSizes = await statusEventRepo.getActiveCountsOnDates(
    selectedFlockId,
    priorMidMonthDates,
  );

  // Build prior rates from pre-aggregated data + batch flock sizes
  for (final entry in priorMonthData.entries) {
    final (year, monthIdx) = entry.key;
    final data = entry.value;
    final midMonth = DateTime(year, monthIdx + 1, 15);
    final flockSize = priorFlockSizes[midMonth] ?? 0;
    if (flockSize > 0) {
      final birdDays = flockSize * data.days;
      final rate = data.total / birdDays;
      priorRates.putIfAbsent(monthIdx, () => []).add((rate: rate, year: year));
    }
  }

  // Merge prior years into actualRates using recency-weighted average
  for (final entry in priorRates.entries) {
    final monthIdx = entry.key;
    if (actualRates.containsKey(monthIdx)) continue;

    var weightedSum = 0.0;
    var totalWeight = 0.0;
    for (final r in entry.value) {
      final yearsAgo = currentYear - r.year;
      final weight = 1.0 / yearsAgo; // last year=1.0, 2 ago=0.5, etc.
      weightedSum += r.rate * weight;
      totalWeight += weight;
    }
    if (totalWeight > 0) {
      actualRates[monthIdx] = weightedSum / totalWeight;
    }
  }

  if (actualRates.isEmpty) {
    // Not enough monthly data — use simple rolling average
    final recentDays = _getRecentDays(dailyMap, 30);
    if (recentDays.isEmpty) return ForecastResult.empty;

    final totalRecent = recentDays.values.fold(0, (s, c) => s + c);
    final dailyRate = totalRecent / recentDays.length;
    final perHenRate = dailyRate / activeHens;

    return ForecastResult(
      currentPerHenRate: perHenRate,
      currentDailyRate: dailyRate,
      projectedWeek: (dailyRate * 7).round(),
      projectedMonth: (dailyRate * 30).round(),
      projectedYear: (dailyRate * 365).round(),
      monthlyForecasts: monthlyForecasts,
      activeHens: activeHens,
      latitude: latitude,
      hasEnoughData: true,
    );
  }

  // Calculate yearly projection using daylight-twin matching
  var yearlyTotal = 0.0;
  final updatedForecasts = <MonthForecast>[];

  for (var i = 0; i < 12; i++) {
    final m = i + 1;
    final existing = monthlyForecasts[i];
    final daysInMonth = daysPerMonth[i];

    double monthForecast;
    double perHenRate;

    if (m < now.month) {
      // Past month — use actuals, but extrapolate if incomplete
      if (existing.isComplete || existing.daysRecorded == 0) {
        monthForecast = existing.actualEggs.toDouble();
      } else {
        // Incomplete past month (e.g., started logging mid-month) — scale up
        final rate = actualRates[i] ??
            _getForecastPerHenRate(i, actualRates, daylightCurve);
        monthForecast = rate * activeHens * daysInMonth;
      }
      perHenRate = actualRates[i] ?? 0;
    } else if (m == now.month) {
      // Current month — actuals so far + forecast remaining days
      final daysRemaining = daysInMonth - existing.daysRecorded;
      if (actualRates.containsKey(i) && daysRemaining > 0) {
        perHenRate = actualRates[i]!;
        monthForecast = existing.actualEggs +
            (perHenRate * activeHens * daysRemaining);
      } else {
        perHenRate = _getForecastPerHenRate(i, actualRates, daylightCurve);
        monthForecast = existing.actualEggs +
            (perHenRate * activeHens * daysRemaining);
      }
    } else {
      // Future month — full forecast
      perHenRate = _getForecastPerHenRate(i, actualRates, daylightCurve);
      monthForecast = perHenRate * activeHens * daysInMonth;
    }

    yearlyTotal += monthForecast;

    updatedForecasts.add(MonthForecast(
      month: m,
      year: currentYear,
      actualEggs: existing.actualEggs,
      forecastEggs: monthForecast.round(),
      perHenRate: perHenRate,
      daylightHours: daylightCurve[i],
      isActual: existing.isActual,
      isComplete: existing.isComplete,
      daysRecorded: existing.daysRecorded,
    ));
  }

  // Current per-hen rate from recent actual data
  final currentRate = _getCurrentPerHenRate(actualRates, now.month - 1);
  final currentDailyRate = currentRate * activeHens;

  // Short-term projections use current rate (not daylight-adjusted)
  final projectedWeek = (currentDailyRate * 7).round();
  final projectedMonth = (currentDailyRate * 30).round();

  return ForecastResult(
    currentPerHenRate: currentRate,
    currentDailyRate: currentDailyRate,
    projectedWeek: projectedWeek,
    projectedMonth: projectedMonth,
    projectedYear: yearlyTotal.round(),
    monthlyForecasts: updatedForecasts,
    activeHens: activeHens,
    latitude: latitude,
    hasEnoughData: true,
  );
});

// ==================== Helpers ====================

/// Get forecast per-hen rate for a target month using daylight-twin matching.
double _getForecastPerHenRate(
  int monthIndex,
  Map<int, double> actualRates,
  List<double> daylightCurve,
) {
  if (actualRates.isEmpty) return 0;

  final targetDL = daylightCurve[monthIndex];
  int? bestMonth;
  var bestDiff = double.infinity;

  for (final m in actualRates.keys) {
    final diff = (daylightCurve[m] - targetDL).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      bestMonth = m;
    }
  }

  if (bestMonth != null) {
    final matchedRate = actualRates[bestMonth]!;
    final matchedDL = daylightCurve[bestMonth];
    // Dampened ratio — 0.6 exponent prevents overcorrection.
    // Near the equator, daylight is ~flat so ratio ≈ 1.0 and the
    // matched rate passes through unscaled. That's correct: flat
    // daylight means flat production, so no seasonal adjustment needed.
    final ratio = math.pow(targetDL / matchedDL, 0.6);
    return matchedRate * ratio;
  }

  return 0;
}

/// Circular month distance (Jan↔Dec = 1, not 11).
int _monthDistance(int a, int b) {
  final d = (a - b).abs();
  return d <= 6 ? d : 12 - d;
}

/// Get the best current per-hen rate from actuals.
/// Prefers the current month, falls back to nearest (with wrap-around).
double _getCurrentPerHenRate(Map<int, double> actualRates, int currentMonthIdx) {
  if (actualRates.containsKey(currentMonthIdx)) {
    return actualRates[currentMonthIdx]!;
  }
  // Fall back to the nearest month with data (circular distance)
  final sorted = actualRates.keys.toList()
    ..sort((a, b) =>
        _monthDistance(a, currentMonthIdx)
            .compareTo(_monthDistance(b, currentMonthIdx)));
  if (sorted.isNotEmpty) return actualRates[sorted.first]!;
  return 0;
}

/// Get daily egg counts for the most recent N days.
Map<DateTime, int> _getRecentDays(Map<DateTime, int> dailyMap, int days) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final result = <DateTime, int>{};

  for (var i = 0; i < days; i++) {
    final date = today.subtract(Duration(days: i));
    final count = dailyMap[date];
    if (count != null) {
      result[date] = count;
    }
  }
  return result;
}

/// Days per month for a given year (handles leap year).
List<int> _daysPerMonth(int year) {
  final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  return [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
}

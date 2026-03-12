import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/expense.dart';
import '../models/financial_forecast.dart';
import '../models/income.dart';
import '../repositories/bird_status_event_repository.dart';
import '../repositories/egg_repository.dart';
import '../repositories/finance_repository.dart';
import 'egg_value_provider.dart';
import 'flock_provider.dart';
import 'forecast_provider.dart';

/// ln(2) — used for exponential decay half-life calculations.
const _ln2 = 0.693147;

// ==================== Main Provider ====================

final financialForecastProvider =
    FutureProvider<FinancialForecast>((ref) async {
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final latitude = await ref.watch(userLatitudeProvider.future);
  final retailPrice = ref.watch(retailPricePerDozenProvider);
  final eggForecast = await ref.watch(forecastProvider.future);

  final repo = FinanceRepository();
  final statusRepo = BirdStatusEventRepository();
  final eggRepo = EggRepository();

  // ---- Gather data ----

  final expenses = selectedFlockId != null
      ? await repo.getExpensesByFlock(selectedFlockId)
      : await repo.getAllExpenses();

  if (expenses.isEmpty) return FinancialForecast.empty;

  // ---- Observation period ----

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sortedDates = expenses.map((e) => e.date).toList()..sort();
  final firstDate = DateTime(
      sortedDates.first.year, sortedDates.first.month, sortedDates.first.day);
  final observationDays = today.difference(firstDate).inDays;

  // ---- Tier (short-circuit before expensive queries if insufficient) ----

  final tier = _computeTier(observationDays, expenses.length);
  if (tier == ForecastTier.insufficient) {
    return FinancialForecast(
      categoryForecasts: [],
      tier: tier,
      observationDays: observationDays,
      totalExpenseCount: expenses.length,
      currentFlockSize: eggForecast.activeHens,
      forecastAnnualEggs: eggForecast.projectedYear,
      monthlyExpenseForecast: 0,
      annualExpenseForecast: 0,
      monthlyExpenseLow: 0,
      monthlyExpenseHigh: 0,
      monthlyIncomeForecast: 0,
      annualIncomeForecast: 0,
      monthlyBreakdown: [],
    );
  }

  // ---- Income (fetched after tier check to avoid unnecessary DB work) ----

  final income = selectedFlockId != null
      ? await repo.getIncomeByFlock(selectedFlockId)
      : await repo.getAllIncome();

  // ---- Historical flock sizes (for per-bird feed normalization) ----

  final sampleDates = <DateTime>[];
  var sampleDate = DateTime(firstDate.year, firstDate.month, 15);
  while (sampleDate.isBefore(today)) {
    sampleDates.add(sampleDate);
    sampleDate = DateTime(sampleDate.year, sampleDate.month + 1, 15);
  }

  final flockSizes = sampleDates.isNotEmpty
      ? await statusRepo.getActiveCountsOnDates(selectedFlockId, sampleDates)
      : <DateTime, int>{};

  final sizeValues = flockSizes.values.where((s) => s > 0).toList();
  final avgFlockSize = sizeValues.isEmpty
      ? eggForecast.activeHens.toDouble()
      : sizeValues.fold(0, (s, v) => s + v) / sizeValues.length;

  // ---- Per-category forecasts ----

  final byCategory = <ExpenseCategory, List<Expense>>{};
  for (final e in expenses) {
    byCategory.putIfAbsent(e.category, () => []).add(e);
  }

  final seasonalMultipliers = _getFeedSeasonalMultipliers(latitude);
  final currentFlockSize = eggForecast.activeHens;

  final categoryForecasts = <CategoryForecast>[];

  for (final entry in byCategory.entries) {
    final category = entry.key;
    final catExpenses = entry.value;
    final type = _classifyCategory(category);

    if (type == CategoryType.regular) {
      categoryForecasts.add(_computeRegularForecast(
        category: category,
        expenses: catExpenses,
        observationDays: observationDays,
        avgFlockSize: avgFlockSize,
        currentFlockSize: currentFlockSize,
        seasonalMultipliers: seasonalMultipliers,
        today: today,
      ));
    } else {
      categoryForecasts.add(_computeIrregularForecast(
        category: category,
        expenses: catExpenses,
        observationDays: observationDays,
        firstDate: firstDate,
        today: today,
      ));
    }
  }

  // ---- Monthly breakdown ----

  final monthlyBreakdown = _computeMonthlyBreakdown(
    categoryForecasts: categoryForecasts,
    expenses: expenses,
    seasonalMultipliers: seasonalMultipliers,
    currentFlockSize: currentFlockSize,
    now: now,
  );

  // ---- Expense summary ----
  // Annual forecast is the sum of 12 seasonally-adjusted months,
  // not dailyRate * 365 (which would bake one month's seasonal
  // multiplier into the full year for feed).

  final annualExpense =
      monthlyBreakdown.fold(0.0, (sum, m) => sum + m.forecast);
  final monthlyExpense = annualExpense / 12;

  // Range: regular ±15%, irregular uses annualLow/annualHigh
  var rangeLowAnnual = 0.0;
  var rangeHighAnnual = 0.0;
  for (final c in categoryForecasts) {
    if (c.type == CategoryType.regular) {
      rangeLowAnnual += c.annualForecast * 0.85;
      rangeHighAnnual += c.annualForecast * 1.15;
    } else {
      rangeLowAnnual += c.annualLow ?? c.annualForecast * 0.5;
      rangeHighAnnual += c.annualHigh ?? c.annualForecast * 1.5;
    }
  }
  final monthlyLow = rangeLowAnnual / 12;
  final monthlyHigh = rangeHighAnnual / 12;

  // ---- Income forecast ----

  final incomeForecast = await _computeIncomeForecast(
    income: income,
    eggForecast: eggForecast,
    eggRepo: eggRepo,
    selectedFlockId: selectedFlockId,
    now: now,
  );

  final monthlyIncome = incomeForecast?.monthlyForecast ?? 0.0;
  final annualIncome = incomeForecast?.annualForecast ?? 0.0;

  // ---- Derived metrics ----

  final annualEggs = eggForecast.projectedYear;
  final forecastCostPerEgg =
      annualEggs > 0 ? annualExpense / annualEggs : null;
  final forecastCostPerDozen =
      forecastCostPerEgg != null ? forecastCostPerEgg * 12 : null;

  // Break-even: months until cumulative income exceeds cumulative expenses.
  // Only possible if monthly net is positive.
  final monthlyNet = monthlyIncome - monthlyExpense;
  double? breakEvenMonths;
  if (monthlyNet > 0) {
    // Use all-time cumulative deficit as the starting point.
    final allTimeExpenses = await repo.getTotalExpensesAllTime();
    final allTimeIncome = await repo.getTotalIncomeAllTime();
    final deficit = allTimeExpenses - allTimeIncome;
    if (deficit > 0) {
      breakEvenMonths = deficit / monthlyNet;
    } else {
      breakEvenMonths = 0; // Already broken even
    }
  }

  // Retail comparison: savings vs buying eggs at store price.
  // retailPrice is per-dozen (from retailPricePerDozenProvider).
  final retailPerEgg = retailPrice / 12;
  double? monthlySavingsVsRetail;
  if (forecastCostPerEgg != null && annualEggs > 0) {
    final monthlyEggsConsumed = annualEggs / 12;
    monthlySavingsVsRetail =
        monthlyEggsConsumed * (retailPerEgg - forecastCostPerEgg);
  }

  return FinancialForecast(
    categoryForecasts: categoryForecasts,
    incomeForecast: incomeForecast,
    monthlyExpenseForecast: monthlyExpense,
    annualExpenseForecast: annualExpense,
    monthlyExpenseLow: monthlyLow,
    monthlyExpenseHigh: monthlyHigh,
    monthlyIncomeForecast: monthlyIncome,
    annualIncomeForecast: annualIncome,
    forecastCostPerEgg: forecastCostPerEgg,
    forecastCostPerDozen: forecastCostPerDozen,
    breakEvenMonths: breakEvenMonths,
    monthlySavingsVsRetail: monthlySavingsVsRetail,
    monthlyBreakdown: monthlyBreakdown,
    tier: tier,
    observationDays: observationDays,
    totalExpenseCount: expenses.length,
    currentFlockSize: currentFlockSize,
    forecastAnnualEggs: annualEggs,
  );
});

// ==================== Tier Computation ====================

ForecastTier _computeTier(int observationDays, int expenseCount) {
  if (observationDays < 30 || expenseCount < 8) {
    return ForecastTier.insufficient;
  }
  if (observationDays >= 365) return ForecastTier.seasoned;
  if (observationDays >= 180) return ForecastTier.mature;
  if (observationDays >= 90) return ForecastTier.established;
  return ForecastTier.emerging;
}

// ==================== Category Classification ====================

/// Feed, bedding, and supplies have predictable recurring patterns.
/// Medical, equipment, and other are sporadic / high-variance.
CategoryType _classifyCategory(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.feed:
    case ExpenseCategory.bedding:
    case ExpenseCategory.supplies:
      return CategoryType.regular;
    case ExpenseCategory.medical:
    case ExpenseCategory.equipment:
    case ExpenseCategory.other:
      return CategoryType.irregular;
  }
}

// ==================== Regular Category Forecast ====================

/// Computes daily run-rate with "last bag" correction.
/// Feed gets per-bird normalization; seasonal adjustment is stored
/// separately on perBirdDailyRate so callers can apply per-month
/// multipliers without double-counting.
CategoryForecast _computeRegularForecast({
  required ExpenseCategory category,
  required List<Expense> expenses,
  required int observationDays,
  required double avgFlockSize,
  required int currentFlockSize,
  required List<double> seasonalMultipliers,
  required DateTime today,
}) {
  final totalSpend = expenses.fold(0.0, (sum, e) => sum + e.amount);
  final count = expenses.length;

  // Sort by date for interval calculation
  final dates = expenses.map((e) => e.date).toList()..sort();
  final firstDate = dates.first;

  // Daily rate with "last bag" correction:
  // Span runs from first purchase to today (not last purchase),
  // then we add one average inter-purchase interval to account
  // for the most recent purchase still being consumed.
  final spanDays = today.difference(firstDate).inDays;
  double dailyRate;
  if (count >= 2 && spanDays > 0) {
    final avgInterval = spanDays / (count - 1);
    final adjustedSpan = spanDays + avgInterval;
    dailyRate = totalSpend / adjustedSpan;
  } else {
    // Single purchase or same-day purchases: use full observation period
    dailyRate = observationDays > 0 ? totalSpend / observationDays : 0;
  }

  // Per-bird normalization for feed — store the unseasonalized rate
  // so monthly breakdown can apply per-month multipliers.
  double? perBirdDailyRate;
  if (category == ExpenseCategory.feed && avgFlockSize > 0) {
    perBirdDailyRate = dailyRate / avgFlockSize;
    // Re-scale to current flock size (no seasonal multiplier here —
    // that's applied per-month in the breakdown and summed for annual).
    dailyRate = perBirdDailyRate * currentFlockSize;
  }

  // For feed, annual forecast is the sum of 12 seasonally-adjusted months.
  // For other regular categories, seasonal multipliers don't apply.
  double annualForecast;
  if (category == ExpenseCategory.feed && perBirdDailyRate != null) {
    final currentYear = today.year;
    final dpm = _daysPerMonth(currentYear);
    annualForecast = 0;
    for (var m = 0; m < 12; m++) {
      annualForecast +=
          perBirdDailyRate * currentFlockSize * dpm[m] * seasonalMultipliers[m];
    }
  } else {
    annualForecast = dailyRate * 365;
  }

  final hasRecurring = expenses.any((e) => e.isRecurring);
  // TODO: When recurring flag is present, use the flagged amount/interval
  // as the primary signal and validate against historical rate (see GH #7).

  return CategoryForecast(
    category: category,
    type: CategoryType.regular,
    dailyRate: dailyRate,
    monthlyForecast: annualForecast / 12,
    annualForecast: annualForecast,
    transactionCount: count,
    perBirdDailyRate: perBirdDailyRate,
    hasRecurringFlag: hasRecurring,
  );
}

// ==================== Irregular Category Forecast ====================

/// Annualized average with per-year min/max range.
/// Partial years at the edges of the observation window are normalized
/// to 12-month equivalents before computing the range.
CategoryForecast _computeIrregularForecast({
  required ExpenseCategory category,
  required List<Expense> expenses,
  required int observationDays,
  required DateTime firstDate,
  required DateTime today,
}) {
  final totalSpend = expenses.fold(0.0, (sum, e) => sum + e.amount);
  final count = expenses.length;

  final years = observationDays / 365.0;
  final annualRate = years > 0 ? totalSpend / years : totalSpend;

  // Compute per-year totals, normalized to 12-month equivalents.
  // Partial years (first and last) are scaled up by the fraction
  // of the year actually observed, to avoid systematically low ranges.
  final perYear = <int, double>{};
  for (final e in expenses) {
    perYear[e.date.year] = (perYear[e.date.year] ?? 0) + e.amount;
  }

  double? annualLow;
  double? annualHigh;
  if (perYear.length >= 2) {
    final normalizedTotals = <double>[];
    for (final entry in perYear.entries) {
      final year = entry.key;
      final total = entry.value;

      // Determine what fraction of this year we observed
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year, 12, 31);
      final obsStart = firstDate.isAfter(yearStart) ? firstDate : yearStart;
      final obsEnd = today.isBefore(yearEnd) ? today : yearEnd;
      final daysObserved = obsEnd.difference(obsStart).inDays + 1;

      if (daysObserved >= 60) {
        // Only include years with meaningful observation (2+ months)
        final fractionOfYear = daysObserved / 365.0;
        normalizedTotals.add(total / fractionOfYear);
      }
    }

    if (normalizedTotals.length >= 2) {
      normalizedTotals.sort();
      annualLow = normalizedTotals.first;
      annualHigh = normalizedTotals.last;
    }
  }

  final dailyRate = annualRate / 365;

  return CategoryForecast(
    category: category,
    type: CategoryType.irregular,
    dailyRate: dailyRate,
    monthlyForecast: annualRate / 12,
    annualForecast: annualRate,
    annualLow: annualLow,
    annualHigh: annualHigh,
    transactionCount: count,
    hasRecurringFlag: expenses.any((e) => e.isRecurring),
  );
}

// ==================== Income Forecast ====================

/// Forecasts income from egg sales: forecastEggs * sellRate * pricePerEgg.
/// Returns null if user never sells eggs.
///
/// Sell rate uses only the date range covered by sales with known egg
/// counts, so income records without eggCount don't dilute the ratio.
Future<IncomeForecast?> _computeIncomeForecast({
  required List<Income> income,
  required ForecastResult eggForecast,
  required EggRepository eggRepo,
  required String? selectedFlockId,
  required DateTime now,
}) async {
  // Filter to sales with known egg counts
  final eggSales = income
      .where((i) => i.eggCount != null && i.eggCount! > 0)
      .toList();

  if (eggSales.isEmpty) return null;

  // Check minimum threshold: 3+ sales spanning 60+ days
  final saleDates = eggSales.map((s) => s.date).toList()..sort();
  final saleSpanDays = saleDates.last.difference(saleDates.first).inDays;
  final hasSufficientData = eggSales.length >= 3 && saleSpanDays >= 60;

  // Check regime cessation: no sales in 90+ days
  final daysSinceLastSale = now.difference(saleDates.last).inDays;
  final isActive = daysSinceLastSale < 90;

  // Sell rate: eggs sold / eggs produced.
  // Use the window from 30 days before first sale to the last sale date
  // (not "now"), so that a gap between last sale and today doesn't
  // dilute the rate with production that wasn't sold.
  final onsetDate =
      saleDates.first.subtract(const Duration(days: 30));
  final rateEndDate = saleDates.last;
  final totalEggsSold =
      eggSales.fold(0, (sum, s) => sum + s.eggCount!);

  final totalEggsProduced = selectedFlockId != null
      ? await eggRepo.getEggCountByFlockAndDateRange(
          selectedFlockId, onsetDate, rateEndDate)
      : await eggRepo.getEggCountByDateRange(onsetDate, rateEndDate);

  final sellRate =
      totalEggsProduced > 0 ? totalEggsSold / totalEggsProduced : 0.0;

  // Price per egg: recency-weighted average (90-day half-life)
  final pricePerEgg = _recencyWeightedPrice(eggSales, now);

  // Forecast
  final effectiveSellRate = isActive ? sellRate : 0.0;
  final annualEggs = eggForecast.projectedYear;
  final annualForecast = annualEggs * effectiveSellRate * pricePerEgg;
  final monthlyForecast = annualForecast / 12;

  return IncomeForecast(
    sellRate: sellRate,
    pricePerEgg: pricePerEgg,
    monthlyForecast: monthlyForecast,
    annualForecast: annualForecast,
    hasSufficientData: hasSufficientData,
    isActive: isActive,
  );
}

/// Recency-weighted average price per egg with 90-day half-life.
double _recencyWeightedPrice(List<Income> eggSales, DateTime now) {
  var weightedSum = 0.0;
  var totalWeight = 0.0;

  for (final sale in eggSales) {
    if (sale.eggCount == null || sale.eggCount! <= 0) continue;
    final daysAgo = now.difference(sale.date).inDays;
    final weight = math.exp(-_ln2 * daysAgo / 90);
    final price = sale.amount / sale.eggCount!;
    weightedSum += price * weight;
    totalWeight += weight;
  }

  return totalWeight > 0 ? weightedSum / totalWeight : 0;
}

// ==================== Monthly Breakdown ====================

/// Build 12-month expense breakdown for the current year.
/// Past months show actual data; current month blends actual-so-far
/// with a prorated forecast for remaining days; future months show
/// the full forecast.
List<MonthlyExpenseForecast> _computeMonthlyBreakdown({
  required List<CategoryForecast> categoryForecasts,
  required List<Expense> expenses,
  required List<double> seasonalMultipliers,
  required int currentFlockSize,
  required DateTime now,
}) {
  final currentYear = now.year;

  // Actual monthly totals from expense data
  final monthlyActuals = List<double>.filled(12, 0);
  for (final e in expenses) {
    if (e.date.year == currentYear) {
      monthlyActuals[e.date.month - 1] += e.amount;
    }
  }

  // Separate feed from other categories for seasonal adjustment
  final feedForecast =
      categoryForecasts.where((c) => c.category == ExpenseCategory.feed);
  final feedPerBirdRate = feedForecast.isNotEmpty
      ? feedForecast.first.perBirdDailyRate ?? 0.0
      : 0.0;
  final nonFeedDailyRate = categoryForecasts
      .where((c) => c.category != ExpenseCategory.feed)
      .fold(0.0, (sum, c) => sum + c.dailyRate);

  final daysPerMonth = _daysPerMonth(currentYear);
  final breakdown = <MonthlyExpenseForecast>[];

  for (var m = 1; m <= 12; m++) {
    final isPast = m < now.month;
    final isCurrent = m == now.month;
    final days = daysPerMonth[m - 1];

    // Full-month forecast with seasonal feed adjustment
    final feedMonthly =
        feedPerBirdRate * currentFlockSize * days * seasonalMultipliers[m - 1];
    final otherMonthly = nonFeedDailyRate * days;
    final fullMonthForecast = feedMonthly + otherMonthly;

    double forecast;
    double? actual;

    if (isPast) {
      // Past month: show actual, use forecast as the chart projection
      actual = monthlyActuals[m - 1];
      forecast = fullMonthForecast;
    } else if (isCurrent) {
      // Current month: actual so far + prorated forecast for remaining days
      actual = monthlyActuals[m - 1];
      final elapsedDays = now.day;
      final remainingDays = days - elapsedDays;
      final dailyForecast = fullMonthForecast / days;
      forecast = actual + (dailyForecast * remainingDays);
    } else {
      // Future month: full forecast
      forecast = fullMonthForecast;
    }

    breakdown.add(MonthlyExpenseForecast(
      month: m,
      year: currentYear,
      forecast: forecast,
      actual: (isPast || isCurrent) ? actual : null,
      isPast: isPast,
    ));
  }

  return breakdown;
}

// ==================== Seasonal Multipliers ====================

/// Feed consumption seasonal multipliers based on latitude.
/// Birds eat 20-30% more in winter (higher caloric need).
/// Returns 12 values (Jan–Dec), normalized around 1.0.
List<double> _getFeedSeasonalMultipliers(int latitude) {
  // Base multipliers for mid-latitude northern hemisphere (~35-40°N)
  // Source: Alabama Cooperative Extension (~340 kcal/day winter vs 260 summer)
  const base = [1.15, 1.15, 1.10, 1.00, 0.95, 0.90,
                 0.85, 0.85, 0.90, 1.00, 1.05, 1.10];

  final absLat = latitude.abs();

  // Scale factor: more seasonal variation at higher latitudes,
  // flattening toward 1.0 near the equator
  final double scale;
  if (absLat < 15) {
    scale = absLat / 15.0; // 0 at equator → 1.0 at 15°
  } else if (absLat > 45) {
    scale = 1.0 + (absLat - 45) / 50.0; // up to ~1.3 at 60°
  } else {
    scale = 1.0;
  }

  // Apply scale: deviation from 1.0 is amplified or dampened
  var multipliers = base.map((m) => 1.0 + (m - 1.0) * scale).toList();

  // Southern hemisphere: shift seasons by 6 months
  if (latitude < 0) {
    multipliers = [...multipliers.sublist(6), ...multipliers.sublist(0, 6)];
  }

  return multipliers;
}

// ==================== Helpers ====================

/// Days per month for a given year (handles leap year).
List<int> _daysPerMonth(int year) {
  final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  return [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
}

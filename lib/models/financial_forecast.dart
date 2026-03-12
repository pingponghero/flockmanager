import 'enums.dart';

/// Data confidence tier based on observation period and expense count.
/// Controls what forecast features are unlocked and how results are labeled.
enum ForecastTier {
  /// Less than 30 days or fewer than 8 expenses.
  insufficient('Not enough data yet'),

  /// 30+ days and 8+ expenses.
  emerging('Early estimate'),

  /// 90+ days.
  established('Projected'),

  /// 6+ months.
  mature('Based on your patterns'),

  /// 12+ months.
  seasoned('Forecast');

  final String label;
  const ForecastTier(this.label);
}

/// Whether a category uses daily run-rate or annualized averaging.
enum CategoryType { regular, irregular }

/// Forecast details for a single expense category.
class CategoryForecast {
  final ExpenseCategory category;
  final CategoryType type;

  /// Computed daily consumption rate (after last-bag correction).
  final double dailyRate;

  /// Expected monthly expense (average month).
  final double monthlyForecast;

  /// Expected annual expense.
  final double annualForecast;

  /// For irregular categories: lowest annual spend observed.
  final double? annualLow;

  /// For irregular categories: highest annual spend observed.
  final double? annualHigh;

  /// Number of transactions in this category.
  final int transactionCount;

  /// For feed: per-bird daily rate before seasonal adjustment.
  final double? perBirdDailyRate;

  /// Whether any transaction in this category has the recurring flag.
  final bool hasRecurringFlag;

  const CategoryForecast({
    required this.category,
    required this.type,
    required this.dailyRate,
    required this.monthlyForecast,
    required this.annualForecast,
    this.annualLow,
    this.annualHigh,
    required this.transactionCount,
    this.perBirdDailyRate,
    this.hasRecurringFlag = false,
  });
}

/// Income projection based on egg sales history.
class IncomeForecast {
  /// Fraction of eggs sold (0.0–1.0).
  final double sellRate;

  /// Recency-weighted average price per egg.
  final double pricePerEgg;

  /// Expected monthly income from egg sales.
  final double monthlyForecast;

  /// Expected annual income from egg sales.
  final double annualForecast;

  /// Whether we have 3+ sales spanning 60+ days.
  final bool hasSufficientData;

  /// Whether the user is still actively selling (sales in last 90 days).
  final bool isActive;

  const IncomeForecast({
    required this.sellRate,
    required this.pricePerEgg,
    required this.monthlyForecast,
    required this.annualForecast,
    required this.hasSufficientData,
    required this.isActive,
  });
}

/// Monthly expense data point for a 12-month chart.
class MonthlyExpenseForecast {
  final int month; // 1-12
  final int year;

  /// Forecast expense for this month.
  final double forecast;

  /// Actual expense for this month (null for future months).
  final double? actual;

  /// Whether this month is in the past.
  final bool isPast;

  const MonthlyExpenseForecast({
    required this.month,
    required this.year,
    required this.forecast,
    this.actual,
    required this.isPast,
  });
}

/// Complete financial forecast result.
class FinancialForecast {
  // ---- Category detail ----
  final List<CategoryForecast> categoryForecasts;

  // ---- Income ----
  final IncomeForecast? incomeForecast;

  // ---- Expense summary ----

  /// Average expected monthly expense.
  final double monthlyExpenseForecast;

  /// Expected annual expense.
  final double annualExpenseForecast;

  /// Lower bound of monthly expense range.
  final double monthlyExpenseLow;

  /// Upper bound of monthly expense range.
  final double monthlyExpenseHigh;

  // ---- Income summary ----
  final double monthlyIncomeForecast;
  final double annualIncomeForecast;

  // ---- Cash flow ----
  double get monthlyCashFlow => monthlyIncomeForecast - monthlyExpenseForecast;
  double get annualCashFlow => annualIncomeForecast - annualExpenseForecast;

  // ---- Derived metrics ----

  /// Projected cost per egg (annual expenses / annual eggs).
  final double? forecastCostPerEgg;

  /// Projected cost per dozen.
  final double? forecastCostPerDozen;

  /// Months until cumulative income exceeds cumulative expenses.
  /// Null means break-even is not projected (expenses exceed income).
  final double? breakEvenMonths;

  /// Monthly savings compared to buying eggs at retail price.
  /// Positive means home eggs are cheaper than store.
  final double? monthlySavingsVsRetail;

  // ---- Monthly chart data (12 entries, Jan–Dec of current year) ----
  final List<MonthlyExpenseForecast> monthlyBreakdown;

  // ---- Metadata ----
  final ForecastTier tier;
  final int observationDays;
  final int totalExpenseCount;
  final int currentFlockSize;
  final int forecastAnnualEggs;

  // ---- Helpers ----
  bool get hasEnoughData => tier != ForecastTier.insufficient;
  bool get isBreakEvenPossible => breakEvenMonths != null;

  const FinancialForecast({
    required this.categoryForecasts,
    this.incomeForecast,
    required this.monthlyExpenseForecast,
    required this.annualExpenseForecast,
    required this.monthlyExpenseLow,
    required this.monthlyExpenseHigh,
    required this.monthlyIncomeForecast,
    required this.annualIncomeForecast,
    this.forecastCostPerEgg,
    this.forecastCostPerDozen,
    this.breakEvenMonths,
    this.monthlySavingsVsRetail,
    required this.monthlyBreakdown,
    required this.tier,
    required this.observationDays,
    required this.totalExpenseCount,
    required this.currentFlockSize,
    required this.forecastAnnualEggs,
  });

  static const empty = FinancialForecast(
    categoryForecasts: [],
    monthlyExpenseForecast: 0,
    annualExpenseForecast: 0,
    monthlyExpenseLow: 0,
    monthlyExpenseHigh: 0,
    monthlyIncomeForecast: 0,
    annualIncomeForecast: 0,
    monthlyBreakdown: [],
    tier: ForecastTier.insufficient,
    observationDays: 0,
    totalExpenseCount: 0,
    currentFlockSize: 0,
    forecastAnnualEggs: 0,
  );
}

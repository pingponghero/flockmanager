/// Computed financial summary comparing egg production value against expenses.
///
/// Egg value uses actual income for sold eggs and store price for consumed eggs:
///   Total Value = consumed value + sale value
///   Where: consumed = (totalEggs - eggsSold) × storePrice/egg
///          saleValue = actual income from sales with egg counts
///
/// Income without egg counts is treated as additive cash — those eggs
/// are still valued at store price and the income is extra.
class EggValueSummary {
  final int eggCount;
  final double eggProductionValue;
  final double totalExpenses;
  final double totalIncome;
  final double retailPricePerDozen;
  final int eggsSold;
  final int eggsGifted;

  const EggValueSummary({
    required this.eggCount,
    required this.eggProductionValue,
    required this.totalExpenses,
    required this.totalIncome,
    required this.retailPricePerDozen,
    this.eggsSold = 0,
    this.eggsGifted = 0,
  });

  /// Egg value minus expenses. Positive = beating the store.
  double get netSavings => eggProductionValue - totalExpenses;

  /// Whether eggs are worth more than what was spent.
  bool get isBeatingTheStore => netSavings >= 0;

  /// Actual cost per egg from expenses, null if no eggs.
  double? get costPerEgg => eggCount > 0 ? totalExpenses / eggCount : null;

  /// Net cost to produce a dozen eggs: (expenses − income) ÷ eggCount × 12.
  /// Based on total production, not just eggs kept, so it stays stable no
  /// matter how eggs are split between kept/sold/gifted — this is the number
  /// to reference for pricing eggs and comparing against the store.
  /// Null if no eggs were produced.
  double? get netCostPerDozen =>
      eggCount > 0 ? (totalExpenses - totalIncome) / eggCount * 12 : null;

  /// Retail price per single egg.
  double get retailPricePerEgg => retailPricePerDozen / 12;

  /// Retail value of eggs given away as gifts (eggsGifted × retail price).
  /// Not added to [netSavings] — you didn't capture this value — but the eggs
  /// you produced still have real monetary worth, so it's surfaced on its own.
  double get giftedValue => eggsGifted * retailPricePerEgg;

  /// Income minus expenses (only meaningful if user tracks income).
  double get cashFlow => totalIncome - totalExpenses;

  /// Eggs consumed (not sold or gifted). Clamped to 0 if sold + gifted
  /// exceeds logged. Gifted eggs are excluded from both sale statistics
  /// and consumed value — they left the flock without revenue.
  int get eggsConsumed => (eggCount - eggsSold - eggsGifted).clamp(0, eggCount);
}

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

  const EggValueSummary({
    required this.eggCount,
    required this.eggProductionValue,
    required this.totalExpenses,
    required this.totalIncome,
    required this.retailPricePerDozen,
    this.eggsSold = 0,
  });

  /// Egg value minus expenses. Positive = beating the store.
  double get netSavings => eggProductionValue - totalExpenses;

  /// Whether eggs are worth more than what was spent.
  bool get isBeatingTheStore => netSavings >= 0;

  /// Actual cost per egg from expenses, null if no eggs.
  double? get costPerEgg => eggCount > 0 ? totalExpenses / eggCount : null;

  /// Net cost per dozen: (expenses − income) ÷ eggsConsumed × 12.
  /// This is what the keeper actually pays per dozen consumed eggs
  /// after offsetting with sales income. Null if no eggs consumed.
  double? get netCostPerDozen =>
      eggsConsumed > 0 ? (totalExpenses - totalIncome) / eggsConsumed * 12 : null;

  /// Retail price per single egg.
  double get retailPricePerEgg => retailPricePerDozen / 12;

  /// Income minus expenses (only meaningful if user tracks income).
  double get cashFlow => totalIncome - totalExpenses;

  /// Eggs consumed (not sold).
  int get eggsConsumed => eggCount - eggsSold;
}

/// Expense and income category metadata for display and visualization.
/// This provides UI-friendly information for the financial tracking features.

import 'package:flutter/material.dart';

// === EXPENSE CATEGORIES ===

enum ExpenseCategory {
  feed,
  bedding,
  supplies,
  medical,
  equipment,
  other,
}

class ExpenseCategoryMeta {
  final ExpenseCategory category;
  final String displayName;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> examples;

  const ExpenseCategoryMeta({
    required this.category,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.color,
    required this.examples,
  });
}

/// Metadata for all expense categories
const Map<ExpenseCategory, ExpenseCategoryMeta> expenseCategoryMeta = {
  ExpenseCategory.feed: ExpenseCategoryMeta(
    category: ExpenseCategory.feed,
    displayName: 'Feed',
    description: 'Layer feed, scratch, treats, and supplements',
    icon: Icons.grass,
    color: Color(0xFFFFB74D), // Amber 300
    examples: [
      'Layer pellets',
      'Scratch grains',
      'Oyster shell',
      'Mealworms',
      'Grit',
      'Treats',
    ],
  ),

  ExpenseCategory.bedding: ExpenseCategoryMeta(
    category: ExpenseCategory.bedding,
    displayName: 'Bedding',
    description: 'Coop bedding and nesting materials',
    icon: Icons.layers,
    color: Color(0xFFA1887F), // Brown 300
    examples: [
      'Pine shavings',
      'Straw',
      'Hay',
      'Hemp bedding',
      'Sand',
      'Nesting pads',
    ],
  ),

  ExpenseCategory.supplies: ExpenseCategoryMeta(
    category: ExpenseCategory.supplies,
    displayName: 'Supplies',
    description: 'Feeders, waterers, and daily supplies',
    icon: Icons.shopping_bag,
    color: Color(0xFF81C784), // Green 300
    examples: [
      'Feeders',
      'Waterers',
      'Heat lamp bulbs',
      'Egg cartons',
      'Cleaning supplies',
      'Pest control',
    ],
  ),

  ExpenseCategory.medical: ExpenseCategoryMeta(
    category: ExpenseCategory.medical,
    displayName: 'Medical',
    description: 'Medications, vet visits, and health supplies',
    icon: Icons.medical_services,
    color: Color(0xFFE57373), // Red 300
    examples: [
      'Medications',
      'Vet visits',
      'First aid supplies',
      'Vitamins',
      'Electrolytes',
      'Wound care',
    ],
  ),

  ExpenseCategory.equipment: ExpenseCategoryMeta(
    category: ExpenseCategory.equipment,
    displayName: 'Equipment',
    description: 'Coop, fencing, and major purchases',
    icon: Icons.construction,
    color: Color(0xFF64B5F6), // Blue 300
    examples: [
      'Coop materials',
      'Fencing',
      'Automatic door',
      'Heated waterer',
      'Brooder setup',
      'Run expansion',
    ],
  ),

  ExpenseCategory.other: ExpenseCategoryMeta(
    category: ExpenseCategory.other,
    displayName: 'Other',
    description: 'Miscellaneous chicken-related expenses',
    icon: Icons.more_horiz,
    color: Color(0xFF9E9E9E), // Gray 500
    examples: [
      'Books/guides',
      'Poultry show fees',
      'Leg bands',
      'Shipping (chicks)',
      'Licensing fees',
      'Misc',
    ],
  ),
};

// === INCOME CATEGORIES ===

enum IncomeCategory {
  eggSales,
  birdSales,
  chicksHatched,
  fertileEggs,
  manure,
  other,
}

class IncomeCategoryMeta {
  final IncomeCategory category;
  final String displayName;
  final String description;
  final IconData icon;
  final Color color;
  final bool trackQuantity; // Whether to prompt for quantity (eggs, birds, etc.)
  final String? quantityLabel; // Label for quantity field if tracked

  const IncomeCategoryMeta({
    required this.category,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.color,
    this.trackQuantity = false,
    this.quantityLabel,
  });
}

/// Metadata for all income categories
const Map<IncomeCategory, IncomeCategoryMeta> incomeCategoryMeta = {
  IncomeCategory.eggSales: IncomeCategoryMeta(
    category: IncomeCategory.eggSales,
    displayName: 'Egg Sales',
    description: 'Income from selling eggs',
    icon: Icons.egg,
    color: Color(0xFFFFD54F), // Amber 300
    trackQuantity: true,
    quantityLabel: 'Dozen sold',
  ),

  IncomeCategory.birdSales: IncomeCategoryMeta(
    category: IncomeCategory.birdSales,
    displayName: 'Bird Sales',
    description: 'Income from selling chickens',
    icon: Icons.savings,
    color: Color(0xFF81C784), // Green 300
    trackQuantity: true,
    quantityLabel: 'Birds sold',
  ),

  IncomeCategory.chicksHatched: IncomeCategoryMeta(
    category: IncomeCategory.chicksHatched,
    displayName: 'Chick Sales',
    description: 'Income from selling hatched chicks',
    icon: Icons.flutter_dash,
    color: Color(0xFFFFCC80), // Orange 200
    trackQuantity: true,
    quantityLabel: 'Chicks sold',
  ),

  IncomeCategory.fertileEggs: IncomeCategoryMeta(
    category: IncomeCategory.fertileEggs,
    displayName: 'Fertile Eggs',
    description: 'Income from selling hatching eggs',
    icon: Icons.egg_alt,
    color: Color(0xFFCE93D8), // Purple 200
    trackQuantity: true,
    quantityLabel: 'Eggs sold',
  ),

  IncomeCategory.manure: IncomeCategoryMeta(
    category: IncomeCategory.manure,
    displayName: 'Manure/Compost',
    description: 'Income from selling composted manure',
    icon: Icons.compost,
    color: Color(0xFF8D6E63), // Brown 400
    trackQuantity: false,
  ),

  IncomeCategory.other: IncomeCategoryMeta(
    category: IncomeCategory.other,
    displayName: 'Other',
    description: 'Other chicken-related income',
    icon: Icons.more_horiz,
    color: Color(0xFF9E9E9E), // Gray 500
    trackQuantity: false,
  ),
};

// === RECURRING INTERVALS ===

enum RecurringInterval {
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

class RecurringIntervalMeta {
  final RecurringInterval interval;
  final String displayName;
  final String shortName;
  final int approximateDays;

  const RecurringIntervalMeta({
    required this.interval,
    required this.displayName,
    required this.shortName,
    required this.approximateDays,
  });
}

const Map<RecurringInterval, RecurringIntervalMeta> recurringIntervalMeta = {
  RecurringInterval.weekly: RecurringIntervalMeta(
    interval: RecurringInterval.weekly,
    displayName: 'Weekly',
    shortName: 'wk',
    approximateDays: 7,
  ),
  RecurringInterval.biweekly: RecurringIntervalMeta(
    interval: RecurringInterval.biweekly,
    displayName: 'Every 2 Weeks',
    shortName: '2wk',
    approximateDays: 14,
  ),
  RecurringInterval.monthly: RecurringIntervalMeta(
    interval: RecurringInterval.monthly,
    displayName: 'Monthly',
    shortName: 'mo',
    approximateDays: 30,
  ),
  RecurringInterval.quarterly: RecurringIntervalMeta(
    interval: RecurringInterval.quarterly,
    displayName: 'Quarterly',
    shortName: 'qtr',
    approximateDays: 90,
  ),
  RecurringInterval.yearly: RecurringIntervalMeta(
    interval: RecurringInterval.yearly,
    displayName: 'Yearly',
    shortName: 'yr',
    approximateDays: 365,
  ),
};

// === HELPER FUNCTIONS ===

/// Get expense category metadata by enum value
ExpenseCategoryMeta getExpenseCategoryMeta(ExpenseCategory category) {
  return expenseCategoryMeta[category]!;
}

/// Get income category metadata by enum value
IncomeCategoryMeta getIncomeCategoryMeta(IncomeCategory category) {
  return incomeCategoryMeta[category]!;
}

/// Get recurring interval metadata by enum value
RecurringIntervalMeta getRecurringIntervalMeta(RecurringInterval interval) {
  return recurringIntervalMeta[interval]!;
}

/// Get all expense categories as a list (useful for dropdowns)
List<ExpenseCategoryMeta> getAllExpenseCategories() {
  return ExpenseCategory.values
      .map((c) => expenseCategoryMeta[c]!)
      .toList();
}

/// Get all income categories as a list
List<IncomeCategoryMeta> getAllIncomeCategories() {
  return IncomeCategory.values
      .map((c) => incomeCategoryMeta[c]!)
      .toList();
}

/// Get all recurring intervals as a list
List<RecurringIntervalMeta> getAllRecurringIntervals() {
  return RecurringInterval.values
      .map((i) => recurringIntervalMeta[i]!)
      .toList();
}

/// Parse expense category from string (for database)
ExpenseCategory? parseExpenseCategory(String? value) {
  if (value == null) return null;
  try {
    return ExpenseCategory.values.firstWhere(
      (c) => c.name == value,
    );
  } catch (_) {
    return null;
  }
}

/// Parse income category from string (for database)
IncomeCategory? parseIncomeCategory(String? value) {
  if (value == null) return null;
  try {
    return IncomeCategory.values.firstWhere(
      (c) => c.name == value,
    );
  } catch (_) {
    return null;
  }
}

/// Parse recurring interval from string (for database)
RecurringInterval? parseRecurringInterval(String? value) {
  if (value == null) return null;
  try {
    return RecurringInterval.values.firstWhere(
      (i) => i.name == value,
    );
  } catch (_) {
    return null;
  }
}

// === CHART HELPERS ===

/// Get colors for expense pie chart in consistent order
List<Color> getExpenseChartColors() {
  return ExpenseCategory.values
      .map((c) => expenseCategoryMeta[c]!.color)
      .toList();
}

/// Get colors for income pie chart in consistent order
List<Color> getIncomeChartColors() {
  return IncomeCategory.values
      .map((c) => incomeCategoryMeta[c]!.color)
      .toList();
}

// === TYPICAL VALUES (for suggestions/autocomplete) ===

/// Common expense descriptions by category
const Map<ExpenseCategory, List<String>> commonExpenseDescriptions = {
  ExpenseCategory.feed: [
    '50lb layer feed',
    '40lb scratch grains',
    '5lb oyster shell',
    'Dried mealworms',
    'Poultry grit',
    'Flock block',
  ],
  ExpenseCategory.bedding: [
    'Pine shavings (bale)',
    'Straw bale',
    'Hemp bedding',
    'Sand (bags)',
    'Nesting box pads',
  ],
  ExpenseCategory.supplies: [
    'Replacement waterer',
    'Feeder',
    'Heat lamp bulb',
    'Egg cartons (flat)',
    'Coop cleaner',
    'Poultry dust',
  ],
  ExpenseCategory.medical: [
    'Corid',
    'SafeGuard',
    'Vet visit',
    'Vitamins & electrolytes',
    'Blu-Kote',
    'VetRx',
  ],
  ExpenseCategory.equipment: [
    'Automatic coop door',
    'Heated waterer base',
    'Fencing materials',
    'Coop repairs',
    'Run netting',
    'Brooder lamp',
  ],
  ExpenseCategory.other: [
    'Chicken keeping book',
    'Leg bands',
    'Chick shipping',
    'Poultry show entry',
  ],
};

/// Get suggested descriptions for expense autocomplete
List<String> getSuggestedExpenseDescriptions(ExpenseCategory category) {
  return commonExpenseDescriptions[category] ?? [];
}

// === BUDGET HELPERS ===

/// Typical monthly cost ranges by category (USD, small backyard flock of 4-8 birds)
/// These are rough estimates for context/comparison features
const Map<ExpenseCategory, ({double low, double typical, double high})> 
    typicalMonthlyCosts = {
  ExpenseCategory.feed: (low: 15, typical: 25, high: 50),
  ExpenseCategory.bedding: (low: 5, typical: 10, high: 20),
  ExpenseCategory.supplies: (low: 0, typical: 5, high: 15),
  ExpenseCategory.medical: (low: 0, typical: 5, high: 30),
  ExpenseCategory.equipment: (low: 0, typical: 10, high: 50),
  ExpenseCategory.other: (low: 0, typical: 5, high: 10),
};

/// Get total typical monthly cost (all categories)
({double low, double typical, double high}) getTotalTypicalMonthlyCost() {
  double low = 0, typical = 0, high = 0;
  for (final costs in typicalMonthlyCosts.values) {
    low += costs.low;
    typical += costs.typical;
    high += costs.high;
  }
  return (low: low, typical: typical, high: high);
}

# Flock Manager — Egg Value Feature Spec

## Overview

The Value tab answers one question for every keeper: "Is my flock worth it financially?" It replaces the old separate Expenses/Income tabs with a single consolidated screen showing what your flock produced, what it cost, and whether you're coming out ahead.

The math distinguishes between eggs you ate (savings vs. store) and eggs you sold (actual income). No user-type toggle, no per-egg disposition tracking, no red numbers.

---

## Core Concept

A flock produces value two ways:

1. **Savings** — eggs you consumed replaced a grocery purchase
2. **Earnings** — eggs you sold generated actual income

**Total Flock Value** = Savings + Earnings

**Net Impact** = Total Flock Value − Expenses

A positive Net Impact means the flock is paying for itself and then some. A negative Net Impact is the true hobby cost beyond what the flock gave back. Both are presented as neutral facts, not judgments.

---

## Formulas

### Inputs

| Variable | Source |
|----------|--------|
| `total_eggs` | Sum of `egg_logs.count` in period |
| `eggs_sold` | Sum of `income.egg_count` in period (where egg_count is non-null) |
| `income` | Sum of `income.amount` in period |
| `store_price_per_egg` | User's `retail_egg_price_per_dozen` ÷ 12 |
| `expenses` | Sum of `expenses.amount` in period |

### Derived Values

```
eggs_consumed       = total_eggs − eggs_sold
savings             = eggs_consumed × store_price_per_egg
earnings            = income (actual cash received)
total_flock_value   = savings + earnings
net_impact          = total_flock_value − expenses
your_cost_per_dozen = (expenses − earnings) ÷ eggs_consumed × 12
```

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| No income records | `eggs_sold = 0`, `earnings = 0`, all eggs are savings |
| Income without egg count | Treat as pure cash earnings, don't subtract from `eggs_consumed` |
| `eggs_sold > total_eggs` (sold from stockpile) | Clamp `eggs_consumed` to 0, `savings = 0` |
| Zero eggs in period | Hero shows $0.00, hide cost per dozen |
| Zero expenses in period | `your_cost_per_dozen = 0`, show "Your eggs cost you nothing this period" |
| Zero eggs consumed | Hide "Your Cost per Dozen" (division by zero) |

---

## User Stories

**As a** keeper who eats all my eggs, **I want to** see what my eggs would have cost at the store **so that** I know whether my flock is saving me money.

**As a** keeper who sells surplus eggs, **I want to** see my actual sale income alongside the value of eggs I kept **so that** I understand my total financial picture.

**As any** keeper, **I want to** see a simple answer to "am I coming out ahead?" **so that** the financial tab is meaningful regardless of whether I sell eggs.

---

## Design Decisions

### No user-type toggle

Most keepers are hybrids — they eat most eggs, sell a few, give some away. A consumer/seller toggle forces a false choice. Same math, same screen, same layout for everyone. If income is zero, income rows simply don't appear. If income exists, it enriches the picture.

### Consumed vs. sold eggs

The assumption: users wanted to eat what they kept, and sold the rest. Eggs consumed are valued at store price (savings). Eggs sold are valued at actual sale price (earnings). This avoids both double-counting and the false equivalence of valuing sold eggs at store price.

### User-set retail price

Egg prices vary wildly by region and quality tier (conventional vs. pasture-raised vs. organic). The user sets their own reference price once in Settings. Default: $4.50/dozen.

### Neutral tone for negative numbers

Negative Net Impact is displayed in muted dark text, never red. Most keepers will be in the red after any large purchase — that's a normal financial fact, not an error. Positive numbers get teal (the app's accent color). The label "Net Impact" works in both directions without judgment.

### Consolidated single screen

The old Expenses tab and Income tab merge into a single "Value" tab. One summary, one list, one FAB. The Category dropdown handles filtering between expense categories and income entries.

### Cost per dozen, not per egg

Chicken keepers think in dozens. "$4.11/doz vs $6.00 store" is immediately meaningful. It also maps to how they'd price eggs for sale.

---

## Tab Rename

Bottom navigation label changes from **"Expenses"** to **"Value"** with the existing $ icon.

---

## Task 1: Retail Price Setting

### SharedPreferences

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `retail_egg_price_per_dozen` | `double` | `4.50` | USD, user-configurable |

### Provider

```dart
// lib/providers/egg_value_provider.dart

final retailPricePerDozenProvider = StateProvider<double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getDouble('retail_egg_price_per_dozen') ?? 4.50;
});

Future<void> setRetailPricePerDozen(WidgetRef ref, double price) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setDouble('retail_egg_price_per_dozen', price);
  ref.invalidate(retailPricePerDozenProvider);
}
```

### Settings UI

Add to Settings screen under an "Egg Value" section:

```
Egg Value
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Store egg price (per dozen)

  [$] [4.50]

  What would you pay for a dozen eggs at the
  store? Used to calculate the value of your
  flock's production.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- Number input with currency formatting
- Min: $0.50, Max: $20.00
- Validation: must be > 0

### Acceptance Criteria

- [ ] Setting appears in Settings screen
- [ ] Default value is $4.50
- [ ] Persists across app restarts
- [ ] Changing value invalidates dependent providers
- [ ] Input validates as positive number within range

---

## Task 2: Value Provider & Model

### File: `lib/providers/egg_value_provider.dart`

```dart
final retailPricePerEggProvider = Provider<double>((ref) {
  return ref.watch(retailPricePerDozenProvider) / 12.0;
});

final flockValueProvider = FutureProvider.family<FlockValue, DateRange>(
  (ref, range) async {
    final totalEggs = await ref.watch(
      eggCountByDateRangeProvider(range).future,
    );
    final pricePerEgg = ref.watch(retailPricePerEggProvider);
    final retailPerDozen = ref.watch(retailPricePerDozenProvider);
    final totalExpenses = await ref.watch(
      totalExpensesProvider(range).future,
    );
    final totalIncome = await ref.watch(
      totalIncomeProvider(range).future,
    );
    final eggsSold = await ref.watch(
      eggsSoldByDateRangeProvider(range).future,
    );

    return FlockValue(
      totalEggs: totalEggs,
      eggsSold: eggsSold,
      storePerEgg: pricePerEgg,
      storePerDozen: retailPerDozen,
      expenses: totalExpenses,
      income: totalIncome,
    );
  },
);
```

### File: `lib/models/flock_value.dart`

```dart
class FlockValue {
  final int totalEggs;
  final int eggsSold;
  final double storePerEgg;
  final double storePerDozen;
  final double expenses;
  final double income;

  const FlockValue({
    required this.totalEggs,
    required this.eggsSold,
    required this.storePerEgg,
    required this.storePerDozen,
    required this.expenses,
    required this.income,
  });

  /// Eggs the keeper consumed (not sold)
  int get eggsConsumed => (totalEggs - eggsSold).clamp(0, totalEggs);

  /// Value of consumed eggs at store price
  double get savings => eggsConsumed * storePerEgg;

  /// Actual cash from sales
  double get earnings => income;

  /// Total financial value the flock produced
  double get totalFlockValue => savings + earnings;

  /// The bottom line: flock value minus what you spent
  double get netImpact => totalFlockValue - expenses;

  /// What you effectively pay per dozen eggs you eat,
  /// after offsetting expenses with sale income.
  /// Returns null if no eggs consumed.
  double? get yourCostPerDozen =>
      eggsConsumed > 0 ? (expenses - earnings) / eggsConsumed * 12 : null;

  /// Is the flock providing net positive value?
  bool get isPositive => netImpact >= 0;

  /// Does this period have any income records?
  bool get hasIncome => income > 0;
}
```

### New Provider Needed

```dart
/// Sum of egg_count from income records where egg_count is non-null.
final eggsSoldByDateRangeProvider = FutureProvider.family<int, DateRange>(
  (ref, range) async {
    final repository = ref.read(incomeRepositoryProvider);
    return repository.getEggsSoldByDateRange(range.start, range.end);
  },
);
```

### Acceptance Criteria

- [ ] `eggsConsumed` correctly subtracts sold eggs from total
- [ ] `savings` uses store price only for consumed eggs
- [ ] `earnings` uses actual income, not imputed value
- [ ] `totalFlockValue` = savings + earnings
- [ ] `netImpact` = totalFlockValue − expenses
- [ ] `yourCostPerDozen` offsets expenses with earnings
- [ ] Income records without egg_count don't reduce eggs_consumed
- [ ] `eggs_sold > total_eggs` clamps consumed to 0
- [ ] Responds to retail price changes
- [ ] Responds to selected flock filter

---

## Task 3: Value Tab Screen

### File: `lib/screens/value/value_screen.dart` (replaces expense_list_screen.dart)

### Layout

```
┌─────────────────────────────────────────┐
│  Egg Value                              │  ← screen title
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 🏠 Flock     All Flocks      ▼ │    │  ← hidden for single-flock users
│  └─────────────────────────────────┘    │
│  ┌──────────────┐ ┌────────────────┐    │
│  │ Period       │ │ Category       │    │
│  │ All Time   ▼ │ │ All          ▼ │    │
│  └──────────────┘ └────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │         Egg Value               │    │  ← hero card
│  │         $193.50                 │    │  ← large, teal
│  │    387 eggs @ $6.00/dz          │    │  ← muted subtitle
│  └─────────────────────────────────┘    │
│                                         │
│  ┌──────────────┐ ┌────────────────┐    │
│  │ Your Cost    │ │ Net Impact     │    │  ← 2-up derived metrics
│  │ per Dozen    │ │                │    │
│  │ $4.11        │ │ +$20.75        │    │  ← teal if positive
│  │ vs $6.00     │ │ vs buying      │    │  ← muted dark if negative
│  │ store        │ │ at store       │    │
│  └──────────────┘ └────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 🛠 Fancy chicken toys           │    │
│  │ Mar 3, 2026              $70.00 │    │  ← expense row
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ 🌿 50lb layer pellets          │    │
│  │ Feb 7, 2026              $35.00 │    │  ← expense row
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ 🥚 Dozen to neighbor           │    │
│  │ Feb 6, 2026  ⌈12 eggs⌉  +$6.00│    │  ← income row, teal
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ 🌿 Mealworm treats             │    │
│  │ Feb 2, 2026              $10.00 │    │
│  └─────────────────────────────────┘    │
│                                         │
│                                 [+]     │  ← speed-dial FAB
└─────────────────────────────────────────┘
```

### Filters

- **Flock** — full-width dropdown, hidden for single-flock users
- **Period** — left half: This Month, Last 90 Days, This Year, All Time
- **Category** — right half: All, Feed, Bedding, Supplies, Medical, Equipment, Income

Category behavior:
- **All** — shows expenses and income together, chronological
- **Feed / Bedding / etc.** — shows only that expense category, income rows hidden
- **Income** — shows only income entries

### Hero Card

Always shows `totalFlockValue` for the selected period, regardless of category filter. The hero answers the overall question, not the filtered view.

- Label: "Egg Value" (small, muted)
- Amount: large, teal, bold
- Subtitle: "XXX eggs @ $X.XX/dz" (muted)

### Derived Metrics Row (2-up cards)

**Left card: "Your Cost per Dozen"**
- Amount: `(expenses − earnings) ÷ eggs_consumed × 12`
- Subtitle: "vs $X.XX store" (user's retail price)
- Hidden when zero eggs consumed in period

**Right card: "Net Impact"**
- Amount: `totalFlockValue − expenses`
- Positive: teal, show as "+$XX.XX"
- Negative: muted dark text (not red), show as "$XX.XX"
- Subtitle: "vs buying at store"

### List Items

Single chronological list, most recent first.

**Expense rows:**
- Category icon (existing colored circles)
- Description
- Date
- Amount right-aligned, standard dark text

**Income rows:**
- Egg/income icon (teal tinted circle)
- Description
- Date + egg count badge if available (e.g., "Feb 6, 2026 · 12 eggs")
- Amount right-aligned in teal, prefixed with "+"

### Speed-Dial FAB

- Default state: single teal "+" button
- On tap: expands to two mini-FABs:
  - **Expense** — opens existing expense form
  - **Income** — opens existing Record Sale form
- Tap outside to collapse

### Edge Cases

| Scenario | Display |
|----------|---------|
| Zero eggs, zero expenses | "No activity this period" |
| Zero eggs, some expenses | Hero shows $0.00, Net Impact = −expenses, hide cost per dozen |
| Some eggs, zero expenses | Hero shows egg value, Net Impact = full value, "Your eggs cost you nothing this period" |
| Zero eggs consumed (all sold) | Hide "Your Cost per Dozen" |
| No income ever logged | Income rows never appear, all eggs valued at store price |
| List empty after category filter | "No [category] expenses this period" |

### Acceptance Criteria

- [ ] Tab labeled "Value" in bottom nav
- [ ] Flock dropdown hidden for single-flock users
- [ ] All three filters (flock, period, category) work correctly
- [ ] Hero card always shows total flock value for full period (unaffected by category filter)
- [ ] Derived metrics update with all filters
- [ ] Your Cost per Dozen hidden when zero eggs consumed
- [ ] Net Impact uses teal for positive, muted dark for negative (never red)
- [ ] List shows mixed expenses + income in chronological order
- [ ] Category "Income" shows only income rows
- [ ] Category expense filters hide income rows
- [ ] Income rows visually distinct (teal amount, + prefix, egg count badge)
- [ ] Speed-dial FAB expands to Expense / Income options
- [ ] Tapping income row navigates to edit sale
- [ ] Tapping expense row navigates to edit expense

---

## Task 4: Home Screen Glanceable Line

### File: `lib/screens/home/home_screen.dart`

A single line below the stat cards row, above recent activity.

### Display

Positive Net Impact:
```
🥚 Your eggs saved you $21 this month
```

Negative Net Impact:
```
🥚 Your flock cost $5 beyond egg value this month
```

Zero eggs in period:
```
(line hidden entirely)
```

### Behavior

- Uses `flockValueProvider` with current month
- Rounds to whole dollar
- Tapping navigates to Value tab
- Respects flock filter
- Updates when eggs, expenses, or income change

### Acceptance Criteria

- [ ] One-line summary on home screen
- [ ] Neutral language for both positive and negative
- [ ] Tapping navigates to Value tab
- [ ] Hidden when no eggs in current period

---

## Task 5: Analytics Integration (Optional)

### File: `lib/screens/analytics/analytics_screen.dart`

### Monthly Net Impact Trend

Bar chart showing net impact per month over last 6–12 months.
- Bars above zero: teal
- Bars below zero: muted warm tone (not red)
- X-axis: month labels
- Y-axis: dollar amounts

### Cumulative View

Toggle to show running total of net impact over time. The line crossing from negative to positive territory is the break-even moment — a genuine milestone worth celebrating.

### Acceptance Criteria

- [ ] Monthly bar chart on analytics screen
- [ ] Teal/muted coloring for positive/negative
- [ ] Cumulative toggle shows running total
- [ ] Respects flock filter
- [ ] Only shows with 2+ months of data

---

## Achievement Tie-In

| Badge | Name | Criteria |
|-------|------|---------|
| 💰 | **Beat the Store** | Net Impact positive for a calendar month |
| ⚖️ | **Break Even** | Cumulative lifetime Net Impact crosses from negative to positive |

---

## Data Requirements

### No schema changes

| Source | Used For |
|--------|----------|
| `egg_logs.count` | Total egg count by period |
| `expenses.amount` | Total expenses by period |
| `income.amount` | Actual sale income by period |
| `income.egg_count` | Eggs sold (to separate consumed from sold) |
| `retail_egg_price_per_dozen` (SharedPreferences) | Store comparison price |

### Providers Needed

| Provider | Status | Notes |
|----------|--------|-------|
| `retailPricePerDozenProvider` | New | SharedPreferences |
| `retailPricePerEggProvider` | New | Derived from above |
| `flockValueProvider` | New | Core calculation |
| `eggsSoldByDateRangeProvider` | New | Sum of income.egg_count |
| `eggCountByDateRangeProvider` | Should exist | From egg provider |
| `totalExpensesProvider(DateRange)` | Should exist | From expense provider |
| `totalIncomeProvider(DateRange)` | May need creation | From income provider |
| `selectedFlockProvider` | Exists | For filtering |

---

## Implementation Order

1. **Task 1**: Retail price setting (foundation)
2. **Task 2**: Value provider and model (core math)
3. **Task 3**: Value tab screen (primary UI — replaces old Expenses/Income tabs)
4. **Task 4**: Home screen line (glanceable summary)
5. **Task 5**: Analytics trend (optional, adds depth)

Estimated effort: 4–5 hours for Tasks 1–4, +2 hours for Task 5.

---

## Future Enhancements (Out of Scope)

- **Regional price defaults**: Auto-suggest retail price based on location
- **Price history tracking**: Update retail price over time, use historical prices for past months
- **Per-category breakdowns**: "Your feed costs are X per dozen, supplies are Y per dozen"
- **Amortized one-time costs**: Spread coop build cost over N years for more accurate monthly picture
- **Comparison benchmarks**: "You're in the top 30% of keepers for cost efficiency" (requires aggregate data, conflicts with privacy-first model)

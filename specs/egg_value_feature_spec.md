# Flock Manager — Egg Value & Savings Feature Spec

## Overview

Replace the profit/loss framing with a universal "egg value" metric that answers "is my flock worth it financially?" for every type of keeper — consumers who eat their eggs, sellers, and the majority who do both.

---

## Core Concept

Every egg has a retail-equivalent value: what the keeper would have paid at the store. This single idea unifies the financial picture for all users without requiring a mode toggle or per-egg disposition tracking.

**Egg Production Value** = `total_eggs × (retail_price_per_dozen / 12)`

**Net Savings** = `Egg Production Value − Expenses`

A positive number means the flock is "beating the store." A negative number is the true hobby cost beyond what the eggs are worth. Sellers who record income get a bonus comparison, but the core metric works even if income is never logged.

---

## User Stories

**As a** keeper who eats all my eggs, **I want to** see what my eggs would have cost at the store **so that** I know whether my flock is saving me money.

**As a** keeper who sells some eggs, **I want to** see both my actual income and the retail value of all eggs produced **so that** I can evaluate my pricing and overall financial picture.

**As any** keeper, **I want to** see a simple "am I beating the store?" answer **so that** the financial tab is meaningful even if I never log income.

---

## Design Decisions

### No user-type toggle

Most keepers are hybrids — they eat most eggs, sell a few, give some away. A consumer/seller toggle forces a false choice. Instead, show the same data to everyone. If income is zero, income lines naturally fade from relevance. If income exists, it enriches the picture. Same math, same screen.

### Per-egg disposition not tracked

We do not track whether individual eggs were sold, consumed, or given away. Every egg gets the same retail-equivalent value. This avoids adding friction to the egg logging flow (which must stay fast) and keeps the model simple. Sellers who want precise per-sale tracking can use the existing income feature.

### User-set retail price

Egg prices vary wildly by region and by what the user would actually buy (conventional vs. pasture-raised vs. organic). A hardcoded national average would be wrong for most people. The user sets their own reference price once.

---

## Task 1: Retail Price Setting

### SharedPreferences

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `retail_egg_price_per_dozen` | `double` | `4.50` | USD, user-configurable |

### Provider

```dart
// lib/providers/settings_provider.dart (or egg_value_provider.dart)

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

Add to Settings screen under a "Financial" or "Egg Value" section:

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
- Min: $0.50, Max: $20.00 (reasonable guardrails)
- Validation: must be > 0

### Acceptance Criteria

- [ ] Setting appears in Settings screen
- [ ] Default value is $4.50
- [ ] Persists across app restarts
- [ ] Changing value invalidates dependent providers
- [ ] Input validates as positive number within range

---

## Task 2: Egg Value Provider

### File: `lib/providers/egg_value_provider.dart` (new)

```dart
/// Value of a single egg at the user's retail reference price.
final retailPricePerEggProvider = Provider<double>((ref) {
  final dozenPrice = ref.watch(retailPricePerDozenProvider);
  return dozenPrice / 12.0;
});

/// Egg production value for a date range.
/// This is what the eggs would have cost at the store.
final eggProductionValueProvider = FutureProvider.family<double, DateRange>(
  (ref, range) async {
    final eggCount = await ref.watch(
      eggCountByDateRangeProvider(range).future,
    );
    final pricePerEgg = ref.watch(retailPricePerEggProvider);
    return eggCount * pricePerEgg;
  },
);

/// Net savings for a date range.
/// Positive = beating the store. Negative = hobby cost beyond egg value.
final netSavingsProvider = FutureProvider.family<NetSavings, DateRange>(
  (ref, range) async {
    final eggValue = await ref.watch(
      eggProductionValueProvider(range).future,
    );
    final totalExpenses = await ref.watch(
      totalExpensesProvider(range).future,
    );
    final totalIncome = await ref.watch(
      totalIncomeProvider(range).future,
    );

    return NetSavings(
      eggProductionValue: eggValue,
      totalExpenses: totalExpenses,
      totalIncome: totalIncome,
    );
  },
);
```

### Model

```dart
// lib/models/net_savings.dart (new)

class NetSavings {
  final double eggProductionValue;
  final double totalExpenses;
  final double totalIncome;

  const NetSavings({
    required this.eggProductionValue,
    required this.totalExpenses,
    required this.totalIncome,
  });

  /// Core metric: are your eggs worth more than you spent?
  double get netSavings => eggProductionValue - totalExpenses;

  /// Cost per egg from actual expenses (existing metric, kept)
  /// Returns null if no eggs in period.
  double? costPerEgg(int eggCount) =>
      eggCount > 0 ? totalExpenses / eggCount : null;

  /// Retail value per egg (for comparison display)
  double retailPerEgg(double retailPerDozen) => retailPerDozen / 12.0;

  /// For sellers: how does actual income compare to retail value?
  double get incomeVsRetailDelta => totalIncome - eggProductionValue;

  /// Is the user beating the store?
  bool get isBeatingTheStore => netSavings >= 0;
}
```

### Acceptance Criteria

- [ ] Egg production value calculated correctly from egg count × retail price
- [ ] Net savings = egg value − expenses
- [ ] Responds to retail price changes (provider invalidation)
- [ ] Responds to selected flock filter
- [ ] Handles zero eggs and zero expenses gracefully
- [ ] Income data included when available, ignored when absent

---

## Task 3: Expense Tab Summary

### File: `lib/screens/expenses/expense_list_screen.dart`

Rework the summary header at the top of the expenses tab. This is the primary home for the detailed financial picture.

### Summary Layout

```
┌─────────────────────────────────────────┐
│  This Month                     [▼]     │  ← period selector (existing)
│                                         │
│  🥚 Egg Value          $56.25           │  ← total eggs × retail price
│     150 eggs × $4.50/dz                 │
│                                         │
│  📉 Expenses           $38.00           │  ← existing total
│                                         │
│  ─────────────────────────────          │
│  ✅ Net Savings        +$18.25          │  ← egg value − expenses
│     Beating the store by $18.25!        │
│                                         │
│  Your cost: $0.25/egg                   │  ← existing metric, kept
│  Store cost: $0.38/egg                  │  ← new comparison point
└─────────────────────────────────────────┘
```

When net savings is negative:
```
│  ⚠️ Net Cost           −$12.50          │
│     Your eggs cost $12.50 more          │
│     than buying at the store            │
```

When income has been logged (seller/mixed):
```
│  🥚 Egg Value          $56.25           │
│     150 eggs × $4.50/dz                 │
│                                         │
│  💵 Income             $24.00           │
│     from egg sales                      │
│                                         │
│  📉 Expenses           $38.00           │
│                                         │
│  ─────────────────────────────          │
│  ✅ Net Savings        +$18.25          │
│     (egg value − expenses)              │
│                                         │
│  💰 Cash Flow          −$14.00          │
│     (income − expenses)                 │
```

The income and cash flow lines only appear if the user has logged any income in the selected period. No clutter for pure consumers.

### Edge Cases

| Scenario | Display |
|----------|---------|
| Zero eggs, zero expenses | "No activity this period" |
| Zero eggs, some expenses | Show expenses only, net = −expenses, omit cost-per-egg |
| Some eggs, zero expenses | Show egg value, net = full egg value, "Your eggs cost you nothing this month!" |
| No income ever logged | Income and cash flow lines hidden |
| Income logged in other periods but not this one | Income line shows $0.00 (user has established they sell sometimes) |

### Acceptance Criteria

- [ ] Summary shows egg value, expenses, and net savings
- [ ] Net savings colored green (positive) or amber/red (negative)
- [ ] Cost-per-egg comparison (yours vs. store) displayed
- [ ] Income section appears only when user has income history
- [ ] Period selector applies to all values
- [ ] Flock filter applies to all values
- [ ] Edge cases handled per table above

---

## Task 4: Home Screen Glanceable Line

### File: `lib/screens/home/home_screen.dart`

Add a single financial summary line to the home screen. This is not a full breakdown — just enough to answer "how am I doing?" at a glance.

### Display

When beating the store:
```
🥚 Your eggs saved you $18 this month
```

When not beating the store:
```
🥚 Your eggs cost $12 more than store-bought this month
```

When no eggs this period:
```
(omit the line entirely — don't show "$0 saved")
```

### Placement

Below the existing stat cards row, above recent activity. Tapping the line navigates to the expenses tab for the full breakdown.

### Implementation

- Uses the same `netSavingsProvider` with current month as the date range
- Rounds to whole dollar for glanceability
- Responds to flock filter

### Acceptance Criteria

- [ ] One-line savings summary on home screen
- [ ] Positive framing for savings, honest framing for costs
- [ ] Tapping navigates to expenses tab
- [ ] Hidden when no eggs in current period
- [ ] Updates when egg logs or expenses change

---

## Task 5: Analytics Integration (Optional)

### File: `lib/screens/analytics/analytics_screen.dart`

Add a savings trend to the analytics screen for users with enough history.

### Monthly Savings Trend Chart

A simple bar or line chart showing net savings per month over the last 6–12 months. Bars above zero are green (beating the store), bars below are red/amber.

This is where the long-term story gets interesting: early months are deep negative (coop build, initial supplies), then the line climbs as one-time costs amortize. Watching it cross zero is a genuine milestone.

### Cumulative View

An optional toggle to show cumulative savings over time — "lifetime, have my chickens paid for themselves?" This is a running total of monthly net savings. The crossover point from negative to positive territory is the true break-even moment.

### Acceptance Criteria

- [ ] Monthly savings bar chart on analytics screen
- [ ] Green/red coloring for positive/negative months
- [ ] Cumulative toggle shows running total
- [ ] Respects flock filter
- [ ] Only shows with 2+ months of data (otherwise not meaningful)

---

## Achievement Tie-In

Two natural achievements from `achievements_ideas.md` map directly to this feature:

| Badge | Name | Updated Criteria |
|-------|------|-----------------|
| 💰 | **Beat the Store** | Net savings positive for a calendar month |
| ⚖️ | **Break Even** | Cumulative lifetime net savings crosses from negative to positive |

---

## Data Requirements

### No schema changes

All data comes from existing tables and the one new SharedPreferences key:

| Source | Used For |
|--------|----------|
| `egg_logs.count` | Total egg count by period |
| `expenses.amount` | Total expenses by period |
| `income.amount` | Total income by period (when present) |
| `retail_egg_price_per_dozen` (prefs) | Retail reference price |

### Existing providers needed

| Provider | Exists? | Notes |
|----------|---------|-------|
| `eggCountByDateRangeProvider` | Should exist | From egg provider |
| `totalExpensesProvider(DateRange)` | Should exist | From expense provider |
| `totalIncomeProvider(DateRange)` | May need creation | Income tracking may be incomplete |
| `selectedFlockProvider` | Exists | For filtering |

---

## Implementation Order

1. **Task 1**: Retail price setting (foundation — everything depends on this)
2. **Task 2**: Egg value provider and model (core calculation)
3. **Task 3**: Expense tab summary (primary UI, most detailed)
4. **Task 4**: Home screen line (glanceable summary)
5. **Task 5**: Analytics trend (optional, adds depth with history)

Estimated effort: 3–4 hours for Tasks 1–4, +2 hours for Task 5.

---

## Future Enhancements (Out of Scope)

- **Regional price defaults**: Auto-suggest retail price based on location
- **Price history tracking**: Update retail price over time, use historical prices for past months
- **Per-category breakdowns**: "Your feed costs are X per egg, supplies are Y per egg"
- **Amortized one-time costs**: Spread coop build cost over 5 years for more accurate monthly picture
- **Comparison benchmarks**: "You're in the top 30% of keepers for cost efficiency" (requires anonymized aggregate data, conflicts with privacy-first model)
- **Per-egg disposition tracking**: Mark eggs as sold/consumed/gifted for precise accounting (adds friction to logging, unlikely worth it)

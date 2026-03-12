# Financial Forecasting — Data Review & Research Brief

## What Data We Have

### Egg Production (already forecasted)
- Daily egg counts per flock/bird, going back to app install
- Per-hen laying rates by month (eggs/hen/day)
- Daylight-adjusted seasonal curves by latitude
- Active bird count over time (flock size history)
- Egg forecast provider already outputs: projected week/month/year, monthly breakdown

### Expenses
- Individual transactions with date, amount, category, optional flock assignment
- **Categories**: Feed, Bedding, Supplies, Medical, Equipment, Other
- **Recurring flag**: `isRecurring` bool + `recurringInterval` (weekly/monthly) — stored on the record but not enforced or auto-generated
- Daily expense totals available via `getDailyExpenses(start, end)`
- Category breakdowns available via `getExpensesByCategories(start, end)`
- Flock-level filtering supported

### Income
- Individual transactions with date, amount, optional description
- Optional `eggCount` field (eggs sold in that transaction) — allows deriving sale price per egg
- Flock-level filtering supported
- Daily income totals available via `getDailyIncome(start, end)`

### Computed Metrics (existing)
- **Cost per egg**: totalExpenses / totalEggCount
- **Net cost per dozen**: (totalExpenses - totalIncome) / eggsConsumed × 12
- **Cash flow**: totalIncome - totalExpenses
- **Egg production value**: (eggsConsumed × retailPrice) + actualSaleIncome
- **Net savings**: eggProductionValue - totalExpenses
- **Break-even price**: totalExpenses / totalEggsSold
- **Retail price per dozen**: user-configured (default $4.50)

### What We Don't Have
- No explicit recurring expense scheduling (the flag exists but expenses aren't auto-generated)
- No seasonal cost patterns tracked separately (feed consumption varies with temperature, but we'd have to infer this from expense history)
- No per-bird cost allocation
- No inventory tracking (feed bags on hand, etc.)
- No market price feeds (local egg prices, feed prices)

---

## The Forecasting Challenge

Financial forecasting for a backyard flock is fundamentally different from egg forecasting:

**Egg production** is driven by biology — daylight hours, breed, age, season. It's relatively predictable with a good model.

**Expenses** are driven by human behavior — when you buy feed, whether you upgrade the coop, vet visits. They're lumpy, irregular, and category-dependent:
- **Feed**: Semi-predictable. Correlates loosely with flock size and season (birds eat more in winter). Purchased in bulk at irregular intervals.
- **Bedding**: Periodic. Seasonal (more frequent changes in wet months).
- **Medical**: Unpredictable. Sporadic, high-variance.
- **Equipment**: Unpredictable. Capital expenditures, one-time or rare.
- **Supplies**: Mixed. Some recurring (oyster shell, grit), some one-off.

**Income** depends on the user's selling behavior — do they sell eggs? How often? At what price? Some users never sell; others sell regularly.

---

## Questions for Research

1. **What forecasting approach works best for small, lumpy, category-heterogeneous expense data?** We might have 50-200 expense records across 1-3 years. Classical time series (ARIMA, exponential smoothing) may be overkill or underperform with so few data points.

2. **Should we forecast by category or in aggregate?** Feed is ~60-80% of costs and somewhat predictable. Medical/equipment are rare spikes. Mixing them may dilute signal.

3. **How should recurring expenses factor in?** We have a recurring flag but don't auto-generate future entries. Should the forecast treat flagged-recurring expenses as guaranteed future costs, or just use the historical pattern?

4. **How do we handle the "lumpiness" problem?** A user buys a $40 bag of feed every 3 weeks. In any given month, they might spend $40 or $80. Annualizing smooths this, but monthly forecasts will look wrong.

5. **Income forecasting**: For users who sell eggs, income correlates with egg production (which we can already forecast). Should income forecast simply be: `forecastEggs × historicalPricePerEgg × historicalSellRate`?

6. **What's the simplest approach that's still useful?** The app is for backyard chicken keepers, not financial analysts. A rough "you'll spend about $X this year" might be more valuable than a precise monthly breakdown.

---

## Research Prompt

I'm building financial forecasting for a backyard chicken flock management app. I need help designing the forecasting methodology — not writing code, just the approach.

**Context:**
- This is a mobile app for hobbyist chicken keepers (not commercial farms)
- We already have egg production forecasting working (daylight-based seasonal model with per-hen normalization)
- Now I need to forecast expenses, income, and derived metrics (cash flow, cost per egg, break-even timeline)
- The app has 1-3 years of historical data at most
- Typical user has 4-15 hens

**Available data:**
- Egg production forecast (monthly projected eggs for the calendar year, per-hen daily rates)
- Expense history: individual transactions with date, amount, category (Feed/Bedding/Supplies/Medical/Equipment/Other), optional recurring flag (weekly/monthly), optional flock assignment
- Income history: individual transactions with date, amount, optional egg count sold
- Active bird count over time
- User-configured retail egg price (for "value of eggs consumed" calculations)

**Expense characteristics:**
- Feed is the dominant cost (~60-80%), purchased in irregular bulk intervals (e.g., $40 bag every 2-4 weeks)
- Bedding is periodic, somewhat seasonal
- Medical and Equipment are rare, high-variance spikes
- Supplies are mixed recurring/one-off
- Total dataset is small: maybe 50-200 expense records over 1-3 years
- Data is "lumpy" — monthly totals vary significantly due to purchase timing, not actual consumption changes

**Income characteristics:**
- Many users never sell eggs (income = $0 always)
- Selling users have irregular sales tied to egg surplus
- Each income record optionally tracks eggs sold, allowing price-per-egg derivation

**What I need help with:**

1. **Expense forecasting approach**: What method works best for small, lumpy, category-heterogeneous data? Consider:
   - Category-level vs. aggregate forecasting
   - How to smooth purchase timing lumpiness (a user spending $40 on feed every 3 weeks shouldn't see wildly different monthly forecasts)
   - How to handle rare spike categories (medical, equipment) — include or exclude from forecasts?
   - Whether to use the recurring expense flag as a "guaranteed future cost" or just rely on historical patterns
   - Seasonal variation in feed costs (birds eat more in winter)
   - How flock size changes should scale expense forecasts

2. **Income forecasting approach**: For users who sell eggs:
   - Should this simply be: `forecastEggs × historicalSellRate × historicalPricePerEgg`?
   - How to estimate sell rate (% of eggs sold vs. consumed) from sparse data
   - How to handle users who start or stop selling mid-history

3. **Derived metric forecasting**:
   - Projected cost per egg (forecast expenses / forecast eggs)
   - Projected break-even date (when cumulative income exceeds cumulative expenses)
   - Projected annual cash flow
   - "Months until you've saved vs. buying store eggs" — using the retail price comparison

4. **Practical considerations**:
   - What's the minimum data needed before showing a forecast? (We require 10 days of egg data for egg forecasting)
   - How to communicate uncertainty to the user without overwhelming them
   - Should we show monthly, quarterly, or just annual projections?
   - How to handle the cold-start problem (new user, 2 weeks of data)

5. **Simplicity constraint**: This is a hobby app. The approach should be understandable ("based on your spending over the last 6 months...") rather than a black box. Users should be able to look at the forecast and say "yeah, that makes sense" or "no, I'm not buying that coop upgrade again."

Please propose a concrete methodology I can implement, not a survey of options. Tell me what you'd build, why, and what the edge cases are.

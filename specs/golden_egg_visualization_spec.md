# Flock Manager — Golden Egg Visualization Spec

## Overview

A radial chart where **daylight hours form an egg-shaped boundary** and **egg production traces a curve inside it**. The egg shape is not a metaphor — plotting daylight hours radially with winter solstice at the bottom and summer at the top produces a literal egg shape due to the asymmetry of seasonal daylight curves. The shape varies by latitude: nearly round near the equator, elongated at northern latitudes.

Two views share the same egg boundary but tell different stories:

- **View A — Total Production**: Raw daily egg count. The practical view. "How many eggs am I getting?"
- **View B — Per-Bird Rate**: Eggs per bird per day. The diagnostic view. "How are my hens performing?"

---

## Design Philosophy

### The egg is daylight, not potential

The golden egg boundary represents a physical fact about where the user lives — hours of sunlight at their latitude across the year. It is **not** labeled as "maximum potential" or "theoretical ceiling." The correlation between daylight and laying rate is something the user discovers by looking at how their production curve tracks the egg wall. The chart presents facts; the user draws conclusions.

### Two questions, two views

Backyard chicken keepers ask two fundamentally different questions about production, and they're in tension:

1. **"How many eggs am I getting?"** — This is what matters for egg cartons, farmer's market sales, and cost-per-egg math. Flock size changes (predator loss, selling birds, buying pullets) show up honestly here. Lose 4 of 12 hens, the curve drops ~30%.

2. **"How are my hens performing?"** — This is what matters for flock health, breed evaluation, and diagnosing problems. The per-bird rate normalizes for flock size changes. Lose 4 hens but the remaining 8 are healthy? The curve barely moves.

Rather than trying to serve both with one chart (which muddies both), each gets its own view with a clean toggle. The egg boundary stays fixed in both — daylight doesn't care about your flock size.

### Forecast from your flock, not breed specs

Breed expectations (e.g., "Barred Rocks lay 250–280/year") are marketing generalizations that don't account for bird age, local climate, feed quality, coop lighting, stress, or dozens of other variables. Once a user has 90+ days of actual data, the app should forecast from **their own flock's observed performance**, not breed database averages.

### Progressive disclosure, not empty charts

A yearly radial with 2 weeks of data looks broken. The chart adapts its time scale as data accumulates so it's always useful, graduating to the full yearly egg view only when there's enough data to fill it meaningfully.

---

## Latitude & Daylight

### Egg Shape by Latitude

The egg boundary is computed from actual daylight hours using a standard solar declination formula. The shape varies meaningfully by latitude:

| Latitude | Location Example | Summer Peak | Winter Low | Shape |
|----------|-----------------|-------------|------------|-------|
| 25°N | Miami, FL | ~13.7h | ~10.6h | Nearly round |
| 35°N | Raleigh, NC | ~14.4h | ~9.8h | Mild oval |
| 39°N | Kansas City, MO | ~14.8h | ~9.4h | Classic egg |
| 45°N | Minneapolis, MN | ~15.5h | ~8.8h | Elongated |
| 50°N | Vancouver, BC | ~16.2h | ~8.1h | Tall oval |
| 55°N | Edmonton, AB | ~17.0h | ~7.3h | Very elongated |

At higher latitudes, both the egg and the production curve stretch dramatically — the seasonal swing is larger, so the visual correlation between daylight and production is more pronounced.

### Default Latitude

On first launch, **default to 39°N** (approximate center of the contiguous US, covers the majority of the backyard chicken keeping population). The user can adjust this in **Settings → Flock Preferences → Your Latitude**.

Latitude is stored as an integer (whole degrees are sufficient — the visual difference between 39° and 39.5° is imperceptible). The setting should include:

- A slider from 20°N to 60°N
- Current value displayed prominently
- Brief helper text: "Adjusts the daylight curve on your egg chart. Approximate is fine."
- 3–4 quick-pick buttons for common ranges: `Southern (25–32°)`, `Central (33–40°)`, `Northern (41–48°)`, `Far North (49–58°)`

Future enhancement: auto-detect from device location on first launch (with permission), round to nearest degree.

### 14-Hour Reference Line

A subtle dashed ring inside the egg at the 14-hour daylight threshold. This is the commonly cited minimum for peak laying stimulus in poultry science. It's not labeled as a "target" — it's reference information for keepers who know what it means, and invisible to those who don't.

Rendered as a thin dashed circle, low opacity, no label unless the user interacts with it.

---

## Radial Layout

### Orientation

- **Summer solstice (June) at top** — the widest point of the egg
- **Winter solstice (December) at bottom** — the narrowest point
- Months proceed clockwise: Jun → Jul → Aug → ... → May → Jun
- Each month occupies a 30° wedge

This orientation means the egg is "right side up" — wider at top, narrower at bottom — which reads naturally. It also means peak production (summer) is at the visual top, matching the intuition of "up = more."

### Month Labels

12 month abbreviations (Jan, Feb, Mar...) positioned just outside the egg boundary at each month's midpoint angle. The currently hovered month highlights bold.

### Season Markers

Small emoji at the four cardinal points as gentle orientation cues:

| Position | Angle | Emoji |
|----------|-------|-------|
| Top | 0° (June) | ☀️ |
| Right | 90° (September) | 🍂 |
| Bottom | 180° (December) | ❄️ |
| Left | 270° (March) | 🌱 |

---

## Data Curve

### Smooth Radial Line

Production data is plotted as a **smooth closed curve** inside the egg, not discrete wedges or bars. Each month maps to a point at its midpoint angle, with radius proportional to the value. Points are connected with Catmull-Rom spline interpolation for a smooth, organic shape.

The area between the center and the curve is filled with a low-opacity tint:
- View A (total): warm amber fill
- View B (per-bird): cooler brown fill

### Data Points

Small dots at each month's position on the curve. Styling varies by data source:

| Source | Dot Style | Meaning |
|--------|-----------|---------|
| Actual (15+ days recorded) | Solid filled, larger | Real data |
| Partial (<15 days recorded) | Solid filled, medium | Extrapolated from partial month |
| Forecast (daylight-matched) | Open circle (white fill, colored border) | Estimated from similar-daylight month |
| Forecast (last year) | Open circle | Carried from previous year's actual |

### Curve Continuity

The curve is drawn as a single continuous path through all 12 months. Forecast months use the same path — there is no visual break. The dot styling communicates which months are real vs projected. This keeps the shape clean and readable.

---

## Center Display

A clean circular area at the center of the radial chart. Contents vary by view:

**View A (Total Production):**
```
  projected
    599
  eggs/yr
```

**View B (Per-Bird Rate):**
```
  avg rate
    68%
  per bird
```

The projected total in View A updates as forecast months are replaced with actual data throughout the year.

---

## Flock Size Changes

### The Core Problem

If a keeper loses 4 of 12 hens to a predator in June:
- **Total output** drops ~30% overnight
- **Per-bird rate** stays roughly constant (surviving hens didn't change)

Raw production plotted against a daylight boundary conflates two variables. The two-view approach resolves this cleanly.

### View A Behavior

The total production curve drops honestly when flock size decreases and rises when birds are added (with a 2–3 week settling delay for new birds). This is the truthful picture of actual output.

### View B Behavior

The per-bird rate barely flinches on flock size changes. The denominator adjusts, so if 8 remaining hens maintain the same individual rate, the curve holds steady. This is the truthful picture of flock performance.

A temporary dip *does* appear when adding new birds (pullets may not lay immediately due to age, stress, transport), and that dip is real and meaningful — it shows the adjustment period.

### Flock Change Annotations

When the active bird count changes (birds marked as deceased, sold, given away, or new birds added), a small annotation appears on the curve at the corresponding month:

- Small circle with the new flock count inside
- Colored border (red-ish for losses, neutral for additions)
- Hover/tap reveals: date, previous count → new count, reason

These annotations appear in both views but are most informative in View A where they explain why the curve moved.

---

## Forecast Engine

### Stage 1: Daylight-Matched (< 1 year of data)

For months without recorded data, find the recorded month with the most similar average daylight hours. Scale that month's production rate by a dampened daylight ratio:

```
forecast_rate = matched_month_rate × (target_daylight / matched_daylight) ^ 0.6
```

The 0.6 exponent prevents overcorrection — a month with 20% more daylight won't produce 20% more eggs because the relationship isn't perfectly linear.

### Stage 2: Historical (1+ years of data)

For months with data from the previous year, use last year's actual values as the forecast. Real data always beats daylight estimation.

### Replacement

As real data arrives throughout the year, it replaces forecast values. The center projection updates accordingly. Open dots become solid dots month by month.

---

## Progressive Time Scales

The full yearly egg chart requires months of data to be useful. Before that threshold, the visualization adapts:

### Days 1–30: Daily Radial

A simple radial plot of individual days. Under 14 days, each day gets its own spoke. At 15+ days, aggregate to day-of-week averages with min/max range bands. No daylight overlay (daylight barely changes over a month). No forecast.

This stage exists to give new users something meaningful to look at immediately.

### Days 31–89: Weekly Buckets

Weekly aggregates arranged radially. A dashed ring shows the overall daily average as reference. A trend arrow appears at 4+ weeks of data. Still no daylight overlay.

### Days 90+: Yearly Egg Chart

The full golden egg. Daylight boundary appears. Forecast fills in missing months. This is the primary visualization described in this spec.

The transition between stages is automatic based on data volume. No user action required.

---

## Year-Over-Year Comparison

When the user has more than one year of data:

- **Current year** = solid curve (primary)
- **Previous year** = thin dashed curve behind it (ghost layer)

The spatial gap between the two curves *is* the year-over-year comparison. Where this year's line is outside last year's = improvement. Where it's inside = decline. No annotations needed — the visual relationship is self-explanatory.

Hover/tap on any month shows the delta explicitly:
- View A: "+23 eggs vs last year" or "−15 eggs"
- View B: "+4% lay rate" or "−2%"

---

## Tooltip / Hover Detail

Tapping (mobile) or hovering (tablet) on a month shows a detail panel below the chart:

**View A tooltip:**
| Field | Example |
|-------|---------|
| Month name | **July** |
| Source badge | `24d recorded` / `from last year` / `daylight-based` |
| Total eggs | **187** |
| Per day | **6.0** |
| vs last year (if available) | **+23** (green) or **−15** (red) |

**View B tooltip:**
| Field | Example |
|-------|---------|
| Month name | **July** |
| Source badge | (same as above) |
| Lay rate | **72%** |
| Avg flock size | **8** hens |
| Avg daylight | **14.8h** |
| vs last year rate | **+4%** (green) or **−2%** (red) |

If a flock size change occurred in the hovered month, an additional line appears:
```
⚠️ Flock 12→8: Lost 4 to predator
```

---

## Visual Design

### Color Palette

| Element | Color | Notes |
|---------|-------|-------|
| Egg fill | Radial gradient: #FFFCF0 → #FDF3D7 → #DDB94C | Golden, warm, natural |
| Egg stroke | #C49830 | Subtle border |
| Egg highlight | White radial gradient at ~35% from top-left | Subtle 3D sheen |
| View A curve | #A0522D (sienna) | Warm, distinct from egg |
| View A fill | #A06820 at 15% opacity | Light amber wash |
| View B curve | #6B4226 (dark brown) | Cooler, diagnostic feel |
| View B fill | #7B5A30 at 15% opacity | Muted wash |
| Previous year ghost | #8B7030, 35% opacity, dashed | Clearly secondary |
| Forecast dots | White fill, #C4A060 border | Open = uncertain |
| Actual dots | Solid curve color | Filled = confirmed |
| Flock change annotation | #C44020 border | Draws attention |
| 14h threshold | #B89030, 0.7px dashed, 40% opacity | Background reference |
| Month labels | #7C5A30 (actual) / #BBA870 (forecast) | Hierarchy by data quality |

### Shadow

A very subtle drop shadow beneath the egg (offset 2px down, 4px blur, black at 5% opacity). Creates gentle depth without looking heavy.

### Egg Shine

A radial gradient highlight (white at 50% opacity fading to transparent) positioned at upper-left ~35% of the egg. Gives a subtle 3D quality that reinforces the egg metaphor without being cartoonish.

---

## Settings Integration

### Settings → Flock Preferences

```
Your Latitude
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Adjusts the daylight curve on your egg chart.
Approximate is fine.

[========●===========] 39°N

[Southern] [Central] [Northern] [Far North]
  25-32°    33-40°    41-48°     49-58°
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Implementation:**
- Stored in SharedPreferences as `user_latitude` (int)
- Default: `39`
- Valid range: 20–60
- Exposed via a Riverpod provider: `userLatitudeProvider`
- Changing latitude invalidates the analytics/chart providers

---

## Data Requirements

### From Existing Schema (no changes needed)

| Source | Fields Used |
|--------|-------------|
| `egg_logs` | `date`, `flock_id`, `bird_id`, `count` |
| `birds` | `id`, `flock_id`, `status`, `status_date` |
| `flocks` | `id`, `name` |

### Derived Data (computed in provider)

| Metric | Calculation |
|--------|-------------|
| Monthly total eggs | `SUM(count) WHERE date IN month GROUP BY month` |
| Monthly days recorded | `COUNT(DISTINCT date) WHERE date IN month` |
| Monthly bird-days | `SUM(active_birds_on_date) for each date in month` |
| Per-bird rate | `total_eggs / bird_days` |
| Avg daylight | `AVG(daylight_hours(day_of_year, latitude)) for each date in month` |
| Flock size on date | Count of birds with `status = 'active'` on that date (using `status_date` for transitions) |

### Flock Size History

Reconstructed from the birds table: for any given date, count birds where `created_at <= date` and (`status = 'active'` or `status_date > date`). This gives the active bird count on any historical date without requiring a separate flock-size-events table.

Flock size change events are detected where the active count differs from the previous day.

---

## Provider Structure

```
lib/providers/
└── golden_egg_provider.dart

Providers:
  userLatitudeProvider          → int (from SharedPreferences)
  daylightCurveProvider         → List<double> (365 daylight values for latitude)
  monthlyAggregateProvider      → List<MonthAggregate> (current year)
  prevYearAggregateProvider     → List<MonthAggregate>? (previous year, if exists)
  forecastProvider              → List<MonthForecast> (12 months, actual + forecast)
  flockSizeHistoryProvider      → List<FlockSizeEvent>
  goldenEggChartDataProvider    → GoldenEggChartData (composed from above)
```

All providers should respect the selected flock filter. Changing the selected flock invalidates the chart data.

---

## Accessibility

- All data points reachable via screen reader with month name, value, and source
- Egg boundary described: "Daylight hours curve for [latitude] degrees north"
- View toggle announces current view on change
- Flock change annotations read as: "Flock size changed from 12 to 8 in June: lost 4 to predator"
- Color is never the sole indicator — dot style (filled vs open) and labels distinguish actual from forecast
- Sufficient contrast between curve and egg fill (verified against WCAG AA)

---

## Implementation Notes

### Flutter Rendering

The radial chart should be implemented as a `CustomPainter` widget. Key considerations:

- Use `Path` with cubic Bezier curves for smooth production curve
- Egg boundary as a pre-computed `Path` from daylight calculations
- `ClipPath` to constrain production curve and fill within egg boundary
- Cache the egg path — it only changes when latitude changes
- Cache daylight calculations — they're pure functions of day-of-year and latitude
- Repaint only when data or view selection changes

### Gesture Handling

- Detect which month wedge was tapped based on angle from center
- Show tooltip as an overlay or bottom panel (not inside the SVG)
- On mobile, first tap selects a month (shows tooltip), second tap on same month deselects
- Swipe left/right could toggle View A ↔ View B

### Performance

- Monthly aggregation queries should be indexed on `egg_logs.date` and `egg_logs.flock_id`
- Forecast computation is lightweight (12 iterations max)
- Flock size history reconstruction is the most expensive query — cache aggressively, invalidate only when birds table changes
- The full chart data provider should debounce recalculation on rapid data changes

---

## File Locations

```
lib/
├── providers/
│   └── golden_egg_provider.dart       (data aggregation, forecast, chart data)
├── screens/analytics/
│   └── golden_egg_screen.dart         (screen wrapper, view toggle, controls)
├── widgets/
│   ├── golden_egg_chart.dart          (CustomPainter radial chart)
│   ├── golden_egg_tooltip.dart        (month detail panel)
│   └── golden_egg_legend.dart         (legend/key below chart)
├── utils/
│   └── daylight_calculator.dart       (solar declination formula, pure functions)
└── screens/settings/
    └── settings_screen.dart           (add latitude preference)
```

---

## Out of Scope (Future)

- Interactive latitude detection from device GPS
- Pinch-to-zoom on specific months
- Landscape/tablet side-by-side View A + View B
- Export chart as shareable image
- Supplemental lighting simulation ("what if I added 2 hours of coop light?")
- Per-bird curves (individual radial lines within the egg, one per hen)
- Multi-year overlay (3+ years stacked)

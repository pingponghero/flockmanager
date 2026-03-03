# /lib/screens/

One subdirectory per feature area. Screens use `ConsumerWidget` /
`ConsumerStatefulWidget` and watch Riverpod providers for reactive state.
Async data renders via `.when(loading, error, data)`. List screens support
pull-to-refresh with provider invalidation.

## Directory map

```
screens/
├── home/           Dashboard: today's eggs, stats, spotlight bird, birthdays
├── birds/          Bird list, detail (3-tab), form, events timeline, health notes
├── eggs/           Egg log form, calendar-based history
├── expenses/       Expense + income forms, two-tab list with financial KPIs
├── medications/    Active treatments, history, searchable reference guide
├── analytics/      Production charts, trends, per-bird breakdown
├── flocks/         Flock list + form (icon/color picker)
├── breeds/         50 chicken breeds with search + filters
├── onboarding/     5-page first-run setup flow
└── settings/       Settings hub, achievements screen
```

## Key screens

- **home_screen.dart** — Dashboard with today's egg card, stat row, spark-line
  chart, flock spotlight, birthday callouts, withdrawal warning, latest
  achievement. Widgets split into `home/widgets/`.

- **bird_list_screen.dart** — Filterable list (gender, status, flock) with sort
  options (name, age, recently added). Pull-to-refresh.

- **bird_detail_screen.dart** — 3-tab profile: Info, Eggs, Health. Photo, stats
  row, status management. Tabs are in `birds/widgets/`.

- **egg_history_screen.dart** — Month-navigable calendar with daily egg counts
  and expandable per-day logs. Swipe-to-delete entries.

- **egg_log_screen.dart** — Log form: date, flock, bird (optional), count, size,
  quality, notes. Used for both create and edit.

- **expense_list_screen.dart** — Two tabs: Expenses (category filter, cost-per-egg)
  and Income (profit/loss summary). Date-range selector.

- **medication_screen.dart** — Three tabs: Active (withdrawal countdown), History
  (dismissible), Reference (searchable guide with legal status badges).

- **analytics_screen.dart** — Production charts with adaptive granularity
  (daily/weekly/monthly), trend indicators, per-bird stats, period selector.

- **onboarding_screen.dart** — 5-page flow: welcome → features → create flock →
  add bird → tour tips. Supports skip and resume.

- **settings_screen.dart** — Account (trial/premium), flock/bird management,
  theme/palette, notifications, data export/import, about.

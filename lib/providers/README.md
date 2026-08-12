# /lib/providers/

Each file covers one domain. Pattern: **AsyncNotifier** for DB-backed state with
mutations (add/update/delete), **computed providers** for derived data. Most
respect `selectedFlockIdProvider` via "ByFlock" variants. Family providers handle
parameterized lookups (by ID, by flock, by bird).

Settings providers (theme, trial, onboarding, notifications) persist via
SharedPreferences instead of SQLite.

## Files

- **flock_provider.dart** — `flocksProvider`, `selectedFlockIdProvider`,
  `selectedFlockProvider`, `archivedFlocksProvider`. Core flock selection that
  other domains filter against.

- **bird_provider.dart** — `birdsProvider`, `activeBirdsProvider`,
  `filteredBirdsProvider`, `birdsByFlockProvider`, `birdCountsByStatusProvider`,
  `upcomingBirthdaysProvider`. Status lifecycle (active/inactive/deceased/sold).

- **bird_status_event_provider.dart** — `birdStatusEventsProvider`,
  `flockSizeOnDateProvider`, `flockSizeHistoryProvider`. Tracks status changes
  over time; powers flock-size charts.

- **egg_provider.dart** — `eggLogsProvider`, `todayEggCountProvider` (+ ByFlock),
  `weekEggCountProvider`, `monthEggCountProvider`, `dailyEggCountsProvider`,
  `checkInStreakProvider`, `autoDistributeEggsProvider`. Largest provider file;
  covers logging, aggregations, streaks, and chart data.

- **expense_provider.dart** — `expensesProvider`, `incomeProvider`,
  `financeDateRangeProvider`, `costPerEggProvider`, `profitLossProvider`,
  `expensesByCategoryProvider`, `breakEvenPriceProvider`. Expense + income with
  date-range filtering and financial KPIs.

- **medication_provider.dart** — `medicationsProvider`, `activeMedicationsProvider`,
  `activeWithdrawalsProvider`, `healthNotesProvider`. Medication courses with
  withdrawal period tracking.

- **analytics_provider.dart** — `analyticsProvider`, `topLayersProvider`,
  `freeloadersProvider`, `productionTrendProvider`. Aggregates egg/bird data into
  dashboard summaries with adaptive chart granularity.

- **achievements_provider.dart** — `earnedAchievementsProvider`,
  `achievementProgressProvider`, `newlyUnlockedAchievementsProvider`. 50+
  achievements across 9 categories with incremental progress tracking.

- **notification_provider.dart** — `notificationSettingsProvider`. Medication
  reminders, withdrawal alerts, daily egg-log reminders.

- **trial_provider.dart** — `trialProvider`, `canEditProvider`. 14-day trial,
  premium IAP, read-only vs full-access gating.

- **onboarding_provider.dart** — `onboardingProvider`, `needsOnboardingProvider`.
  First-run flow state and resume support.

- **review_prompt_provider.dart** — `reviewPromptProvider`,
  `isEligibleForReviewPrompt`. Tracks app-open days and asks for a native store
  review after an achievement celebration, gated on engagement and a 90-day
  cooldown. State is "already prompted this session".

- **theme_provider.dart** — `themeProvider`, `themeModeProvider`. Color palette
  and light/dark mode via SharedPreferences.

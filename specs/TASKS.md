# Flock Manager — Implementation Tasks

Work through these in order. Each task is sized for one Claude Code session. Complete and test each before moving on.

---

## Phase 1: Foundation

### Task 1.1: Project Setup
```
Create a new Flutter project called "flock_manager" with the folder structure defined in CLAUDE.md.

Add these dependencies to pubspec.yaml:
- flutter_riverpod
- riverpod_annotation
- go_router
- sqflite
- path
- uuid
- shared_preferences
- intl
- freezed_annotation (dev)
- build_runner (dev)
- freezed (dev)

Create placeholder files for the folder structure but don't implement yet.
Run flutter pub get and flutter analyze to verify setup.
```

### Task 1.2: Theme and App Shell
```
Implement lib/app/theme.dart with:
- Light theme only for now
- Primary color: a warm earth tone (barn red or forest green)
- Clean, readable typography
- Card and input styling

Implement lib/main.dart with:
- ProviderScope wrapper
- MaterialApp.router setup
- Theme applied

Implement lib/app/router.dart with GoRouter:
- / -> HomeScreen (placeholder)
- /flocks -> FlockListScreen (placeholder)
- /birds -> BirdListScreen (placeholder)
- /settings -> SettingsScreen (placeholder)

Create placeholder screens that just show the route name.
Verify navigation works.
```

### Task 1.3: Database Setup
```
Implement lib/database/database_helper.dart:
- Singleton pattern
- Database initialization
- Version 1 schema from CLAUDE.md
- onCreate handler that creates all tables
- onUpgrade handler (empty for now, but structured for future migrations)

Implement lib/database/tables.dart:
- String constants for all CREATE TABLE statements
- Keep SQL centralized here

Test: App should launch without database errors.
Add a temporary button that inserts and reads a test flock to verify DB works.
```

### Task 1.4: Models
```
Create all model classes in lib/models/ using freezed:
- Flock
- Bird  
- EggLog
- Expense
- Income
- MedicationLog
- HealthNote

Each model needs:
- All fields from CLAUDE.md schema
- factory constructor
- toMap() method for SQLite
- fromMap() factory for SQLite
- Appropriate defaults (id generated via uuid, created_at via DateTime.now())

Create lib/models/enums.dart with all enums.

Run build_runner to generate freezed code.
Run flutter analyze.
```

---

## Phase 2: Flock & Bird Management

### Task 2.1: Flock Repository and Provider
```
Implement lib/repositories/flock_repository.dart:
- getAllFlocks()
- getFlockById(String id)
- insertFlock(Flock flock)
- updateFlock(Flock flock)
- archiveFlock(String id)
- deleteFlock(String id)

Implement lib/providers/flock_provider.dart:
- flocksProvider: AsyncNotifier that loads all non-archived flocks
- selectedFlockProvider: StateProvider<String?> for current flock filter
- Persist selectedFlockId to SharedPreferences

Test with temporary UI buttons.
```

### Task 2.2: Flock Screens
```
Implement lib/screens/flocks/flock_list_screen.dart:
- Shows list of flocks as cards
- Each card shows: name, description, bird count (placeholder 0 for now), color indicator
- FAB to add new flock
- Tap card -> flock detail
- Long press or swipe -> archive option

Implement lib/screens/flocks/flock_form_screen.dart:
- Used for both create and edit
- Fields: name (required), description, icon picker, color picker
- Save button in app bar
- Validation

Wire up routes in router.dart.
```

### Task 2.3: Bird Repository and Provider
```
Implement lib/repositories/bird_repository.dart:
- getAllBirds()
- getBirdsByFlock(String flockId)
- getBirdById(String id)
- insertBird(Bird bird)
- updateBird(Bird bird)
- updateBirdStatus(String id, BirdStatus status, String? notes)
- deleteBird(String id)

Implement lib/providers/bird_provider.dart:
- birdsProvider: loads all birds
- birdsByFlockProvider(String flockId): filtered list
- activeBirdsProvider: only active status
- Single bird provider for detail view

Test CRUD operations.
```

### Task 2.4: Bird List Screen
```
Implement lib/screens/birds/bird_list_screen.dart:
- List of birds with photo thumbnail, name, breed, age, status indicator
- Filter chips: All, Active, Deceased, Sold
- Flock filter dropdown (uses selectedFlockProvider)
- Sort options: name, age, recently added
- FAB to add bird
- Tap -> bird detail
- Empty state when no birds

Implement lib/widgets/bird_card.dart:
- Reusable card widget
- Shows: photo (or placeholder), name, breed, age, egg count (placeholder)
- Visual indicator for non-active status
```

### Task 2.5: Bird Form Screen
```
Implement lib/screens/birds/bird_form_screen.dart:
- Create and edit modes
- Sections:
  1. Photo (tap to add/change, uses image_picker)
  2. Basic info: name*, flock*, breed (dropdown from breed DB + free text option)
  3. Dates: hatch date (date picker), acquired date
  4. Details: source, expected egg color, notes
- Save in app bar
- Validation (name and flock required)

Photo should save to app documents directory, store path in database.
```

### Task 2.6: Bird Detail Screen
```
Implement lib/screens/birds/bird_detail_screen.dart:
- Header: large photo, name, breed, age
- Stats row: total eggs, eggs this month, laying rate (placeholder calcs)
- Tabs or sections:
  1. Info: all bird details in readable format
  2. Eggs: list of recent egg logs for this bird
  3. Health: medication and health notes timeline
- Edit button in app bar
- Status change action (menu or button):
  - If active: options to mark as deceased, sold, given away
  - Prompt for date and notes
  - Confirmation dialog
```

---

## Phase 3: Egg Logging

### Task 3.1: Egg Repository and Provider
```
Implement lib/repositories/egg_repository.dart:
- getAllEggLogs()
- getEggLogsByDate(DateTime date)
- getEggLogsByDateRange(DateTime start, DateTime end)
- getEggLogsByFlock(String flockId)
- getEggLogsByBird(String birdId)
- insertEggLog(EggLog log)
- updateEggLog(EggLog log)
- deleteEggLog(String id)
- getTotalEggCount()
- getEggCountByDateRange(DateTime start, DateTime end)

Implement lib/providers/egg_provider.dart:
- todayEggsProvider
- weekEggsProvider
- eggHistoryProvider(DateRange)
- lastLoggedFlockProvider (for defaults)
```

### Task 3.2: Quick Egg Log Widget
```
Implement lib/widgets/egg_quick_log.dart:
- Bottom sheet triggered by FAB
- Number picker (large, easy to tap, 0-30 range)
- Default count: same as yesterday for selected flock, or 0
- Flock selector (defaults to selectedFlockProvider or last used)
- Single prominent "Save" button
- Optional expandable section for: size, quality, notes, date, bird attribution
- Haptic feedback on save
- Toast confirmation
- Auto-dismiss on save

This is the most important UX in the app. Keep it fast.
2 taps for typical use: open sheet, tap save (using defaults).
```

### Task 3.3: Egg History Screen
```
Implement lib/screens/eggs/egg_history_screen.dart:
- Calendar view (month grid)
- Each day cell shows egg count (color coded: 0=gray, low=yellow, normal=green, high=blue)
- Tap day -> shows list of logs for that day
- Ability to edit/delete from day view
- Swipe month navigation
- Flock filter

Implement lib/screens/eggs/egg_log_screen.dart:
- Form for manual entry (for backfilling or detailed logging)
- All fields available
- Bird selector filtered by selected flock
```

### Task 3.4: Home Screen
```
Implement lib/screens/home/home_screen.dart:
- Header: "Good morning" + selected flock name (or "All Flocks")
- Today's eggs: big number + vs yesterday comparison
- Spark line: last 7 days production
- Stat cards row: week total, month total, active bird count
- Recent activity: last 5 egg logs with relative timestamps
- Quick actions: big "Log Eggs" button (opens quick log sheet)
- FAB also opens quick log sheet

This is the main screen users see daily. Keep it glanceable.
```

---

## Phase 4: Analytics

### Task 4.1: Analytics Provider
```
Implement lib/providers/analytics_provider.dart:

Calculate and expose:
- Daily/weekly/monthly/yearly egg totals
- Per-bird egg counts and percentages
- Laying rate by bird (eggs per 7 days average)
- Production trend (current week vs previous week)
- Best/worst production days
- Top layers ranking
- "Freeloaders" (active birds with 0 eggs in period)
- Seasonal patterns (month over month, if enough data)

All calculations should respect selectedFlockProvider filter.
Cache results and invalidate when egg_logs change.
```

### Task 4.2: Analytics Screen
```
Implement lib/screens/analytics/analytics_screen.dart:
- Period selector: Week, Month, Year, All Time
- Flock filter
- Summary stats: total eggs, daily average, best day, worst day
- Line chart: eggs per day over selected period (using fl_chart)
- Per-bird breakdown:
  - Ranked list with bird name, photo, count, percentage, bar visualization
  - Highlight top performer
  - Flag freeloaders
- Pull to refresh

Use skeleton loading states while data loads.
```

---

## Phase 5: Expenses

### Task 5.1: Expense Repository and Provider
```
Implement lib/repositories/expense_repository.dart:
- getAllExpenses()
- getExpensesByDateRange(DateTime start, DateTime end)
- getExpensesByCategory(ExpenseCategory category)
- insertExpense(Expense expense)
- updateExpense(Expense expense)
- deleteExpense(String id)
- getTotalExpenses(DateTime start, DateTime end)
- Same for Income

Implement lib/providers/expense_provider.dart:
- expensesProvider
- incomeProvider
- costPerEggProvider: total expenses / total eggs
- profitLossProvider: income - expenses
- expensesByCategoryProvider: grouped totals for pie chart
```

### Task 5.2: Expense Screens
```
Implement lib/screens/expenses/expense_list_screen.dart:
- List of expenses, sorted by date descending
- Each item: date, amount, category icon, description
- Filter by category
- Summary header: total spent (period), cost per egg
- FAB to add expense
- Swipe to delete

Implement lib/screens/expenses/expense_form_screen.dart:
- Amount (number input with currency format)
- Category (chips or dropdown)
- Date
- Description
- Flock (optional—null means shared)
- Recurring toggle with interval picker

Add income tracking UI (simpler: just amount, date, description, egg count)
```

### Task 5.3: Financial Summary Widget
```
Add financial summary to home screen or create dedicated summary screen:
- This month's expenses by category (pie chart)
- Cost per egg
- If income tracked: profit/loss, break-even price
- Trend vs last month

Keep it optional/collapsible for users who don't care about finances.
```

---

## Phase 6: Health & Medications

### Task 6.1: Medication Repository and Provider
```
Implement lib/repositories/medication_repository.dart:
- getAllMedications()
- getActiveMedications() (end_date null or in future)
- getMedicationsByBird(String birdId)
- getMedicationsByFlock(String flockId)
- insertMedication(MedicationLog log)
- updateMedication(MedicationLog log)
- deleteMedication(String id)
- Same pattern for HealthNote

Implement lib/providers/medication_provider.dart:
- activeMedicationsProvider
- withdrawalActiveProvider: bool, true if any active withdrawal
- withdrawalEndDateProvider: when current withdrawal ends
```

### Task 6.2: Medication Data
```
Create lib/utils/medication_data.dart:
- List of common poultry medications with default withdrawal days:
  - Corid (Amprolium): 0 days
  - SafeGuard (Fenbendazole): 14 days
  - Tylan (Tylosin): 1 day
  - Ivermectin: 14 days
  - Duramycin: 4 days
  - Valbazen: 14 days
  - VetRx: 0 days
  - Wazine: 14 days
  - Denagard: 5 days

Provide as dropdown options but allow custom entry.
```

### Task 6.3: Medication Screen
```
Implement lib/screens/medications/medication_screen.dart:
- WITHDRAWAL BANNER if any active withdrawal (prominent, can't miss)
  - Shows medication name and days remaining
- Active medications section
- Add medication form:
  - Medication (dropdown + custom)
  - Bird or whole flock
  - Dosage
  - Start date, end date
  - Withdrawal days (pre-filled from medication_data)
  - Notes
- Medication history list
- Notification scheduling for:
  - Treatment end reminder
  - Withdrawal complete

Integrate health notes timeline on bird detail screen.
```

---

## Phase 7: Breed Database & Settings

### Task 7.1: Breed Data
```
Create lib/data/breeds.dart:
- Static list of 50 common chicken breeds
- Each breed: name, aka, category, egg color, egg size, eggs per year, temperament, cold hardy, heat tolerant, broody tendency, weights, description
- Include: Leghorn, Rhode Island Red, Australorp, Plymouth Rock, Orpington, Wyandotte, Sussex, Brahma, Cochin, Silkie, Polish, Ameraucana, Easter Egger, Olive Egger, Marans, Welsummer, Barnevelder, Delaware, New Hampshire, Jersey Giant, Langshan, Minorca, Andalusian, Hamburg, Campine, Fayoumi, Cream Legbar, Bielefelder, ISA Brown, Golden Comet, Black Star, Red Star

Data source: Use typical breed characteristics.
```

### Task 7.2: Breed Screens
```
Implement lib/screens/breeds/breed_list_screen.dart:
- Searchable list of all breeds
- Filter chips: egg color (white, brown, blue, green, chocolate), cold hardy, good layers
- Each item: breed name, egg color indicator, eggs/year range
- Tap -> breed detail

Implement lib/screens/breeds/breed_detail_screen.dart:
- Breed image (bundled assets or placeholder)
- All breed characteristics in readable format
- "Add bird of this breed" quick action
```

### Task 7.3: Settings Screen
```
Implement lib/screens/settings/settings_screen.dart:
- Trial/purchase status display
- Purchase button if not purchased
- Notification preferences (toggle each type)
- Data export button (CSV)
- About section: version, support email
- Legal: privacy policy link

Implement CSV export:
- Creates ZIP with: birds.csv, egg_logs.csv, expenses.csv, medications.csv
- Opens share sheet
```

### Task 7.4: Trial and Purchase
```
Implement lib/providers/trial_provider.dart:
- Check trial start date from SharedPreferences
- Calculate days remaining
- Expose: isTrialActive, trialDaysRemaining, isPurchased, isReadOnly

Implement trial banner widget:
- Shows days remaining during trial
- Shows "Trial ended" with purchase button when expired

Implement purchase flow:
- Single non-consumable IAP: "full_access" at $4.99
- Restore purchases button
- Handle all purchase states

Implement read-only mode:
- When isReadOnly: disable all add/edit actions
- Show "Unlock" prompt when tapped
- Export always works (no hostage-taking)
```

---

## Phase 8: Polish

### Task 8.1: Empty States
```
Add empty state illustrations/messages for:
- No flocks yet
- No birds yet  
- No eggs logged
- No expenses
- No medications

Each should have a clear call to action.
```

### Task 8.2: Loading and Error States
```
Audit all screens for proper:
- Loading skeletons while data loads
- Error states with retry button
- Offline handling (should work fine, all local)

Use consistent patterns across app.
```

### Task 8.3: Notifications
```
Implement notification scheduling:
- Medication ending reminder (day of end date, morning)
- Withdrawal complete (day after withdrawal ends)
- Recurring expense reminder (1 day before due)
- Inactivity nudge (3 days no logs, optional, default off)

Handle notification permissions properly for iOS and Android.
```

### Task 8.4: Final Polish
```
- App icon (simple chicken or egg silhouette)
- Splash screen
- Haptic feedback on key actions
- Consistent transitions
- Keyboard handling (dismiss on tap outside, next field flow)
- Tablet/large screen layouts (optional, but nice)
- Accessibility: screen reader labels, sufficient contrast
- Run flutter analyze, fix all warnings
- Test on both iOS and Android
```

---

## Launch Prep

### Task 9.1: App Store Assets
```
Create:
- App icon (1024x1024 for App Store, adaptive for Android)
- Screenshots (6.5" iPhone, Android phone)
- Feature graphic for Play Store
- App description and keywords
- Privacy policy (hosted webpage)
- Support email setup
```

### Task 9.2: Beta Testing
```
- Deploy to TestFlight and Play Store internal testing
- Recruit 10-20 real chicken keepers
- Gather feedback for 2 weeks
- Fix critical issues
- Ship to production
```

---

## Task Execution Tips

When giving a task to Claude Code:

1. Copy the task description
2. Add: "Refer to CLAUDE.md for architecture and conventions"
3. Let it complete the task
4. Run `flutter analyze` and `flutter run` to verify
5. Test manually before moving on
6. Commit after each completed task

If a task is taking too long or Claude Code is struggling:
- Break it into smaller pieces
- Provide more specific guidance
- Show an example of the pattern you want

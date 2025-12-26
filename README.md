# Flock Manager

A cross-platform mobile app for backyard chicken keepers to track flocks, log eggs, monitor expenses, and manage bird health.

## Tech Stack

- **Framework:** Flutter 3.x
- **Language:** Dart
- **Database:** SQLite via `sqflite`
- **State Management:** Riverpod (riverpod + flutter_riverpod)
- **Navigation:** GoRouter
- **Charts:** fl_chart
- **Photos:** image_picker
- **In-App Purchase:** in_app_purchase
- **Local Notifications:** flutter_local_notifications

## Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Xcode (for iOS)
- Android Studio (for Android)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd flock_manager

# Install dependencies
flutter pub get

# Generate freezed classes
dart run build_runner build

# Run the app
flutter run
```

## Commands

```bash
# Run app
flutter run

# Run on specific device
flutter run -d <device_id>

# Build release
flutter build apk
flutter build ios

# Run tests
flutter test

# Generate freezed classes
dart run build_runner build

# Clean rebuild
flutter clean && flutter pub get

# Static analysis
flutter analyze
```

## Architecture

```
lib/
├── main.dart                 # App entry, providers, router setup
├── app/
│   ├── router.dart           # GoRouter configuration
│   └── theme.dart            # ThemeData, colors, text styles
├── models/                   # Freezed data classes
├── database/
│   ├── database_helper.dart  # SQLite singleton, migrations
│   └── tables.dart           # Table creation SQL
├── repositories/             # Data access layer
├── providers/                # Riverpod providers
├── screens/                  # Full-page views
├── widgets/                  # Reusable components
└── utils/                    # Helpers and constants
```

## Database Schema

### Tables

| Table | Purpose |
|-------|---------|
| `flocks` | Flock groups (e.g., "Backyard Hens") |
| `birds` | Individual birds with breed, age, status |
| `bird_photos` | Multiple photos per bird |
| `egg_logs` | Daily egg production records |
| `expenses` | Cost tracking by category |
| `income` | Egg sales and other income |
| `medication_logs` | Medications with withdrawal tracking |
| `health_notes` | Health observations per bird |

### Enums

```dart
enum BirdStatus { active, deceased, sold, givenAway }
enum EggSize { small, medium, large, jumbo }
enum EggQuality { normal, softShell, doubleYolk, abnormal }
enum ExpenseCategory { feed, bedding, supplies, medical, equipment, other }
enum HealthNoteType { observation, symptom, treatment, vetVisit, other }
enum RecurringInterval { weekly, monthly }
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

Test structure:
- `test/models/` - Model unit tests (toMap, fromMap, computed properties)
- `test/database/` - Database schema tests
- `test/widget_test.dart` - Widget tests

## Key Features

- **Quick Egg Logging** - Log daily eggs in 2 taps from anywhere in the app
- **Flock Management** - Organize birds into flocks
- **Bird Profiles** - Track individual birds with photos, breed, and age
- **Expense Tracking** - Monitor costs with category breakdown
- **Medication Tracking** - Log treatments with egg withdrawal period alerts
- **Analytics** - View production trends and per-bird statistics

## License

[Add license here]

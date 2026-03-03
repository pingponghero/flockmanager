# /lib/repositories/

Thin SQLite data-access layer. Each repository takes a `Database` instance and
provides typed CRUD + domain-specific queries. Providers own the repository
instances and call these methods.

All queries use raw SQL via `sqflite`. Models are Freezed classes hydrated from
row maps.

## Files

- **flock_repository.dart** — `FlockRepository` → `flocks` table. CRUD,
  archive/unarchive (soft delete via `is_archived`), bird count per flock.

- **bird_repository.dart** — `BirdRepository` → `birds` table. CRUD, filter by
  status/flock, status updates with event date, count-by-status map.

- **egg_repository.dart** — `EggRepository` → `egg_logs` table. Largest repo.
  Core CRUD, batch insert for distributed logs, date-range aggregations, daily
  counts for charts, streak calculations, and achievement queries (double yolk,
  fairy egg, Christmas eggs, etc.).

- **expense_repository.dart** — `ExpenseRepository` → `expenses` + `income`
  tables. Separate CRUD for expenses and income. Category breakdowns, date-range
  totals, eggs-sold tracking.

- **medication_repository.dart** — `MedicationRepository` → `medication_logs` +
  `health_notes` tables. Medication CRUD with active/withdrawal filtering, health
  notes per bird, reassign-to-anonymous on bird deletion.

- **bird_status_event_repository.dart** — `BirdStatusEventRepository` →
  `bird_status_events` table. Event log for bird status changes. Reconstructs
  historical flock size on any date by finding each bird's most recent event.

# Flock Manager — Data Import/Export Tasks

Ensure reliable round-trip data backup and restore via CSV export/import, including bird photos.

---

## Task 1: Export Compatibility Updates

Update the existing CSV export to ensure clean round-trip compatibility with import.

### Column Headers (canonical, must match exactly)

```
flocks.csv:
id,name,description,icon,color,is_archived,created_at

birds.csv:
id,flock_id,name,breed,breed_id,photo_primary,hatch_date,acquired_date,source,egg_color,status,status_date,status_notes,notes,created_at

egg_logs.csv:
id,date,flock_id,bird_id,count,size,quality,notes,created_at

expenses.csv:
id,date,amount,category,description,flock_id,is_recurring,recurring_interval,created_at

income.csv:
id,date,amount,description,egg_count,created_at

medication_logs.csv:
id,bird_id,flock_id,medication_name,dosage,start_date,end_date,withdrawal_days,notes,created_at

health_notes.csv:
id,bird_id,date,type,description,created_at
```

### Data Format Standards

| Type | Format | Example | Notes |
|------|--------|---------|-------|
| Dates | ISO8601 | `2025-01-19T14:30:00.000` | Empty string for null, never "null" |
| Booleans | SQLite style | `0` or `1` | is_archived, is_recurring |
| Integers | Plain | `142` | No thousands separators |
| Decimals | Plain | `24.99` | No currency symbols |
| Nulls | Empty string | `` | Never literal "null" text |
| Enums | String value | `active`, `deceased` | Case-sensitive, match Dart enum names |
| Text with special chars | CSV escaped | `"Has ""quotes"" and, commas"` | Standard CSV quoting rules |
| Photo references | Relative path | `bird_abc123.jpg` | Filename only, not absolute path |

### Export Changes Required

1. **Photo handling**
   - For each bird with `photo_primary` set:
     - Copy image file to `photos/` folder in ZIP
     - Rename to `bird_{bird_id}.jpg` (use bird's ID, not original filename)
     - In `birds.csv`, export `photo_primary` as `bird_{id}.jpg` (relative reference)
   - Birds without photos: `photo_primary` is empty string

2. **Exclude bird_photos.csv from ZIP**
   - Table not currently used (only photo_primary on birds)
   - If multi-photo support added later, revisit this

3. **Consistent file naming**
   - Lowercase with underscores: `egg_logs.csv` not `EggLogs.csv`

4. **UTF-8 encoding with BOM**
   - Byte order mark helps Excel open files correctly

5. **Omit empty tables**
   - Don't include `expenses.csv` if user has no expenses
   - Reduces clutter, import handles missing files gracefully

6. **Header row required**
   - First row is always column headers, never data

### ZIP Structure

```
flock_export_2025-01-19.zip
├── export_metadata.json    (required)
├── flocks.csv              (required)
├── birds.csv               (required)
├── egg_logs.csv            (omit if empty)
├── expenses.csv            (omit if empty)
├── income.csv              (omit if empty)
├── medication_logs.csv     (omit if empty)
├── health_notes.csv        (omit if empty)
└── photos/                 (omit if no birds have photos)
    ├── bird_abc123.jpg
    ├── bird_def456.jpg
    └── bird_ghi789.jpg
```

### New: export_metadata.json

```json
{
  "app_version": "1.0.0",
  "export_date": "2025-01-19T14:30:00.000",
  "export_format_version": 1,
  "counts": {
    "flocks": 2,
    "birds": 8,
    "photos": 5,
    "egg_logs": 142,
    "expenses": 23,
    "income": 5,
    "medication_logs": 3,
    "health_notes": 12
  }
}
```

**Benefits:**
- Import can check `format_version` for compatibility
- User sees summary without extracting CSVs
- Photo count helps user understand backup completeness
- Future-proofs for schema migrations

### File Size Considerations

Typical bird photo: 1-3 MB (phone camera)

| Flock Size | Estimated ZIP |
|------------|---------------|
| 5 birds | 5-15 MB |
| 20 birds | 20-60 MB |
| 50 birds | 50-150 MB |

Add progress indicator and note in UI: "Export may take a moment for large flocks with photos."

### Acceptance Criteria

- [ ] All CSVs use canonical column headers
- [ ] Date/boolean/null formats match spec
- [ ] photo_primary exports as relative filename (not absolute path)
- [ ] Photos copied to photos/ folder with bird ID naming
- [ ] export_metadata.json included with correct counts (including photos)
- [ ] Empty tables omitted from ZIP
- [ ] photos/ folder omitted if no birds have photos
- [ ] Files are UTF-8 with BOM
- [ ] Progress indicator shown during export

---

## Task 2: CSV Import (Replace Mode)

Implement data import from ZIP file to restore backups.

### User Flow

1. User taps **"Import Data"** in Settings (place near existing Export)

2. **Warning dialog appears:**
   ```
   ⚠️ Replace All Data?
   
   This will permanently delete all existing data and replace 
   it with the imported backup.
   
   • All current flocks, birds, and logs will be deleted
   • This cannot be undone
   
   [Cancel]  [Choose Backup File...]
   ```

3. If confirmed, **file picker opens** (filtered to .zip files)

4. App reads `export_metadata.json` and shows **confirmation with counts:**
   ```
   Import Backup?
   
   From: flock_export_2025-01-19.zip
   Exported: January 19, 2025 at 2:30 PM
   
   Contains:
   • 2 flocks
   • 8 birds (5 with photos)
   • 142 egg logs
   • 23 expenses
   • 5 income records
   • 3 medication logs
   • 12 health notes
   
   [Cancel]  [Import]
   ```

5. **Import executes** (show progress indicator)

6. **Success toast:** "Imported 2 flocks, 8 birds, 142 egg logs..."

7. **Refresh app state** (invalidate all Riverpod providers, navigate to home)

### Validation Rules

**ZIP Structure:**
- Must be valid ZIP file
- Must contain `flocks.csv` and `birds.csv` (minimum required)
- Other CSVs optional
- `photos/` folder optional

**Metadata Check:**
- If `export_metadata.json` exists:
  - `format_version > 1`: Show "This backup is from a newer app version. Please update Flock Manager."
  - `format_version == 1`: Proceed normally
- If metadata missing: Attempt import with warning (legacy backup)

**CSV Validation:**
- Header row must match expected columns exactly
- Required fields must be non-empty (id, name, flock_id where applicable)
- Foreign keys must resolve:
  - `birds.flock_id` → must exist in `flocks.csv`
  - `egg_logs.flock_id` → must exist in `flocks.csv`
  - `egg_logs.bird_id` → must exist in `birds.csv` (if non-empty)
  - etc.
- Dates must parse as ISO8601
- Enums must match valid values

### Import Order (dependency sequence)

```
1. flocks
2. birds (without photo paths)
3. photos (extract files, update bird records with new paths)
4. egg_logs
5. expenses
6. income
7. medication_logs
8. health_notes
```

### Photo Import Process

1. **Clear existing photos**
   - Delete all files in app's photo storage directory
   - Clear `bird_photos` table

2. **Extract new photos**
   - If ZIP contains `photos/` folder:
     - Extract each image to app's photo storage directory
     - Preserve filename (e.g., `bird_abc123.jpg`)

3. **Update bird records**
   - For each bird in `birds.csv` with non-empty `photo_primary`:
     - Check that referenced file exists in extracted photos
     - Build new absolute path: `{app_photo_dir}/bird_abc123.jpg`
     - Update bird record with new absolute path

4. **Handle missing photos gracefully**
   - If `photo_primary` references a file not in ZIP:
     - Log warning
     - Set `photo_primary` to empty string
     - Continue import (don't fail entire operation)

### Database Operations

```dart
Future<ImportResult> importFromZip(File zipFile) async {
  // 1. Extract ZIP to temp directory
  // 2. Validate structure and parse all CSVs
  // 3. Validate foreign key relationships
  // 4. If any validation fails, return error (no DB changes)
  
  // 5. Begin transaction
  // 6. Delete all existing data (reverse dependency order)
  //    - health_notes, medication_logs, income, expenses, 
  //      egg_logs, bird_photos, birds, flocks
  // 7. Delete existing photo files
  // 8. Extract photos to app storage
  // 9. Insert imported data (dependency order)
  // 10. Update bird photo paths to new locations
  // 11. Commit transaction
  
  // 12. Clean up temp directory
  // 13. Return success with counts
}
```

### Error Handling

**User-friendly error messages:**

| Error | Message |
|-------|---------|
| Not a ZIP file | "This file isn't a valid backup. Please select a .zip file exported from Flock Manager." |
| Missing required CSV | "This backup is incomplete. Missing required file: flocks.csv" |
| Wrong columns | "birds.csv has unexpected columns. This backup may be from a different app." |
| Parse error | "Could not read egg_logs.csv row 47: invalid date format" |
| FK violation | "egg_logs.csv row 23 references a flock that doesn't exist in this backup" |
| Newer format | "This backup is from a newer version of Flock Manager. Please update the app." |

**Photo-specific handling (warnings, not errors):**

| Issue | Handling |
|-------|----------|
| Photo file missing from ZIP | Log warning, clear photo reference, continue |
| Photo file corrupt/unreadable | Log warning, clear photo reference, continue |
| Orphan photos (no matching bird) | Ignore, don't copy to app storage |

**Transaction safety:**
- Entire import wrapped in transaction
- Any failure → complete rollback
- User's existing data preserved on error
- Photo extraction happens after DB validation but before commit

### ImportResult Model

```dart
class ImportResult {
  final bool success;
  final String? errorMessage;
  final int flocksImported;
  final int birdsImported;
  final int photosImported;
  final int eggLogsImported;
  final int expensesImported;
  final int incomeImported;
  final int medicationLogsImported;
  final int healthNotesImported;
  final List<String> warnings; // e.g., "Photo missing for bird 'Henrietta'"
  
  String get summaryMessage {
    // "Imported 2 flocks, 8 birds (5 photos), 142 egg logs..."
  }
}
```

### Settings Screen UI

```
Data Management
─────────────────────────────
[↑] Export Data
    Save all flock data and photos as a backup file
    
[↓] Import Data  
    Restore from a backup file (replaces all current data)
─────────────────────────────
```

### Acceptance Criteria

- [ ] Import button appears in Settings
- [ ] Warning dialog clearly explains data replacement
- [ ] File picker filters to .zip files
- [ ] Confirmation shows counts from metadata (including photo count)
- [ ] Validation catches malformed/incompatible backups
- [ ] Foreign key violations detected before any DB changes
- [ ] Import wrapped in transaction with rollback on failure
- [ ] Photos extracted and paths updated correctly
- [ ] Missing photos handled gracefully (warning, not error)
- [ ] Success toast shows imported counts
- [ ] App state refreshes after import (providers invalidated)

### Test Cases

| Scenario | Expected Result |
|----------|-----------------|
| Import into empty database | Success |
| Import into database with existing data | Existing data wiped, import succeeds |
| Import ZIP missing optional CSVs (expenses, etc.) | Success, only available data imported |
| Import ZIP missing required CSV (flocks.csv) | Error before any DB changes |
| Import ZIP with invalid CSV headers | Error with specific message |
| Import ZIP with FK violations | Error with specific row/file |
| Import non-ZIP file | Error: not a valid backup |
| Import from newer format_version | Error: update app |
| Import legacy ZIP (no metadata) | Warning, then proceed |
| Import fails mid-transaction | Rollback, existing data intact |
| Import ZIP with photos | Photos restored, paths updated |
| Import ZIP with missing photo file | Warning logged, photo reference cleared, import succeeds |
| Import ZIP with no photos/ folder | Success, all photo references cleared |
| Import ZIP with orphan photos | Orphans ignored, not copied |

### Round-Trip Test

1. Create database with edge-case data:
   - Text with commas, quotes, newlines in notes
   - Empty optional fields
   - All enum values represented
   - Various date values
   - Birds with and without photos
   
2. Export → Import into fresh install → Export again

3. Compare the two exports:
   - CSVs should be identical (except export_date in metadata)
   - Photos should be byte-for-byte identical

---

## Implementation Notes

### File Locations

```
lib/
├── repositories/
│   └── import_export_repository.dart  (new or expand existing)
├── models/
│   └── import_result.dart             (new)
├── screens/settings/
│   └── settings_screen.dart           (add import UI)
└── widgets/
    └── import_confirmation_dialog.dart (new)
```

### Photo Storage

```dart
// Get app's photo directory
final appDir = await getApplicationDocumentsDirectory();
final photoDir = Directory('${appDir.path}/photos');

// Ensure it exists
await photoDir.create(recursive: true);

// Photo path pattern
final photoPath = '${photoDir.path}/bird_$birdId.jpg';
```

### Dependencies

May need to add if not present:
- `archive` package for ZIP handling
- `csv` package for parsing (or use existing solution)
- `file_picker` for selecting import file

### Provider Invalidation

After successful import:
```dart
// Invalidate all data providers to force refresh
ref.invalidate(flocksProvider);
ref.invalidate(birdsProvider);
ref.invalidate(eggsProvider);
// ... etc
```

---

## Future Enhancements (Out of Scope)

- **Merge mode**: Add imported data without wiping existing
- **Selective import**: Choose which tables to import
- **Cloud backup**: Google Drive / iCloud integration
- **Import from competitors**: Parse other apps' export formats
- **Multi-photo support**: If bird_photos table gets used, bundle all photos

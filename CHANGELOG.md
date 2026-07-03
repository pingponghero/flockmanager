# Changelog

## 2.5.0 (+26) — unreleased (branch: 24-27-gifted-eggs-and-recipients)

Implements the two most-requested beta features (#24, #27).

### Added

- **Gifted eggs** (#24) — a first-class Gift category alongside sales:
  - "Record Gift" action on the Value tab; the sale/income form has a
    Sale | Gift selector. Gifts are always zero-amount and require an egg
    count.
  - Gifted eggs are **excluded from sold-egg counts and average sale
    price**, and are not valued at retail in the egg-value math (they are
    tracked as their own bucket: logged = consumed + sold + gifted).
  - Gifted totals shown on the Egg Value card and its breakdown sheet.
  - DB migration v6 adds `income.type` / `income.recipient_id` (existing
    rows default to `sale`) and the `recipients` table.
- **Recipient directory** (#27) — manage the people you sell/gift eggs to:
  - Settings → Recipients: add, rename, delete (deleting keeps the
    sale/gift records, unlinked), with per-recipient statistics
    (eggs sold, revenue, eggs gifted).
  - Recipient picker on the sale/gift form with inline "New recipient…".
  - Sale/gift list rows show "Sale to / Gift to <name>" when no
    description is set.
- **Gifting achievements**: Sharing the Bounty (first gifted egg),
  Gift Basket (100 gifted eggs), Community Coop (gifts to 3+ recipients).
- Export/import includes `recipients.csv` and the new income columns;
  older backups without them import cleanly (rows default to sale).

## 2.4.0 (+25) — unreleased

Bug-fix release driven by beta feedback (power user with ~6 years of
imported history). See GitHub issues for items deferred to later releases.

### Fixed

- **Medication logs could not be saved** — the Add Medication form inserted
  an empty `id`, so the first save silently wrote a blank-ID row and every
  save after that failed with a UNIQUE constraint error. New saves generate
  a proper UUID, a DB migration (v5) repairs the existing blank-ID row, and
  CSV import now repairs blank medication IDs instead of failing.
- **CSV import failed on multiline text** — export quoted embedded line
  breaks correctly, but the import parser split rows on every newline before
  handling quotes, breaking export→import round-trips for any multiline
  notes/description ("IMPORT FAILED … column count mismatch"). The parser now
  handles quoted newlines and `\r\n` endings; export additionally quotes
  bare `\r`.
- **Forecast counted deceased/sold birds** — the production forecast took
  "current active hens" from the status-event timeline, which can disagree
  with reality for birds imported from backups with incomplete status
  history (missing terminal events, or death dates predating the
  reconstructed 'active' event). The forecast now reads today's flock size
  from the birds table; migration v5 repairs inconsistent event timelines;
  import reconstruction orders events correctly and no longer skips the
  terminal event when `status_date` is missing.
- **Home screen pinned a stale "latest achievement"** (#23) — the widget
  showed the last *defined* earned achievement (which is why "Molt Survivor"
  stuck). Earned dates are now recorded and the most recently earned
  achievement is shown; dates are dropped if an achievement is revoked by a
  data correction.
- **Achievement text hardcoded `$`** — "Basically Free" and "Side Hustle"
  descriptions now render the currency symbol chosen in Settings.
- **"Log by hen instead" dropped entered data** — switching from the quick
  log to per-hen logging discarded the selected date, flock, and any bird +
  count already entered. All three now carry over.
- **Deceased birds accrued new flock-wide medications** — a bird's HEALTH
  tab no longer lists flock-wide treatments started after the bird's
  departure (death/sale/give-away) date.
- Restored the missing `export_reminder_provider.dart` (untracked file
  referenced by the settings screen; main did not compile without it).

### Improved

- Single-flock users get the flock prefilled in **Record Sale** and
  **Add Expense** (matching egg logging); "Shared" remains the default when
  multiple flocks exist.
- **Achievements screen** shows the earned date in the badge detail sheet
  (dates are recorded from this version onward).
- The Add Medication sheet's Save button now matches the styling used by
  the other entry forms.

### Investigated, not code-changed (from the same feedback)

- *Stale expense/income detail after edit*: this build has no separate
  detail screen — list rows open the edit form directly; could not
  reproduce.
- *Archive "UNDO" toast never dismisses*: all app snackbars use a 4-second
  timeout; Android keeps action snackbars on screen when an accessibility
  service (e.g. TalkBack) is active, which matches the report.
- *Achievement not revoked after correcting an entry*: achievements are
  re-evaluated from live data, so corrections do revoke them; the stale
  home-screen widget (fixed above) made it look otherwise.
- *"Start week on Monday" only partially applied*: no week-start setting
  exists in this codebase — tracked as a feature request with the i18n
  cluster (#19).

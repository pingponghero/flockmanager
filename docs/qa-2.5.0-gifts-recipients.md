# QA Plan — Gifted Eggs + Recipient Directory (branch `24-27-gifted-eggs-and-recipients`)

Covers #24/#27 plus regression on the 2.4.0 fixes stacked under this branch.
~30–40 min for the full pass; the Critical section alone is ~15 min.

## Setup

```bash
flutter emulators                        # list
flutter emulators --launch <emulator_id> # e.g. Pixel_8_API_34
flutter run
```

- Seed data: Settings → (debug tools) → **Load test data**, then restart the app.
- Suggested devices: one phone emulator + one tablet emulator if available
  (the reporting beta user is on a Samsung Tab S9). Spot-check dark mode once.

**Upgrade path (do this once, it exercises migrations v5+v6):**

1. `git checkout main && flutter run` — create data on the old build:
   at least one flock, a few birds (mark one deceased), egg logs, an expense,
   **two income records with egg counts**, and try adding **two medications**
   (on main the second add should FAIL — that's the known bug).
2. Stop, `git checkout 24-27-gifted-eggs-and-recipients && flutter run`
   (do NOT uninstall — this performs an in-place upgrade).
3. Verify: app opens with all data intact; existing income rows appear as
   Sales; adding medications now works repeatedly; forecast hen count
   excludes the deceased bird.

---

## Critical — Gifted eggs (#24)

| # | Steps | Expected |
|---|---|---|
| G1 | Value tab → + → **Record Gift** | Form titled "Record Gift", Gift segment selected, **no amount field**, egg count labeled "Number of eggs gifted" |
| G2 | Save a gift without egg count | Validation error "Please enter how many eggs were gifted" |
| G3 | Save gift: 10 eggs, recipient Anna, today | Snackbar; list row shows gift icon, title "Gift to Anna", trailing **"Gift"** (not +$0.00) |
| G4 | Toggle Sale ↔ Gift mid-entry | Amount field appears/disappears; entered values survive the toggle |
| G5 | Record a sale: 12 eggs for 6.00 | Egg Value card: avg $/dz computed from the sale only; "10 gifted" line appears; gifted eggs NOT in "sold" count |
| G6 | Tap Egg Value card (breakdown sheet) | Shows "10 gifted · not counted in value or sale stats"; consumed = logged − sold − gifted |
| G7 | Edit the gift → flip to Sale, amount 0.01 → Save; then flip back to Gift | Both directions save; Value stats update accordingly |
| G8 | Swipe-delete the gift | Dialog says "Delete Gift"; snackbar "Gift deleted"; stats update |
| G9 | Record first-ever gift (fresh/seed data) | "Sharing the Bounty" achievement celebration fires once; appears as Latest Achievement on home |
| G10 | Flock filter: gift assigned to Flock A, then filter Value tab by Flock B | Gift not counted for Flock B; "Shared" gifts count for all flocks |

## Critical — Recipients (#27)

| # | Steps | Expected |
|---|---|---|
| R1 | Settings → Recipients (no data) | Empty state with explanation; FAB adds |
| R2 | Add "Anna" via FAB; add "zuzana" | List sorted case-insensitively (Anna, zuzana) |
| R3 | In gift form → Recipient → **New recipient…** | Name dialog; new recipient auto-selected in the dropdown |
| R4 | Record 1 sale (12 eggs, 6.00) + 2 gifts (10+5 eggs) for Anna | Anna's row: "12 eggs sold (…6.00) · 15 eggs gifted" |
| R5 | Rename Anna → "Anna K." | List and existing income rows ("Gift to Anna K.") update |
| R6 | Delete Anna (confirm dialog warns records are kept) | Recipient gone; her sale/gift rows remain, now titled "Egg Gift"/"Egg Sale" |
| R7 | Recipient dropdown → "None" | Saves with no recipient |
| R8 | Gift to 3 different recipients | "Community Coop" achievement fires |

## Critical — Export / Import round-trip

| # | Steps | Expected |
|---|---|---|
| E1 | With gifts + recipients present: Settings → Export Data → then Import that file | Everything restored: gifts still gifts, recipients + links intact, stats identical |
| E2 | Import a backup made on main/2.3.x (make one during the upgrade-path setup) | Imports cleanly; all income rows become Sales |
| E3 | Put multiline text (2+ ENTERs) in a bird's notes and an expense description → export → import | No "IMPORT FAILED"; text intact with line breaks |

## Regression — 2.4.0 fixes included in this branch

| # | Steps | Expected |
|---|---|---|
| X1 | Add two medications back to back | Both save (no UNIQUE constraint error) |
| X2 | Mark a bird deceased → Analytics forecast | Active hen count drops immediately |
| X3 | Earn any new achievement | Home "Latest Achievement" updates (not pinned to Molt Survivor); detail sheet shows earned date |
| X4 | Settings → Currency Symbol → set "Kč" | Field accepts 2–3 chars; shows in amounts and in "Basically Free"/"Side Hustle" achievement text |
| X5 | Quick log: set count 3 + pick a bird under More Options → "Log by hen instead" | That bird pre-filled with 3 in the per-hen list; date/flock carried over |
| X6 | With exactly one flock: open Record Sale and Add Expense | Flock pre-filled (not "Shared"); with 2+ flocks default stays "Shared" |
| X7 | Medication sheet Save button | Plain text button matching other forms |

## Nice-to-have checks

- Rotate device / tablet layout on the gift form and Recipients screen.
- Dark mode: gift icon/labels legible on Value tab.
- Gift Basket progress: achievement screen shows n/100 progress bar after some gifts.
- Recipient with a long name: list row and "Gift to <name>" truncate gracefully.

## Known limitations (don't file as bugs)

- Gifted eggs intentionally carry **zero value** in egg-value/net-savings math.
- Achievement earned dates only exist from this version onward; older earned
  badges show no date until re-observed.
- The "$0.01 workaround" records stay sales until manually edited to Gift.

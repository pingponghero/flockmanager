# Flock Manager MVP — Product Specification

**Version:** 1.0  
**Target:** Solo developer, cross-platform (iOS/Android)  
**Monetization:** 14-day free trial → $4.99 one-time purchase  
**Data:** Local storage only, no backend required

---

## Product positioning

A fast, focused flock management app for backyard chicken keepers who want real insights without complexity. Competes on UX quality and speed, not feature count.

**Core promise:** Log eggs in one tap. Know which hens earn their keep. Track costs without spreadsheets.

**Target user:** Backyard chicken keeper with 4-25 birds, possibly multiple flocks or coops, who wants more than a notebook but less than a farm management system.

---

## Information architecture

```
Home (Dashboard)
├── Quick log (egg entry)
├── Today's summary
└── Production trend (7-day spark chart)

Flocks
├── Flock list
├── Flock detail
│   ├── Birds in flock
│   ├── Flock production stats
│   └── Flock expenses
└── Add/edit flock

Birds
├── Bird list (filterable by flock, status)
├── Bird detail
│   ├── Profile info
│   ├── Photo gallery
│   ├── Egg production history
│   ├── Health/medication log
│   └── Notes timeline
└── Add/edit bird

Eggs
├── Log entry (quick add)
├── History (calendar + list view)
└── Analytics
    ├── Production charts
    ├── Per-bird breakdown
    └── Seasonal trends

Expenses
├── Expense list
├── Add expense
├── Cost analysis
│   ├── Cost per egg
│   ├── Cost per bird
│   └── Monthly burn rate
└── Income tracking (egg sales)

Medications
├── Active reminders
├── Medication log
├── Withdrawal calculator
└── Add medication schedule

Breeds (reference)
├── Breed database
├── Search/filter
└── Breed detail cards

Settings
├── Trial/purchase status
├── Data export
├── Notifications
└── App preferences
```

---

## Feature specifications

### 1. Flock management

**Purpose:** Organize birds into logical groups (by coop, by purpose, by age cohort).

**Data model — Flock:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | auto | |
| name | string | yes | e.g., "Main Coop", "Bantam Run" |
| description | string | no | |
| icon | enum | no | Predefined icon set |
| color | hex | no | For visual differentiation |
| created_at | datetime | auto | |

**Functionality:**
- Create, edit, archive flocks
- Reorder flocks (drag handle)
- Archive (soft delete) preserves historical data
- Default flock created on first launch
- Flock-level production stats aggregate from birds

**UX notes:**
- Flock selector should be persistent/accessible from most screens
- "All flocks" view available everywhere
- Maximum recommended: 10 flocks (no hard limit)

---

### 2. Bird profiles

**Purpose:** Track individual birds with enough detail to be useful, not so much it's tedious.

**Data model — Bird:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | auto | |
| flock_id | UUID | yes | Foreign key |
| name | string | yes | |
| breed | string | no | Free text or breed DB link |
| breed_id | UUID | no | Link to breed database |
| photo_primary | blob/path | no | Main display photo |
| photos | array | no | Additional photos (max 5) |
| hatch_date | date | no | For age calculation |
| acquired_date | date | no | When you got them |
| source | string | no | Hatchery, breeder, etc. |
| egg_color | string | no | Expected egg color |
| status | enum | yes | active, deceased, sold, given_away |
| status_date | date | no | When status changed |
| status_notes | string | no | Cause of death, buyer info, etc. |
| notes | string | no | General notes |
| created_at | datetime | auto | |

**Calculated fields:**
- Age (from hatch_date)
- Total eggs (lifetime)
- Eggs this week/month/year
- Days since last egg
- Laying rate (eggs per week average)

**Functionality:**
- Add bird with minimal required fields (name + flock only)
- Edit all fields anytime
- Photo management: add, delete, set primary
- Status change workflow with required date and optional notes
- "Deceased" status prompts for cause (predator, illness, age, unknown, other)
- View bird's complete egg history
- View bird's medication history
- Quick actions: log egg for this bird, add note, add medication

**UX notes:**
- Bird list shows photo thumbnail, name, breed, age, recent egg count
- Filter by: flock, status, breed
- Sort by: name, age, production
- Swipe actions: quick egg log, edit

---

### 3. Egg logging

**Purpose:** The core daily interaction. Must be frictionless.

**Data model — EggLog:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | auto | |
| date | date | yes | Defaults to today |
| flock_id | UUID | yes | |
| count | integer | yes | Total eggs this entry |
| bird_id | UUID | no | If attributed to specific bird |
| size | enum | no | small, medium, large, jumbo |
| quality | enum | no | normal, soft_shell, double_yolk, abnormal |
| notes | string | no | |
| created_at | datetime | auto | |

**Functionality:**

*Quick log (primary flow):*
1. Tap FAB or "Log eggs" from anywhere
2. See number picker (default: last logged count for this flock)
3. Tap flock selector if different from default
4. Tap save — done

Total taps for typical use: 2 (open → save with defaults)

*Detailed log (optional):*
- Expand to show size, quality, notes
- Attribute to specific bird (shows bird picker filtered by flock)
- Change date (for backfilling)

*Batch attribution:*
- "3 eggs" can be split: 1 from Henrietta, 1 from Ginger, 1 unknown
- Or just logged as 3 eggs from flock (no attribution)

**UX notes:**
- Remember last-used flock as default
- Haptic feedback on save
- Quick confirmation toast, not blocking modal
- Allow multiple log entries per day (some people collect AM and PM)
- Calendar view shows dots/counts per day
- Undo available for 5 seconds after logging

---

### 4. Production analytics

**Purpose:** Answer "how are my chickens doing?" with actual data.

**Views:**

*Dashboard widget:*
- Today's count vs. 7-day average
- Simple trend indicator (up/down/flat)
- Spark line showing last 7 days

*Full analytics screen:*
- Time period selector: week, month, year, all time, custom range
- Total eggs in period
- Daily average
- Best day / worst day
- Line chart of production over time

*Per-bird breakdown:*
- Ranked list: bird name, egg count, percentage of total
- Highlight top performer
- Highlight "freeloaders" (active birds with 0 eggs in period)
- Laying rate (eggs per week) by bird

*Seasonal view (nice to have):*
- Month-over-month comparison
- Year-over-year if enough data

**Calculations:**
- Laying rate = eggs in period / days in period × 7
- Per-bird percentage = bird eggs / total eggs × 100
- Trend = compare current 7 days to previous 7 days

---

### 5. Expense tracking

**Purpose:** Answer "what does each egg actually cost me?"

**Data model — Expense:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | auto | |
| date | date | yes | |
| amount | decimal | yes | |
| category | enum | yes | feed, bedding, supplies, medical, equipment, other |
| description | string | no | |
| flock_id | UUID | no | Null = shared across all flocks |
| recurring | boolean | no | For regular expenses |
| recurring_interval | enum | no | weekly, monthly |
| created_at | datetime | auto | |

**Data model — Income:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | auto | |
| date | date | yes | |
| amount | decimal | yes | |
| description | string | no | e.g., "Egg sales - neighbor" |
| egg_count | integer | no | How many eggs sold |
| created_at | datetime | auto | |

**Analytics:**
- Total expenses (period)
- Expenses by category (pie chart)
- Cost per egg = total expenses / total eggs
- Cost per bird per month = total expenses / bird count / months
- Profit/loss = income - expenses
- Break-even price = cost per egg (what to charge per egg)

**UX notes:**
- Quick expense entry from home screen
- Preset amounts for common expenses (e.g., "$18 - 50lb feed bag")
- Recurring expense reminders (not auto-log, just notification)

---

### 6. Medication & health tracking

**Purpose:** Keep birds healthy, track treatments, respect withdrawal periods.

**Data model — MedicationLog:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | auto | |
| bird_id | UUID | no | Null = whole flock |
| flock_id | UUID | yes | |
| medication_name | string | yes | |
| dosage | string | no | |
| start_date | date | yes | |
| end_date | date | no | |
| withdrawal_days | integer | no | Egg withdrawal period |
| notes | string | no | |
| created_at | datetime | auto | |

**Data model — HealthNote:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | auto | |
| bird_id | UUID | yes | |
| date | date | yes | |
| type | enum | yes | observation, symptom, treatment, vet_visit, other |
| description | string | yes | |
| created_at | datetime | auto | |

**Functionality:**

*Medication scheduling:*
- Add medication with start date, optional end date
- Set withdrawal period (eggs unsafe to eat)
- App shows "WITHDRAWAL ACTIVE" banner when applicable
- Notification when withdrawal period ends
- Common medications with preset withdrawal periods (user can edit)

*Health timeline:*
- Chronological list of health events per bird
- Add observations, symptoms, treatments
- No diagnosis engine in MVP — just logging

**Preset medications (with typical withdrawal periods):**
- Corid (Amprolium) — 0 days
- SafeGuard (Fenbendazole) — 14 days
- Tylan (Tylosin) — 1 day
- Ivermectin — 14 days
- Duramycin — 4 days
- Valbazen — 14 days
- VetRx — 0 days
- *User can add custom*

---

### 7. Breed database

**Purpose:** Reference information for common breeds. Low effort, high perceived value.

**Data model — Breed (static, bundled with app):**
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| name | string | e.g., "Barred Plymouth Rock" |
| also_known_as | array | Alternate names |
| category | enum | standard, bantam, hybrid |
| egg_color | string | |
| egg_size | string | |
| eggs_per_year | string | Range, e.g., "250-300" |
| temperament | string | |
| cold_hardy | boolean | |
| heat_tolerant | boolean | |
| broody | enum | rarely, sometimes, often |
| weight_hen | string | |
| weight_rooster | string | |
| description | string | Short paragraph |
| image | asset | Bundled image |

**Content scope (MVP):**
Start with 40-50 most common breeds:
- Production breeds: Leghorn, Rhode Island Red, Australorp, etc.
- Dual purpose: Plymouth Rock, Orpington, Wyandotte, Sussex, etc.
- Fancy/ornamental: Silkie, Polish, Cochin, etc.
- Easter eggers, Olive eggers, common hybrids

**Functionality:**
- Browse full list
- Search by name
- Filter by: egg color, cold hardy, temperament
- Link breed to bird profile (optional)
- "Learn more" links to external resources (optional)

---

### 8. Data export

**Purpose:** Users own their data. Critical for trust.

**Export formats:**
- CSV (one file per data type: birds, eggs, expenses)
- Combined CSV (all data, multi-sheet or merged)
- PDF summary report (nice to have)

**Export contents:**
- All bird data including status history
- Complete egg log
- All expenses and income
- Medication records

**Delivery:**
- Share sheet (email, files, AirDrop, etc.)
- Local save option

---

### 9. Notifications

**Purpose:** Helpful reminders without being annoying.

**Notification types:**
- Medication ending: "Tylan treatment ends today"
- Withdrawal complete: "Eggs are safe to eat again"
- Recurring expense reminder: "Time to buy feed?"
- Inactivity nudge: "Haven't logged eggs in 3 days" (optional, default off)

**User controls:**
- Each notification type can be toggled independently
- Quiet hours setting
- All notifications can be disabled globally

---

## Trial and purchase flow

**Trial period:** 14 days, full functionality

**Trial experience:**
- Day 1: Welcome, no purchase prompts
- Day 7: Gentle reminder ("7 days left in trial")
- Day 12: "Trial ending soon" notification
- Day 14: App enters read-only mode

**Read-only mode (post-trial, unpurchased):**
- Can view all existing data
- Cannot add new eggs, birds, expenses
- Clear "Unlock Full Access - $4.99" button
- No data loss, no hostage-taking

**Purchase:**
- Single in-app purchase: $4.99
- Restores on new device via App Store/Play Store receipt
- No account creation required

**Messaging:**
- "One-time purchase. No subscription. Yours forever."
- "Your data stays on your device. Export anytime."

---

## Technical notes

**Local storage:**
- SQLite database (or platform equivalent)
- Photos stored in app's local documents directory
- Backup via device backup (iCloud, Google)

**No backend required:**
- No user accounts
- No cloud sync
- No server costs
- No auth complexity

**Cross-platform options:**
- Flutter (Dart) — single codebase, native performance
- React Native — JavaScript, larger ecosystem
- Kotlin Multiplatform — newer, native feel

**Performance targets:**
- App launch to usable: < 1 second
- Egg log save: < 100ms
- Analytics generation: < 500ms for 3 years of data

**Data estimates:**
- 1 year of data for 12 birds: ~10MB
- 5 years: ~50MB
- Photos are the main storage driver

---

## Out of scope (explicitly not building)

- Cloud sync / multi-device
- User accounts
- Weather integration
- Smart coop integrations
- AI/ML features
- Social/community features
- Incubation tracking
- Breeding/genetics tracking
- Family tree visualization
- Coop sitter sharing
- In-app purchase for features (single unlock only)
- Ads

---

## Success metrics

**App Store:**
- 4.5+ star rating
- "Easy to use" mentioned in reviews
- No complaints about data loss

**Usage (if analytics added, opt-in only):**
- 60%+ of users log eggs within 24 hours of install
- 30%+ convert from trial to paid
- 40%+ weekly retention at 30 days

---

## Launch checklist

- [ ] App Store assets (screenshots, description, keywords)
- [ ] Privacy policy (local-only storage makes this simple)
- [ ] Basic landing page / support email
- [ ] TestFlight / Play Store beta with 10-20 real chicken keepers
- [ ] Respond to every review for first 3 months
- [ ] Post launch announcement on r/BackYardChickens, BYC forum

---

## Future considerations (Phase 2, if appetite returns)

**Low effort additions:**
- Weather widget (API call, display only)
- Home screen widgets (iOS/Android)
- Dark mode
- iPad/tablet layout
- Apple Watch complication (today's count)

**Medium effort:**
- Incubation tracker
- Basic breeding records
- Photo export / sharing
- Siri/Google Assistant shortcuts

**High effort (requires backend):**
- Cloud sync
- Multi-device support
- Coop sitter sharing
- Community features

---

*Spec version 1.0 — December 2024*

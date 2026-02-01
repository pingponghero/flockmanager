# Flock Manager — Empty State Copy

UI copy for empty states throughout the app. Each entry includes headline, body text, and call-to-action button label where applicable.

---

## Flocks

### First Launch / No Flocks

**Headline:** Welcome to Flock Manager

**Body:** Start by creating your first flock. You can organize birds however makes sense—by coop, breed, or just keep everyone together.

**CTA:** Create Your First Flock

---

## Birds

### No Birds in Current Flock

**Headline:** No birds yet

**Body:** Add your chickens to start tracking eggs, health, and more. You can always add details later—just a name is enough to get started.

**CTA:** Add a Bird

### No Birds Anywhere (Global View)

**Headline:** Your flock awaits

**Body:** Once you add your birds, you'll see them here. Track each hen's eggs, health history, and more.

**CTA:** Add Your First Bird

### Filter Returns No Results

**Headline:** No birds match this filter

**Body:** Try adjusting your selection or add a new bird.

**CTA:** Clear Filters

---

## Egg History

### No Eggs Logged (Global)

**Headline:** No eggs logged yet

**Body:** Tap the + button anytime to log today's collection. It takes two seconds, and you'll start seeing trends in no time.

**CTA:** Log Your First Eggs

### No Eggs for Specific Flock

**Headline:** No eggs from this flock

**Body:** Once you log eggs for {flockName}, they'll appear here.

**CTA:** Log Eggs

### No Eggs for Selected Day

**Headline:** Nothing logged for {date}

**Body:** Either the girls took the day off, or you haven't logged yet.

**CTA:** Add Entry for This Day

---

## Analytics

### Insufficient Data

**Headline:** Not enough data yet

**Body:** Keep logging eggs for a few more days and you'll start seeing production trends, top layers, and more.

**CTA:** *(none)*

### Partial Data (Building History)

**Headline:** Building your flock's story

**Body:** You have {dayCount} days of data. Analytics get more useful after a couple weeks of logging.

**CTA:** *(none)*

---

## Expenses

### No Expenses Tracked

**Headline:** No expenses tracked

**Body:** Optional but useful—log feed, supplies, and other costs to see your true cost per egg.

**CTA:** Add an Expense

---

## Income

### No Income Recorded

**Headline:** No income recorded

**Body:** Selling eggs or chicks? Track it here to see if your flock is paying for itself.

**CTA:** Record Income

---

## Medications

### No Medications Logged (Ever)

**Headline:** No medications logged

**Body:** When you treat your flock, log it here to track withdrawal periods and keep your eggs safe.

**CTA:** Log a Treatment

### No Active Treatments (History Exists)

**Headline:** No active treatments

**Body:** Your flock is medication-free. Past treatments are listed below.

**CTA:** *(none)*

---

## Health Notes

### No Notes for Bird

**Headline:** No health notes

**Body:** Use this to track vet visits, symptoms, or anything you want to remember about {birdName}.

**CTA:** Add a Note

---

## Search

### No Results Found

**Headline:** No results found

**Body:** Try different keywords or check your spelling.

**CTA:** Clear Search

---

## Implementation Notes

### Variables

Use these placeholder tokens in the UI code:

| Token | Description | Example |
|-------|-------------|---------|
| `{flockName}` | Current flock's name | "Backyard Girls" |
| `{birdName}` | Current bird's name | "Henrietta" |
| `{date}` | Formatted date | "December 26" |
| `{dayCount}` | Number of days with data | "5" |

### Design Principles

| Principle | Rationale |
|-----------|-----------|
| Short headlines | Mobile screens, scannable |
| One CTA per state | Reduces decision fatigue |
| Acknowledge the empty state | "No eggs yet" vs. showing nothing |
| Light personality | "The girls took the day off" resonates with chicken keepers |
| No guilt-tripping | Avoid "You haven't logged in 5 days!" energy |
| Explain the value | Why track expenses? "See your true cost per egg" |

### Accessibility

- All empty states should have appropriate ARIA labels
- CTA buttons should be large enough for easy tapping (minimum 44x44 pts)
- Ensure sufficient color contrast for body text
- Consider adding simple illustrations (optional, not required for MVP)

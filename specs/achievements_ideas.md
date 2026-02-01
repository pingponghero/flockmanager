# Flock Manager — Achievements & Badge System Ideas

A fun, engaging achievements system to reward users for milestones and encourage continued app usage.

---

## Production Milestones

| Badge | Name | Criteria |
|-------|------|----------|
| 🥚 | **First Egg!** | Log your first egg |
| 🥚🥚 | **Dozen Club** | 12 eggs in a single day |
| 📦 | **Century** | 100 total eggs logged |
| 🏆 | **Thousand Layer** | 1,000 total eggs |
| 💎 | **Golden Flock** | 10,000 lifetime eggs |
| 📈 | **Perfect Week** | 7 consecutive days of logging |
| 🔥 | **On a Roll** | 30-day logging streak |
| ⭐ | **Overachiever** | Single hen exceeds breed's expected annual production |

---

## Flock Diversity

| Badge | Name | Criteria |
|-------|------|----------|
| 🌈 | **Rainbow Basket** | Hens laying 4+ different egg colors |
| 🎨 | **Full Palette** | All egg colors represented (white, cream, brown, blue, green, olive, chocolate) |
| 📚 | **Breed Collector** | 5 different breeds |
| 🦚 | **Flock Diversity** | 10 different breeds |
| 🌍 | **World Tour** | Breeds from 4+ continents of origin |
| ✨ | **Rare Find** | Add an ornamental or rare breed |
| 🐣 | **Easter Every Day** | 3+ Easter Eggers |

---

## Flock Size

| Badge | Name | Criteria |
|-------|------|----------|
| 🐔 | **Starter Flock** | 3 birds |
| 🐓 | **Baker's Dozen** | 13 birds |
| 🏠 | **Full House** | 25 birds |
| 🌾 | **Mini Homestead** | 50 birds |
| 👑 | **Flock Boss** | 100+ birds |
| 🗂️ | **Multi-Manager** | 3+ separate flocks |

---

## Longevity & Care

| Badge | Name | Criteria |
|-------|------|----------|
| 🎂 | **First Birthday** | A bird reaches 1 year old |
| 🎉 | **Senior Hen** | A bird reaches 5 years old |
| 👵 | **Grand Old Girl** | A bird reaches 8 years old |
| 💚 | **Empty Nest Never** | Keep chickens for 2+ continuous years |
| 🏅 | **Dedicated Keeper** | 5 years of chicken keeping |
| 🌟 | **Old Timer** | A bird in your flock for 3+ years |

---

## Financial

| Badge | Name | Criteria |
|-------|------|----------|
| 💰 | **Beat the Store** | Cost per egg below grocery store average (~$0.25) |
| 🤑 | **Basically Free** | Cost per egg below $0.15 |
| 📊 | **Budget Tracker** | Log 10 expenses |
| 💵 | **Side Hustle** | Record your first egg sale income |
| ⚖️ | **Break Even** | Income exceeds expenses for a month |
| 📈 | **In the Black** | Profitable for 3 consecutive months |
| 🧮 | **Know Your Numbers** | Track expenses for 6 months |

---

## Health & Medication

| Badge | Name | Criteria |
|-------|------|----------|
| 💊 | **First Aid** | Log your first medication |
| 🩺 | **Flock Doctor** | Successfully complete 5 medication courses |
| ✅ | **All Clear** | Complete a withdrawal period |
| 📋 | **Health Nut** | Add health notes for all birds |
| 🛡️ | **Prevention Pro** | No medications needed for 6 months |
| 🌿 | **Clean Bill** | Full flock with no active health issues |

---

## Consistency & Engagement

| Badge | Name | Criteria |
|-------|------|----------|
| ☀️ | **Early Bird** | Log eggs before 8 AM |
| 🌙 | **Night Owl** | Log eggs after 9 PM |
| 📆 | **Monthly Regular** | Log eggs every day for a calendar month |
| 🗓️ | **Year-Round Keeper** | Log eggs in all 12 months |
| 🔄 | **Creature of Habit** | Log at the same hour (±30 min) for 7 days |
| 📱 | **Power User** | Use the app 100 days |

---

## Fun & Quirky

| Badge | Name | Criteria |
|-------|------|----------|
| 🎰 | **Double Yolk Day** | Log a double-yolk egg |
| 🤏 | **Fairy Egg** | Log a tiny/abnormal egg |
| 🐣 | **Broody Mama** | Have a hen marked as broody |
| 🦊 | **Survivor** | Bird marked as "predator encounter" in notes survives |
| 📸 | **Photogenic Flock** | Add photos for all birds |
| 🏷️ | **Name Game** | Name 10+ birds |
| 🎭 | **Creative Namer** | Give a bird a name over 15 characters |
| 🔇 | **The Quiet Life** | All hens, no roosters |
| 📣 | **Alarm Clock** | Have a rooster |
| ❄️ | **Winter Warriors** | Log eggs in December, January, and February |
| 🌞 | **Summer Surplus** | 20+ eggs in a single day (peak season) |
| 🦆 | **Plot Twist** | (Easter egg) Name a bird "Duck" |

---

## Seasonal / Special

| Badge | Name | Criteria |
|-------|------|----------|
| 🐰 | **Easter Ready** | Log eggs on Easter Sunday |
| 🦃 | **Thanksgiving Prep** | Log eggs in November |
| 🎄 | **Holiday Helper** | Log eggs on Christmas |
| 🌸 | **Spring Awakening** | First egg after a winter laying pause |
| 🍂 | **Molt Survivor** | Log eggs through October (molting season) |

---

## Implementation Notes

### Data Model

```sql
CREATE TABLE achievements (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  category TEXT NOT NULL,
  criteria_type TEXT NOT NULL,  -- 'count', 'streak', 'date', 'threshold', 'special'
  criteria_value TEXT,          -- JSON with specifics
  sort_order INTEGER DEFAULT 0
);

CREATE TABLE user_achievements (
  id TEXT PRIMARY KEY,
  achievement_id TEXT NOT NULL,
  unlocked_at TEXT NOT NULL,
  notified INTEGER DEFAULT 0,
  progress_value INTEGER,       -- For tracking partial progress
  FOREIGN KEY (achievement_id) REFERENCES achievements(id)
);
```

### Trigger Points

Check achievements on:
- Egg log save → production milestones, streaks, seasonal
- Bird add/edit → flock size, diversity, naming
- Expense/income save → financial badges
- Medication log → health badges
- App open → engagement badges, date-based checks

### Display Ideas

- Dedicated achievements screen with categories
- Locked badges grayed out with "?" or silhouette
- Progress bars for incremental achievements ("47/100 eggs")
- Celebration animation on unlock
- Optional push notification for new achievements

### Shareability

- Generate shareable image cards for achievements
- "I just earned the Golden Flock badge in Flock Manager! 🐔"
- Free marketing when users share on social media

### MVP Priority

**Phase 1 (Launch):**
- First Egg, Century, Thousand Layer
- Starter Flock, Baker's Dozen
- Perfect Week, On a Roll
- Beat the Store

**Phase 2:**
- All diversity badges
- All longevity badges
- Remaining financial badges

**Phase 3:**
- Fun/quirky badges
- Seasonal badges
- Easter eggs

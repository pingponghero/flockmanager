import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/breeds.dart';
import '../models/enums.dart';
import 'bird_provider.dart';
import 'egg_provider.dart';
import 'egg_value_provider.dart';
import 'expense_provider.dart';
import 'flock_provider.dart';
import 'medication_provider.dart';

/// Achievement definition
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final bool Function(AchievementContext ctx) check;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.check,
  });

  /// Description with the user's currency symbol applied.
  /// Descriptions are authored with '$' as the placeholder currency.
  String describeWith(String currencySymbol) =>
      currencySymbol == '\$' ? description : description.replaceAll('\$', currencySymbol);
}

/// Context passed to achievement checks
class AchievementContext {
  // Flock & Birds
  final int activeBirdCount;
  final int totalBirdCount;
  final int flockCount;
  final int breedCount;
  final Set<String> eggColors;
  final int birdsWithPhotos;
  final int birdsOver1Year;
  final int birdsOver3Years;
  final int birdsOver5Years;
  final int birdsOver8Years;
  final int longestNameLength;
  final bool hasBirdNamedDuck;
  final int easterEggerCount;

  // Eggs
  final int totalEggs;
  final int maxEggsInOneDay;
  final int maxEggsInSummer; // Max eggs in a day during June/July/August
  final int loggingStreakDays;
  final Set<int> monthsWithEggs; // 1-12
  final int februaryEggs;
  final int marchEggs;
  final bool loggedBeforeSix;
  final bool loggedAfterNine;
  final bool hasDoubleYolk;
  final bool hasFairyEgg;
  final bool hasAbnormalEgg;
  final bool hasChristmasEggs; // Logged eggs on Dec 25

  // Breed-related
  final bool hasOrnamentalBreed;
  final bool hasOverachiever; // Bird exceeded breed's expected annual production
  final bool hasRooster;
  final bool hasChickenRooster; // Male chicken specifically (for "Alarm Clock")
  final bool allHens; // All birds are hens (no roosters)

  // Financial
  final double totalExpenses;
  final double totalIncome;
  final double? costPerEgg;
  final double netSavings; // eggProductionValue - totalExpenses
  final double? netCostPerDozen; // (expenses - income) / eggsConsumed * 12
  final double retailPricePerDozen;
  final int expenseCount;
  final int incomeCount;

  // Gifting
  final int giftedEggs;
  final int giftRecipientCount;

  // Health
  final int medicationLogCount;
  final int completedMedicationCount;
  final int birdsWithHealthNotes;
  final bool hasActiveWithdrawal;

  // Time-based
  final int daysUsingApp;
  final int yearsKeepingChickens;

  const AchievementContext({
    required this.activeBirdCount,
    required this.totalBirdCount,
    required this.flockCount,
    required this.breedCount,
    required this.eggColors,
    required this.birdsWithPhotos,
    required this.birdsOver1Year,
    required this.birdsOver3Years,
    required this.birdsOver5Years,
    required this.birdsOver8Years,
    required this.longestNameLength,
    required this.hasBirdNamedDuck,
    required this.easterEggerCount,
    required this.totalEggs,
    required this.maxEggsInOneDay,
    required this.maxEggsInSummer,
    required this.loggingStreakDays,
    required this.monthsWithEggs,
    required this.februaryEggs,
    required this.marchEggs,
    required this.loggedBeforeSix,
    required this.loggedAfterNine,
    required this.hasDoubleYolk,
    required this.hasFairyEgg,
    required this.hasAbnormalEgg,
    required this.hasChristmasEggs,
    required this.hasOrnamentalBreed,
    required this.hasOverachiever,
    required this.hasRooster,
    required this.hasChickenRooster,
    required this.allHens,
    required this.totalExpenses,
    required this.totalIncome,
    required this.costPerEgg,
    required this.netSavings,
    required this.netCostPerDozen,
    required this.retailPricePerDozen,
    required this.expenseCount,
    required this.incomeCount,
    this.giftedEggs = 0,
    this.giftRecipientCount = 0,
    required this.medicationLogCount,
    required this.completedMedicationCount,
    required this.birdsWithHealthNotes,
    required this.hasActiveWithdrawal,
    required this.daysUsingApp,
    required this.yearsKeepingChickens,
  });
}

/// All available achievements organized by category
final achievements = <Achievement>[
  // ==================== PRODUCTION MILESTONES ====================
  Achievement(
    id: 'first_egg',
    name: 'First Egg!',
    description: 'Log your first egg',
    icon: Icons.egg_outlined,
    color: Colors.amber,
    category: 'Layer Legends',
    check: (ctx) => ctx.totalEggs >= 1,
  ),
  Achievement(
    id: 'dozen_club',
    name: 'Dozen Club',
    description: '12 eggs in a single day',
    icon: Icons.egg,
    color: Colors.orange,
    category: 'Layer Legends',
    check: (ctx) => ctx.maxEggsInOneDay >= 12,
  ),
  Achievement(
    id: 'century_mark',
    name: 'Century',
    description: '100 total eggs logged',
    icon: Icons.looks_one,
    color: Colors.deepOrange,
    category: 'Layer Legends',
    check: (ctx) => ctx.totalEggs >= 100,
  ),
  Achievement(
    id: 'thousand_layer',
    name: 'Thousand Layer',
    description: '1,000 total eggs',
    icon: Icons.military_tech,
    color: Colors.amber,
    category: 'Layer Legends',
    check: (ctx) => ctx.totalEggs >= 1000,
  ),
  Achievement(
    id: 'golden_flock',
    name: 'Golden Flock',
    description: '10,000 lifetime eggs',
    icon: Icons.diamond,
    color: Colors.yellow,
    category: 'Layer Legends',
    check: (ctx) => ctx.totalEggs >= 10000,
  ),
  Achievement(
    id: 'perfect_week',
    name: 'Perfect Week',
    description: '7 consecutive days of logging',
    icon: Icons.calendar_view_week,
    color: Colors.blue,
    category: 'Layer Legends',
    check: (ctx) => ctx.loggingStreakDays >= 7,
  ),
  Achievement(
    id: 'on_a_roll',
    name: 'On a Roll',
    description: '30-day logging streak',
    icon: Icons.local_fire_department,
    color: Colors.deepOrange,
    category: 'Layer Legends',
    check: (ctx) => ctx.loggingStreakDays >= 30,
  ),
  Achievement(
    id: 'summer_surplus',
    name: 'Summer Surplus',
    description: '20+ eggs in a summer day (Jun-Aug)',
    icon: Icons.wb_sunny,
    color: Colors.orange,
    category: 'Layer Legends',
    check: (ctx) => ctx.maxEggsInSummer >= 20,
  ),

  // ==================== FLOCK DIVERSITY ====================
  Achievement(
    id: 'rainbow_basket',
    name: 'Rainbow Basket',
    description: 'Hens laying 4+ different egg colors',
    icon: Icons.palette,
    color: Colors.purple,
    category: 'Variety Show',
    check: (ctx) => ctx.eggColors.length >= 4,
  ),
  Achievement(
    id: 'full_palette',
    name: 'Full Palette',
    description: 'All 7 egg colors represented',
    icon: Icons.brush,
    color: Colors.deepPurple,
    category: 'Variety Show',
    check: (ctx) => ctx.eggColors.length >= 7,
  ),
  Achievement(
    id: 'breed_collector',
    name: 'Breed Collector',
    description: '5 different breeds',
    icon: Icons.collections,
    color: Colors.indigo,
    category: 'Variety Show',
    check: (ctx) => ctx.breedCount >= 5,
  ),
  Achievement(
    id: 'flock_diversity',
    name: 'Breed Baron',
    description: '10 different breeds',
    icon: Icons.diversity_3,
    color: Colors.teal,
    category: 'Variety Show',
    check: (ctx) => ctx.breedCount >= 10,
  ),
  Achievement(
    id: 'easter_every_day',
    name: 'Easter Every Day',
    description: '3+ Easter Eggers',
    icon: Icons.egg_alt,
    color: Colors.lightBlue,
    category: 'Variety Show',
    check: (ctx) => ctx.easterEggerCount >= 3,
  ),
  Achievement(
    id: 'rare_find',
    name: 'Rare Find',
    description: 'Add an ornamental breed',
    icon: Icons.auto_awesome,
    color: Colors.deepPurple,
    category: 'Variety Show',
    check: (ctx) => ctx.hasOrnamentalBreed,
  ),
  Achievement(
    id: 'overachiever',
    name: 'Overachiever',
    description: "A hen exceeds her breed's expected production",
    icon: Icons.star,
    color: Colors.amber,
    category: 'Variety Show',
    check: (ctx) => ctx.hasOverachiever,
  ),

  // ==================== FLOCK SIZE ====================
  Achievement(
    id: 'starter_flock',
    name: 'Starter Flock',
    description: '3 birds',
    icon: Icons.egg,
    color: Colors.brown,
    category: 'The More the Merrier',
    check: (ctx) => ctx.activeBirdCount >= 3,
  ),
  Achievement(
    id: 'bakers_dozen',
    name: "Baker's Dozen",
    description: '13 birds',
    icon: Icons.bakery_dining,
    color: Colors.green,
    category: 'The More the Merrier',
    check: (ctx) => ctx.activeBirdCount >= 13,
  ),
  Achievement(
    id: 'full_house',
    name: 'Full House',
    description: '25 birds',
    icon: Icons.home,
    color: Colors.blue,
    category: 'The More the Merrier',
    check: (ctx) => ctx.activeBirdCount >= 25,
  ),
  Achievement(
    id: 'mini_homestead',
    name: 'Mini Homestead',
    description: '50 birds',
    icon: Icons.agriculture,
    color: Colors.amber,
    category: 'The More the Merrier',
    check: (ctx) => ctx.activeBirdCount >= 50,
  ),
  Achievement(
    id: 'flock_boss',
    name: 'Flock Boss',
    description: '100+ birds',
    icon: Icons.workspace_premium,
    color: Colors.red,
    category: 'The More the Merrier',
    check: (ctx) => ctx.activeBirdCount >= 100,
  ),
  Achievement(
    id: 'multi_manager',
    name: 'Multi-Manager',
    description: '3+ separate flocks',
    icon: Icons.folder_copy,
    color: Colors.blueGrey,
    category: 'The More the Merrier',
    check: (ctx) => ctx.flockCount >= 3,
  ),

  // ==================== LONGEVITY & CARE ====================
  Achievement(
    id: 'first_birthday',
    name: 'First Birthday',
    description: 'A bird reaches 1 year old',
    icon: Icons.cake,
    color: Colors.pink,
    category: 'Golden Years',
    check: (ctx) => ctx.birdsOver1Year >= 1,
  ),
  Achievement(
    id: 'senior_hen',
    name: 'Senior Hen',
    description: 'A bird reaches 5 years old',
    icon: Icons.elderly,
    color: Colors.purple,
    category: 'Golden Years',
    check: (ctx) => ctx.birdsOver5Years >= 1,
  ),
  Achievement(
    id: 'grand_old_girl',
    name: 'Grand Old Girl',
    description: 'A bird reaches 8 years old',
    icon: Icons.star,
    color: Colors.amber,
    category: 'Golden Years',
    check: (ctx) => ctx.birdsOver8Years >= 1,
  ),
  Achievement(
    id: 'dedicated_keeper',
    name: 'Dedicated Keeper',
    description: '5 years of chicken keeping',
    icon: Icons.verified,
    color: Colors.green,
    category: 'Golden Years',
    check: (ctx) => ctx.yearsKeepingChickens >= 5,
  ),

  // ==================== FINANCIAL ====================
  Achievement(
    id: 'beat_the_store',
    name: 'Beat the Store',
    description: 'Egg value exceeds expenses',
    icon: Icons.local_grocery_store,
    color: Colors.green,
    category: 'Nest Egg',
    check: (ctx) => ctx.netSavings >= 0 && ctx.totalEggs >= 50 && ctx.totalExpenses > 0,
  ),
  Achievement(
    id: 'basically_free',
    name: 'Basically Free',
    description: 'Cost per egg below \$0.15',
    icon: Icons.savings,
    color: Colors.lightGreen,
    category: 'Nest Egg',
    check: (ctx) => ctx.costPerEgg != null && ctx.costPerEgg! < 0.15 && ctx.totalEggs >= 100,
  ),
  Achievement(
    id: 'budget_tracker',
    name: 'Budget Tracker',
    description: 'Log 10 expenses',
    icon: Icons.receipt_long,
    color: Colors.blueGrey,
    category: 'Nest Egg',
    check: (ctx) => ctx.expenseCount >= 10,
  ),
  Achievement(
    id: 'side_hustle',
    name: 'Side Hustle',
    description: 'Earn \$20+ from egg sales',
    icon: Icons.attach_money,
    color: Colors.green,
    category: 'Nest Egg',
    check: (ctx) => ctx.totalIncome >= 20,
  ),
  Achievement(
    id: 'in_the_black',
    name: 'In the Black',
    description: 'Total income exceeds expenses',
    icon: Icons.trending_up,
    color: Colors.teal,
    category: 'Nest Egg',
    check: (ctx) => ctx.totalIncome > ctx.totalExpenses && ctx.totalIncome > 50 && ctx.totalExpenses > 0,
  ),
  Achievement(
    id: 'first_gift',
    name: 'Sharing the Bounty',
    description: 'Gift your first eggs',
    icon: Icons.card_giftcard,
    color: Colors.pink,
    category: 'Nest Egg',
    check: (ctx) => ctx.giftedEggs >= 1,
  ),
  Achievement(
    id: 'gift_basket',
    name: 'Gift Basket',
    description: '100 eggs gifted',
    icon: Icons.redeem,
    color: Colors.purple,
    category: 'Nest Egg',
    check: (ctx) => ctx.giftedEggs >= 100,
  ),
  Achievement(
    id: 'community_coop',
    name: 'Community Coop',
    description: 'Gift eggs to 3+ different recipients',
    icon: Icons.diversity_1,
    color: Colors.orange,
    category: 'Nest Egg',
    check: (ctx) => ctx.giftRecipientCount >= 3,
  ),

  // ==================== HEALTH & MEDICATION ====================
  Achievement(
    id: 'first_aid',
    name: 'First Aid',
    description: 'Log your first medication',
    icon: Icons.medical_services,
    color: Colors.red,
    category: 'Flock Doc',
    check: (ctx) => ctx.medicationLogCount >= 1,
  ),
  Achievement(
    id: 'flock_doctor',
    name: 'Flock Doctor',
    description: 'Complete 5 medication courses',
    icon: Icons.healing,
    color: Colors.pink,
    category: 'Flock Doc',
    check: (ctx) => ctx.completedMedicationCount >= 5,
  ),
  Achievement(
    id: 'all_clear',
    name: 'All Clear',
    description: 'Complete a withdrawal period',
    icon: Icons.check_circle,
    color: Colors.green,
    category: 'Flock Doc',
    check: (ctx) => ctx.completedMedicationCount >= 1,
  ),

  // ==================== CONSISTENCY & ENGAGEMENT ====================
  Achievement(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Log eggs before 6 AM',
    icon: Icons.wb_twilight,
    color: Colors.orange,
    category: 'Star Keeper',
    check: (ctx) => ctx.loggedBeforeSix,
  ),
  Achievement(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Log eggs after 9 PM',
    icon: Icons.nightlight,
    color: Colors.indigo,
    category: 'Star Keeper',
    check: (ctx) => ctx.loggedAfterNine,
  ),
  Achievement(
    id: 'year_round_keeper',
    name: 'Year-Round Keeper',
    description: 'Log eggs in all 12 months',
    icon: Icons.calendar_month,
    color: Colors.blue,
    category: 'Star Keeper',
    check: (ctx) => ctx.monthsWithEggs.length >= 12,
  ),
  Achievement(
    id: 'power_user',
    name: 'Power User',
    description: 'Use the app 100 days',
    icon: Icons.phone_android,
    color: Colors.deepPurple,
    category: 'Star Keeper',
    check: (ctx) => ctx.daysUsingApp >= 100,
  ),

  // ==================== FUN & QUIRKY ====================
  Achievement(
    id: 'photogenic_flock',
    name: 'Photogenic Flock',
    description: 'Add photos for all birds',
    icon: Icons.photo_camera,
    color: Colors.pink,
    category: 'Just for Clucks',
    check: (ctx) => ctx.activeBirdCount > 4 && ctx.birdsWithPhotos == ctx.activeBirdCount,
  ),
  Achievement(
    id: 'name_game',
    name: 'Name Game',
    description: 'Name 10+ birds',
    icon: Icons.badge,
    color: Colors.teal,
    category: 'Just for Clucks',
    check: (ctx) => ctx.totalBirdCount >= 10,
  ),
  Achievement(
    id: 'creative_namer',
    name: 'Creative Namer',
    description: 'Give a bird a name over 15 characters',
    icon: Icons.text_fields,
    color: Colors.purple,
    category: 'Just for Clucks',
    check: (ctx) => ctx.longestNameLength > 15 && ctx.totalBirdCount >= 3,
  ),
  Achievement(
    id: 'plot_twist',
    name: 'Plot Twist',
    description: 'Name a bird "Duck"',
    icon: Icons.sentiment_very_satisfied,
    color: Colors.yellow,
    category: 'Just for Clucks',
    check: (ctx) => ctx.hasBirdNamedDuck,
  ),
  Achievement(
    id: 'double_yolk_day',
    name: 'Double Yolk Day',
    description: 'Log a double-yolk egg',
    icon: Icons.looks_two,
    color: Colors.amber,
    category: 'Just for Clucks',
    check: (ctx) => ctx.hasDoubleYolk,
  ),
  Achievement(
    id: 'fairy_egg',
    name: 'Fairy Egg',
    description: 'Log a tiny fairy egg',
    icon: Icons.auto_awesome,
    color: Colors.pink,
    category: 'Just for Clucks',
    check: (ctx) => ctx.hasFairyEgg,
  ),
  Achievement(
    id: 'the_quiet_life',
    name: 'The Quiet Life',
    description: 'All females, no males (3+ birds)',
    icon: Icons.volume_off,
    color: Colors.teal,
    category: 'Just for Clucks',
    check: (ctx) => ctx.daysUsingApp >= 14 && ctx.activeBirdCount >= 3 && ctx.allHens,
  ),
  Achievement(
    id: 'alarm_clock',
    name: 'Alarm Clock',
    description: 'Have a rooster in your flock',
    icon: Icons.alarm,
    color: Colors.orange,
    category: 'Just for Clucks',
    check: (ctx) => ctx.hasChickenRooster && ctx.daysUsingApp >= 7,
  ),
  Achievement(
    id: 'winter_warriors',
    name: 'Winter Warriors',
    description: 'Log eggs in Dec, Jan, and Feb',
    icon: Icons.ac_unit,
    color: Colors.lightBlue,
    category: 'Just for Clucks',
    check: (ctx) => ctx.monthsWithEggs.contains(12) &&
                     ctx.monthsWithEggs.contains(1) &&
                     ctx.monthsWithEggs.contains(2) &&
                     ctx.totalEggs >= 30,
  ),

  // ==================== SEASONAL ====================
  Achievement(
    id: 'thanksgiving_prep',
    name: 'Turkey Time',
    description: 'Log eggs in November',
    icon: Icons.restaurant,
    color: Colors.orange,
    category: 'Four Seasons',
    check: (ctx) => ctx.monthsWithEggs.contains(11) && ctx.totalEggs >= 50,
  ),
  Achievement(
    id: 'holiday_helper',
    name: "Santa's Omelet",
    description: 'Log eggs on Christmas Day',
    icon: Icons.egg_alt,
    color: Colors.red,
    category: 'Four Seasons',
    check: (ctx) => ctx.hasChristmasEggs,
  ),
  Achievement(
    id: 'spring_awakening',
    name: 'Spring Awakening',
    description: 'More eggs in March than February',
    icon: Icons.local_florist,
    color: Colors.pink,
    category: 'Four Seasons',
    check: (ctx) => ctx.marchEggs > ctx.februaryEggs && ctx.februaryEggs >= 10,
  ),
  Achievement(
    id: 'molt_survivor',
    name: 'Molt Survivor',
    description: 'Log eggs through October (molting season)',
    icon: Icons.autorenew,
    color: Colors.brown,
    category: 'Four Seasons',
    check: (ctx) => ctx.monthsWithEggs.contains(10) && ctx.totalEggs >= 50,
  ),
];

/// Provider for earned achievements
final earnedAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final context = await ref.watch(_achievementContextProvider.future);
  final earned = achievements.where((a) => a.check(context)).toList();
  // Keep the earned-date record in sync: stamps newly earned achievements
  // with today, drops ones that are no longer earned (e.g. after a data
  // correction revoked them).
  await AchievementTracker.instance
      .recordEarned(earned.map((a) => a.id).toSet());
  return earned;
});

/// Provider for achievement count summary
final achievementSummaryProvider = FutureProvider<({int earned, int total})>((ref) async {
  final earned = await ref.watch(earnedAchievementsProvider.future);
  return (earned: earned.length, total: achievements.length);
});

/// Provider for the most recently earned achievement (for home screen widget)
final latestAchievementProvider = FutureProvider<Achievement?>((ref) async {
  final earned = await ref.watch(earnedAchievementsProvider.future);
  if (earned.isEmpty) return null;
  // Pick the achievement with the newest recorded earned date. Achievements
  // earned before dates were tracked share the same first-run timestamp;
  // ties keep definition order (last wins) for stability.
  final earnedDates = await AchievementTracker.instance.getEarnedDates();
  Achievement latest = earned.first;
  DateTime? latestDate = earnedDates[latest.id];
  for (final a in earned.skip(1)) {
    final date = earnedDates[a.id];
    if (latestDate == null ||
        (date != null && !date.isBefore(latestDate))) {
      latest = a;
      latestDate = date ?? latestDate;
    }
  }
  return latest;
});

/// Provider exposing the recorded earned date per achievement id.
final achievementEarnedDatesProvider =
    FutureProvider<Map<String, DateTime>>((ref) async {
  // Depend on earned achievements so dates refresh after recomputation.
  await ref.watch(earnedAchievementsProvider.future);
  return AchievementTracker.instance.getEarnedDates();
});

/// Provider for achievements grouped by category
final achievementsByCategoryProvider = FutureProvider<Map<String, List<({Achievement achievement, bool earned})>>>((ref) async {
  final earnedList = await ref.watch(earnedAchievementsProvider.future);
  final earnedIds = earnedList.map((a) => a.id).toSet();

  final grouped = <String, List<({Achievement achievement, bool earned})>>{};
  for (final achievement in achievements) {
    grouped.putIfAbsent(achievement.category, () => []);
    grouped[achievement.category]!.add((
      achievement: achievement,
      earned: earnedIds.contains(achievement.id),
    ));
  }
  return grouped;
});

/// Progress data for incremental achievements
class AchievementProgress {
  final int current;
  final int target;

  const AchievementProgress(this.current, this.target);

  double get percent => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  bool get isComplete => current >= target;
}

/// Provider for achievement progress data
final achievementProgressProvider = FutureProvider<Map<String, AchievementProgress>>((ref) async {
  final context = await ref.watch(_achievementContextProvider.future);

  return {
    // Production milestones - egg counts
    'first_egg': AchievementProgress(context.totalEggs, 1),
    'century_mark': AchievementProgress(context.totalEggs, 100),
    'thousand_layer': AchievementProgress(context.totalEggs, 1000),
    'golden_flock': AchievementProgress(context.totalEggs, 10000),

    // Production - daily records
    'dozen_club': AchievementProgress(context.maxEggsInOneDay, 12),
    'summer_surplus': AchievementProgress(context.maxEggsInSummer, 20),

    // Production - streaks
    'perfect_week': AchievementProgress(context.loggingStreakDays, 7),
    'on_a_roll': AchievementProgress(context.loggingStreakDays, 30),

    // Diversity
    'rainbow_basket': AchievementProgress(context.eggColors.length, 4),
    'full_palette': AchievementProgress(context.eggColors.length, 7),
    'breed_collector': AchievementProgress(context.breedCount, 5),
    'flock_diversity': AchievementProgress(context.breedCount, 10),
    'easter_every_day': AchievementProgress(context.easterEggerCount, 3),

    // Flock size
    'starter_flock': AchievementProgress(context.activeBirdCount, 3),
    'bakers_dozen': AchievementProgress(context.activeBirdCount, 13),
    'full_house': AchievementProgress(context.activeBirdCount, 25),
    'mini_homestead': AchievementProgress(context.activeBirdCount, 50),
    'flock_boss': AchievementProgress(context.activeBirdCount, 100),
    'multi_manager': AchievementProgress(context.flockCount, 3),

    // Financial
    'budget_tracker': AchievementProgress(context.expenseCount, 10),

    // Gifting
    'first_gift': AchievementProgress(context.giftedEggs, 1),
    'gift_basket': AchievementProgress(context.giftedEggs, 100),
    'community_coop': AchievementProgress(context.giftRecipientCount, 3),

    // Health
    'flock_doctor': AchievementProgress(context.completedMedicationCount, 5),

    // Engagement
    'year_round_keeper': AchievementProgress(context.monthsWithEggs.length, 12),
    'power_user': AchievementProgress(context.daysUsingApp, 100),
    'name_game': AchievementProgress(context.totalBirdCount, 10),
  };
});

/// Internal provider that gathers all data needed for achievement checks
final _achievementContextProvider = FutureProvider<AchievementContext>((ref) async {
  // Gather all the data we need
  final birds = await ref.watch(activeBirdsProvider.future);
  final allBirds = await ref.watch(birdsProvider.future);
  final flocks = await ref.watch(flocksProvider.future);
  final totalEggs = await ref.watch(totalEggCountProvider.future);
  final totalExpenses = await ref.watch(totalExpensesProvider.future);
  final totalIncome = await ref.watch(totalIncomeProvider.future);
  final costPerEgg = await ref.watch(costPerEggProvider.future);
  final eggValueSummary = await ref.watch(allTimeEggValueProvider.future);
  final activeWithdrawals = await ref.watch(activeWithdrawalsProvider.future);

  // Get repositories for additional queries
  final eggRepo = ref.read(eggRepositoryProvider);
  final expenseRepo = ref.read(financeRepositoryProvider);

  // Calculate breed count (unique non-null breeds)
  final breeds = birds
      .map((b) => b.breed)
      .where((b) => b != null && b.isNotEmpty)
      .toSet();

  // Calculate egg colors
  final eggColors = birds
      .map((b) => b.eggColor?.toLowerCase())
      .where((c) => c != null && c.isNotEmpty)
      .toSet()
      .cast<String>();

  // Count Easter Eggers
  final easterEggerCount = birds.where((b) =>
    b.breed?.toLowerCase().contains('easter egger') == true ||
    b.breedId?.contains('easter_egger') == true
  ).length;

  // Calculate bird ages
  final now = DateTime.now();
  int birdsOver1Year = 0;
  int birdsOver3Years = 0;
  int birdsOver5Years = 0;
  int birdsOver8Years = 0;
  int birdsWithPhotos = 0;
  int longestNameLength = 0;
  bool hasBirdNamedDuck = false;
  DateTime? oldestBirdDate;

  for (final bird in birds) {
    if (bird.photoPrimary != null) birdsWithPhotos++;
    if (bird.name.length > longestNameLength) longestNameLength = bird.name.length;
    if (bird.name.toLowerCase() == 'duck') hasBirdNamedDuck = true;

    if (bird.hatchDate != null) {
      final ageDays = now.difference(bird.hatchDate!).inDays;
      if (ageDays >= 365) birdsOver1Year++;
      if (ageDays >= 365 * 3) birdsOver3Years++;
      if (ageDays >= 365 * 5) birdsOver5Years++;
      if (ageDays >= 365 * 8) birdsOver8Years++;

      if (oldestBirdDate == null || bird.hatchDate!.isBefore(oldestBirdDate)) {
        oldestBirdDate = bird.hatchDate;
      }
    }
  }

  // Calculate years keeping chickens (from oldest bird or first flock)
  DateTime? startDate = oldestBirdDate;
  for (final flock in flocks) {
    if (startDate == null || flock.createdAt.isBefore(startDate)) {
      startDate = flock.createdAt;
    }
  }
  final yearsKeeping = startDate != null
      ? (now.difference(startDate).inDays / 365).floor()
      : 0;

  // Get egg logging stats
  final maxEggsInOneDay = await eggRepo.getMaxEggsInOneDay();
  final maxEggsInSummer = await eggRepo.getMaxEggsInSummer();
  final loggingStreak = await eggRepo.getCurrentLoggingStreak();
  final monthsWithEggs = await eggRepo.getMonthsWithEggs();
  final februaryEggs = await eggRepo.getTotalEggsForMonth(2);
  final marchEggs = await eggRepo.getTotalEggsForMonth(3);
  final hasEarlyLog = await eggRepo.hasLogBeforeHour(6);
  final hasLateLog = await eggRepo.hasLogAfterHour(21);
  final daysWithLogs = await eggRepo.getDistinctLogDays();
  final hasDoubleYolk = await eggRepo.hasDoubleYolkEgg();
  final hasFairyEgg = await eggRepo.hasFairyEgg();
  final hasAbnormalEgg = await eggRepo.hasAbnormalEgg();
  final hasChristmasEggs = await eggRepo.hasChristmasEggs();

  // Check for ornamental breeds, overachievers, and rooster status
  bool hasOrnamentalBreed = false;
  bool hasOverachiever = false;
  bool hasRooster = false;
  bool hasChickenRooster = false;
  bool allHens = true;

  for (final bird in birds) {
    // Check sex
    if (bird.isRooster) {
      hasRooster = true;
      allHens = false;
      if (bird.isChicken) {
        hasChickenRooster = true;
      }
    } else if (bird.sex == BirdSex.unknown) {
      allHens = false; // Unknown sex doesn't count as hen for "The Quiet Life"
    }

    if (bird.breedId != null) {
      final breed = getBreedById(bird.breedId!);
      if (breed != null) {
        if (breed.category == BreedCategory.ornamental) {
          hasOrnamentalBreed = true;
        }
        // Check if bird's eggs exceed breed's expected annual production
        if (bird.hatchDate != null) {
          final birdEggs = await eggRepo.getTotalEggCountByBird(bird.id);
          final yearsOld = now.difference(bird.hatchDate!).inDays / 365;
          if (yearsOld > 0 && birdEggs > breed.eggsPerYearMax * yearsOld) {
            hasOverachiever = true;
          }
        }
      }
    }
  }

  // Get expense/income counts
  final expenses = await expenseRepo.getAllExpenses();
  final incomes = await expenseRepo.getAllIncome();

  // Gifting stats
  final giftedEggs = await expenseRepo.getEggsGiftedAllTime();
  final giftRecipientCount = await expenseRepo.getGiftRecipientCount();

  // Get medication stats
  final medications = await ref.watch(medicationsProvider.future);
  final completedMeds = medications.where((m) =>
    m.endDate != null && m.endDate!.isBefore(now)
  ).length;

  // Count birds with health notes
  final medRepo = ref.read(medicationRepositoryProvider);
  final birdsWithHealthNotes = await medRepo.getBirdsWithHealthNotesCount();

  return AchievementContext(
    activeBirdCount: birds.length,
    totalBirdCount: allBirds.length,
    flockCount: flocks.length,
    breedCount: breeds.length,
    eggColors: eggColors,
    birdsWithPhotos: birdsWithPhotos,
    birdsOver1Year: birdsOver1Year,
    birdsOver3Years: birdsOver3Years,
    birdsOver5Years: birdsOver5Years,
    birdsOver8Years: birdsOver8Years,
    longestNameLength: longestNameLength,
    hasBirdNamedDuck: hasBirdNamedDuck,
    easterEggerCount: easterEggerCount,
    totalEggs: totalEggs,
    maxEggsInOneDay: maxEggsInOneDay,
    maxEggsInSummer: maxEggsInSummer,
    loggingStreakDays: loggingStreak,
    monthsWithEggs: monthsWithEggs,
    februaryEggs: februaryEggs,
    marchEggs: marchEggs,
    loggedBeforeSix: hasEarlyLog,
    loggedAfterNine: hasLateLog,
    hasDoubleYolk: hasDoubleYolk,
    hasFairyEgg: hasFairyEgg,
    hasAbnormalEgg: hasAbnormalEgg,
    hasChristmasEggs: hasChristmasEggs,
    hasOrnamentalBreed: hasOrnamentalBreed,
    hasOverachiever: hasOverachiever,
    hasRooster: hasRooster,
    hasChickenRooster: hasChickenRooster,
    allHens: allHens,
    totalExpenses: totalExpenses,
    totalIncome: totalIncome,
    costPerEgg: costPerEgg,
    netSavings: eggValueSummary.netSavings,
    netCostPerDozen: eggValueSummary.netCostPerDozen,
    retailPricePerDozen: eggValueSummary.retailPricePerDozen,
    expenseCount: expenses.length,
    incomeCount: incomes.length,
    giftedEggs: giftedEggs,
    giftRecipientCount: giftRecipientCount,
    medicationLogCount: medications.length,
    completedMedicationCount: completedMeds,
    birdsWithHealthNotes: birdsWithHealthNotes,
    hasActiveWithdrawal: activeWithdrawals.isNotEmpty,
    daysUsingApp: daysWithLogs,
    yearsKeepingChickens: yearsKeeping,
  );
});

// ==================== ACHIEVEMENT TRACKING ====================

const _shownAchievementsKey = 'shown_achievement_ids';
const _earnedDatesKey = 'achievement_earned_dates';

/// Service for tracking which achievements have been shown to the user
/// and when each achievement was first observed as earned.
class AchievementTracker {
  AchievementTracker._();

  static final instance = AchievementTracker._();

  Set<String>? _shownIds;
  Map<String, DateTime>? _earnedDates;

  /// Load the set of shown achievement IDs from storage.
  Future<Set<String>> _loadShownIds() async {
    if (_shownIds != null) return _shownIds!;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_shownAchievementsKey) ?? [];
    _shownIds = ids.toSet();
    return _shownIds!;
  }

  /// Mark an achievement as shown.
  Future<void> markAsShown(String achievementId) async {
    final shown = await _loadShownIds();
    shown.add(achievementId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shownAchievementsKey, shown.toList());
  }

  /// Mark multiple achievements as shown.
  Future<void> markAllAsShown(List<String> achievementIds) async {
    final shown = await _loadShownIds();
    shown.addAll(achievementIds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shownAchievementsKey, shown.toList());
  }

  /// Get achievements that are earned but not yet shown to user.
  Future<List<Achievement>> getNewlyUnlocked(
    List<Achievement> earnedAchievements,
  ) async {
    final shown = await _loadShownIds();
    return earnedAchievements
        .where((a) => !shown.contains(a.id))
        .toList();
  }

  /// Check if there are any new achievements to show.
  Future<bool> hasNewAchievements(List<Achievement> earnedAchievements) async {
    final newOnes = await getNewlyUnlocked(earnedAchievements);
    return newOnes.isNotEmpty;
  }

  /// Load recorded earned dates (achievement id -> date first seen earned).
  Future<Map<String, DateTime>> getEarnedDates() async {
    if (_earnedDates != null) return Map.of(_earnedDates!);
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_earnedDatesKey) ?? [];
    final dates = <String, DateTime>{};
    for (final entry in entries) {
      final sep = entry.indexOf('|');
      if (sep <= 0) continue;
      final date = DateTime.tryParse(entry.substring(sep + 1));
      if (date != null) {
        dates[entry.substring(0, sep)] = date;
      }
    }
    _earnedDates = dates;
    return Map.of(dates);
  }

  /// Sync the earned-date record with the currently earned achievement ids.
  /// New ids are stamped with now; ids no longer earned are removed so a
  /// re-earned achievement gets a fresh date.
  Future<void> recordEarned(Set<String> earnedIds) async {
    final dates = await getEarnedDates();
    var changed = false;
    final now = DateTime.now();

    for (final id in earnedIds) {
      if (!dates.containsKey(id)) {
        dates[id] = now;
        changed = true;
      }
    }
    final revoked = dates.keys.where((id) => !earnedIds.contains(id)).toList();
    for (final id in revoked) {
      dates.remove(id);
      changed = true;
    }

    if (changed) {
      _earnedDates = dates;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _earnedDatesKey,
        dates.entries
            .map((e) => '${e.key}|${e.value.toIso8601String()}')
            .toList(),
      );
    }
  }

  /// Clear all shown achievements (for testing).
  Future<void> clearAll() async {
    _shownIds = {};
    _earnedDates = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shownAchievementsKey);
    await prefs.remove(_earnedDatesKey);
  }
}

/// Provider for newly unlocked achievements (earned but not yet celebrated).
final newlyUnlockedAchievementsProvider =
    FutureProvider<List<Achievement>>((ref) async {
  final earned = await ref.watch(earnedAchievementsProvider.future);
  return AchievementTracker.instance.getNewlyUnlocked(earned);
});

/// Check for new achievements and show celebration dialogs.
/// Call this after key trigger points (egg save, bird save, etc.)
/// Returns the list of newly unlocked achievements (not yet marked as shown).
/// IMPORTANT: Caller must call markAchievementsAsShown() after displaying dialogs.
Future<List<Achievement>> checkAndCelebrateAchievements(
  WidgetRef ref,
  BuildContext context,
) async {
  // Force refresh of achievement context
  ref.invalidate(_achievementContextProvider);
  ref.invalidate(earnedAchievementsProvider);

  // Wait for the new earned achievements
  final earned = await ref.read(earnedAchievementsProvider.future);

  // Get newly unlocked ones (earned but not yet shown)
  final newlyUnlocked = await AchievementTracker.instance.getNewlyUnlocked(earned);

  return newlyUnlocked;
}

/// Mark achievements as shown after celebration dialog is displayed.
Future<void> markAchievementsAsShown(List<Achievement> achievements) async {
  if (achievements.isNotEmpty) {
    await AchievementTracker.instance.markAllAsShown(
      achievements.map((a) => a.id).toList(),
    );
  }
}

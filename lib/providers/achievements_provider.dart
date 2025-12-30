import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/breeds.dart';
import '../models/enums.dart';
import 'bird_provider.dart';
import 'egg_provider.dart';
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
  final int loggingStreakDays;
  final Set<int> monthsWithEggs; // 1-12
  final bool loggedBeforeEight;
  final bool loggedAfterNine;
  final bool hasDoubleYolk;
  final bool hasAbnormalEgg;

  // Breed-related
  final bool hasOrnamentalBreed;
  final bool hasOverachiever; // Bird exceeded breed's expected annual production
  final bool hasRooster;
  final bool allHens; // All birds are hens (no roosters)

  // Financial
  final double totalExpenses;
  final double totalIncome;
  final double? costPerEgg;
  final int expenseCount;
  final int incomeCount;

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
    required this.loggingStreakDays,
    required this.monthsWithEggs,
    required this.loggedBeforeEight,
    required this.loggedAfterNine,
    required this.hasDoubleYolk,
    required this.hasAbnormalEgg,
    required this.hasOrnamentalBreed,
    required this.hasOverachiever,
    required this.hasRooster,
    required this.allHens,
    required this.totalExpenses,
    required this.totalIncome,
    required this.costPerEgg,
    required this.expenseCount,
    required this.incomeCount,
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
    category: 'Production',
    check: (ctx) => ctx.totalEggs >= 1,
  ),
  Achievement(
    id: 'dozen_club',
    name: 'Dozen Club',
    description: '12 eggs in a single day',
    icon: Icons.egg,
    color: Colors.orange,
    category: 'Production',
    check: (ctx) => ctx.maxEggsInOneDay >= 12,
  ),
  Achievement(
    id: 'century_mark',
    name: 'Century Mark',
    description: '100 total eggs logged',
    icon: Icons.looks_one,
    color: Colors.deepOrange,
    category: 'Production',
    check: (ctx) => ctx.totalEggs >= 100,
  ),
  Achievement(
    id: 'thousand_layer',
    name: 'Thousand Layer',
    description: '1,000 total eggs',
    icon: Icons.military_tech,
    color: Colors.amber,
    category: 'Production',
    check: (ctx) => ctx.totalEggs >= 1000,
  ),
  Achievement(
    id: 'golden_flock',
    name: 'Golden Flock',
    description: '10,000 lifetime eggs',
    icon: Icons.diamond,
    color: Colors.yellow,
    category: 'Production',
    check: (ctx) => ctx.totalEggs >= 10000,
  ),
  Achievement(
    id: 'perfect_week',
    name: 'Perfect Week',
    description: '7 consecutive days of logging',
    icon: Icons.calendar_view_week,
    color: Colors.blue,
    category: 'Production',
    check: (ctx) => ctx.loggingStreakDays >= 7,
  ),
  Achievement(
    id: 'on_a_roll',
    name: 'On a Roll',
    description: '30-day logging streak',
    icon: Icons.local_fire_department,
    color: Colors.deepOrange,
    category: 'Production',
    check: (ctx) => ctx.loggingStreakDays >= 30,
  ),
  Achievement(
    id: 'summer_surplus',
    name: 'Summer Surplus',
    description: '20+ eggs in a single day',
    icon: Icons.wb_sunny,
    color: Colors.orange,
    category: 'Production',
    check: (ctx) => ctx.maxEggsInOneDay >= 20,
  ),

  // ==================== FLOCK DIVERSITY ====================
  Achievement(
    id: 'rainbow_basket',
    name: 'Rainbow Basket',
    description: 'Hens laying 4+ different egg colors',
    icon: Icons.palette,
    color: Colors.purple,
    category: 'Diversity',
    check: (ctx) => ctx.eggColors.length >= 4,
  ),
  Achievement(
    id: 'full_palette',
    name: 'Full Palette',
    description: 'All 7 egg colors represented',
    icon: Icons.brush,
    color: Colors.deepPurple,
    category: 'Diversity',
    check: (ctx) => ctx.eggColors.length >= 7,
  ),
  Achievement(
    id: 'breed_collector',
    name: 'Breed Collector',
    description: '5 different breeds',
    icon: Icons.collections,
    color: Colors.indigo,
    category: 'Diversity',
    check: (ctx) => ctx.breedCount >= 5,
  ),
  Achievement(
    id: 'flock_diversity',
    name: 'Flock Diversity',
    description: '10 different breeds',
    icon: Icons.diversity_3,
    color: Colors.teal,
    category: 'Diversity',
    check: (ctx) => ctx.breedCount >= 10,
  ),
  Achievement(
    id: 'easter_every_day',
    name: 'Easter Every Day',
    description: '3+ Easter Eggers',
    icon: Icons.egg_alt,
    color: Colors.lightBlue,
    category: 'Diversity',
    check: (ctx) => ctx.easterEggerCount >= 3,
  ),
  Achievement(
    id: 'rare_find',
    name: 'Rare Find',
    description: 'Add an ornamental breed',
    icon: Icons.auto_awesome,
    color: Colors.deepPurple,
    category: 'Diversity',
    check: (ctx) => ctx.hasOrnamentalBreed,
  ),
  Achievement(
    id: 'overachiever',
    name: 'Overachiever',
    description: "A hen exceeds her breed's expected production",
    icon: Icons.star,
    color: Colors.amber,
    category: 'Diversity',
    check: (ctx) => ctx.hasOverachiever,
  ),

  // ==================== FLOCK SIZE ====================
  Achievement(
    id: 'starter_flock',
    name: 'Starter Flock',
    description: '3 birds',
    icon: Icons.egg,
    color: Colors.brown,
    category: 'Flock Size',
    check: (ctx) => ctx.activeBirdCount >= 3,
  ),
  Achievement(
    id: 'bakers_dozen',
    name: "Baker's Dozen",
    description: '13 birds',
    icon: Icons.groups,
    color: Colors.green,
    category: 'Flock Size',
    check: (ctx) => ctx.activeBirdCount >= 13,
  ),
  Achievement(
    id: 'full_house',
    name: 'Full House',
    description: '25 birds',
    icon: Icons.home,
    color: Colors.blue,
    category: 'Flock Size',
    check: (ctx) => ctx.activeBirdCount >= 25,
  ),
  Achievement(
    id: 'mini_homestead',
    name: 'Mini Homestead',
    description: '50 birds',
    icon: Icons.agriculture,
    color: Colors.amber,
    category: 'Flock Size',
    check: (ctx) => ctx.activeBirdCount >= 50,
  ),
  Achievement(
    id: 'flock_boss',
    name: 'Flock Boss',
    description: '100+ birds',
    icon: Icons.workspace_premium,
    color: Colors.red,
    category: 'Flock Size',
    check: (ctx) => ctx.activeBirdCount >= 100,
  ),
  Achievement(
    id: 'multi_manager',
    name: 'Multi-Manager',
    description: '3+ separate flocks',
    icon: Icons.folder_copy,
    color: Colors.blueGrey,
    category: 'Flock Size',
    check: (ctx) => ctx.flockCount >= 3,
  ),

  // ==================== LONGEVITY & CARE ====================
  Achievement(
    id: 'first_birthday',
    name: 'First Birthday',
    description: 'A bird reaches 1 year old',
    icon: Icons.cake,
    color: Colors.pink,
    category: 'Longevity',
    check: (ctx) => ctx.birdsOver1Year >= 1,
  ),
  Achievement(
    id: 'senior_hen',
    name: 'Senior Hen',
    description: 'A bird reaches 5 years old',
    icon: Icons.elderly,
    color: Colors.purple,
    category: 'Longevity',
    check: (ctx) => ctx.birdsOver5Years >= 1,
  ),
  Achievement(
    id: 'grand_old_girl',
    name: 'Grand Old Girl',
    description: 'A bird reaches 8 years old',
    icon: Icons.star,
    color: Colors.amber,
    category: 'Longevity',
    check: (ctx) => ctx.birdsOver8Years >= 1,
  ),
  Achievement(
    id: 'dedicated_keeper',
    name: 'Dedicated Keeper',
    description: '5 years of chicken keeping',
    icon: Icons.verified,
    color: Colors.green,
    category: 'Longevity',
    check: (ctx) => ctx.yearsKeepingChickens >= 5,
  ),

  // ==================== FINANCIAL ====================
  Achievement(
    id: 'beat_the_store',
    name: 'Beat the Store',
    description: 'Cost per egg below \$0.25',
    icon: Icons.local_grocery_store,
    color: Colors.green,
    category: 'Financial',
    check: (ctx) => ctx.costPerEgg != null && ctx.costPerEgg! < 0.25 && ctx.totalEggs >= 50,
  ),
  Achievement(
    id: 'basically_free',
    name: 'Basically Free',
    description: 'Cost per egg below \$0.15',
    icon: Icons.savings,
    color: Colors.lightGreen,
    category: 'Financial',
    check: (ctx) => ctx.costPerEgg != null && ctx.costPerEgg! < 0.15 && ctx.totalEggs >= 100,
  ),
  Achievement(
    id: 'budget_tracker',
    name: 'Budget Tracker',
    description: 'Log 10 expenses',
    icon: Icons.receipt_long,
    color: Colors.blueGrey,
    category: 'Financial',
    check: (ctx) => ctx.expenseCount >= 10,
  ),
  Achievement(
    id: 'side_hustle',
    name: 'Side Hustle',
    description: 'Record your first egg sale',
    icon: Icons.attach_money,
    color: Colors.green,
    category: 'Financial',
    check: (ctx) => ctx.incomeCount >= 1,
  ),
  Achievement(
    id: 'in_the_black',
    name: 'In the Black',
    description: 'Total income exceeds expenses',
    icon: Icons.trending_up,
    color: Colors.teal,
    category: 'Financial',
    check: (ctx) => ctx.totalIncome > ctx.totalExpenses && ctx.totalIncome > 0,
  ),

  // ==================== HEALTH & MEDICATION ====================
  Achievement(
    id: 'first_aid',
    name: 'First Aid',
    description: 'Log your first medication',
    icon: Icons.medical_services,
    color: Colors.red,
    category: 'Health',
    check: (ctx) => ctx.medicationLogCount >= 1,
  ),
  Achievement(
    id: 'flock_doctor',
    name: 'Flock Doctor',
    description: 'Complete 5 medication courses',
    icon: Icons.healing,
    color: Colors.pink,
    category: 'Health',
    check: (ctx) => ctx.completedMedicationCount >= 5,
  ),
  Achievement(
    id: 'all_clear',
    name: 'All Clear',
    description: 'Complete a withdrawal period',
    icon: Icons.check_circle,
    color: Colors.green,
    category: 'Health',
    check: (ctx) => ctx.completedMedicationCount >= 1,
  ),

  // ==================== CONSISTENCY & ENGAGEMENT ====================
  Achievement(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Log eggs before 8 AM',
    icon: Icons.wb_twilight,
    color: Colors.orange,
    category: 'Engagement',
    check: (ctx) => ctx.loggedBeforeEight,
  ),
  Achievement(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Log eggs after 9 PM',
    icon: Icons.nightlight,
    color: Colors.indigo,
    category: 'Engagement',
    check: (ctx) => ctx.loggedAfterNine,
  ),
  Achievement(
    id: 'year_round_keeper',
    name: 'Year-Round Keeper',
    description: 'Log eggs in all 12 months',
    icon: Icons.calendar_month,
    color: Colors.blue,
    category: 'Engagement',
    check: (ctx) => ctx.monthsWithEggs.length >= 12,
  ),
  Achievement(
    id: 'power_user',
    name: 'Power User',
    description: 'Use the app 100 days',
    icon: Icons.phone_android,
    color: Colors.deepPurple,
    category: 'Engagement',
    check: (ctx) => ctx.daysUsingApp >= 100,
  ),

  // ==================== FUN & QUIRKY ====================
  Achievement(
    id: 'photogenic_flock',
    name: 'Photogenic Flock',
    description: 'Add photos for all birds',
    icon: Icons.photo_camera,
    color: Colors.pink,
    category: 'Fun',
    check: (ctx) => ctx.activeBirdCount > 0 && ctx.birdsWithPhotos == ctx.activeBirdCount,
  ),
  Achievement(
    id: 'name_game',
    name: 'Name Game',
    description: 'Name 10+ birds',
    icon: Icons.badge,
    color: Colors.teal,
    category: 'Fun',
    check: (ctx) => ctx.totalBirdCount >= 10,
  ),
  Achievement(
    id: 'creative_namer',
    name: 'Creative Namer',
    description: 'Give a bird a name over 15 characters',
    icon: Icons.text_fields,
    color: Colors.purple,
    category: 'Fun',
    check: (ctx) => ctx.longestNameLength > 15,
  ),
  Achievement(
    id: 'plot_twist',
    name: 'Plot Twist',
    description: 'Name a bird "Duck"',
    icon: Icons.flutter_dash,
    color: Colors.yellow,
    category: 'Fun',
    check: (ctx) => ctx.hasBirdNamedDuck,
  ),
  Achievement(
    id: 'double_yolk_day',
    name: 'Double Yolk Day',
    description: 'Log a double-yolk egg',
    icon: Icons.looks_two,
    color: Colors.amber,
    category: 'Fun',
    check: (ctx) => ctx.hasDoubleYolk,
  ),
  Achievement(
    id: 'fairy_egg',
    name: 'Fairy Egg',
    description: 'Log a tiny/abnormal egg',
    icon: Icons.auto_awesome,
    color: Colors.pink,
    category: 'Fun',
    check: (ctx) => ctx.hasAbnormalEgg,
  ),
  Achievement(
    id: 'the_quiet_life',
    name: 'The Quiet Life',
    description: 'All hens, no roosters',
    icon: Icons.volume_off,
    color: Colors.teal,
    category: 'Fun',
    check: (ctx) => ctx.activeBirdCount > 0 && ctx.allHens,
  ),
  Achievement(
    id: 'alarm_clock',
    name: 'Alarm Clock',
    description: 'Have a rooster in your flock',
    icon: Icons.alarm,
    color: Colors.orange,
    category: 'Fun',
    check: (ctx) => ctx.hasRooster,
  ),
  Achievement(
    id: 'winter_warriors',
    name: 'Winter Warriors',
    description: 'Log eggs in Dec, Jan, and Feb',
    icon: Icons.ac_unit,
    color: Colors.lightBlue,
    category: 'Fun',
    check: (ctx) => ctx.monthsWithEggs.contains(12) &&
                     ctx.monthsWithEggs.contains(1) &&
                     ctx.monthsWithEggs.contains(2),
  ),

  // ==================== SEASONAL ====================
  Achievement(
    id: 'thanksgiving_prep',
    name: 'Thanksgiving Prep',
    description: 'Log eggs in November',
    icon: Icons.restaurant,
    color: Colors.orange,
    category: 'Seasonal',
    check: (ctx) => ctx.monthsWithEggs.contains(11),
  ),
  Achievement(
    id: 'holiday_helper',
    name: 'Holiday Helper',
    description: 'Log eggs on Christmas',
    icon: Icons.card_giftcard,
    color: Colors.red,
    category: 'Seasonal',
    // This needs specific date check - approximating with December for now
    check: (ctx) => ctx.monthsWithEggs.contains(12),
  ),
];

/// Provider for earned achievements
final earnedAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final context = await ref.watch(_achievementContextProvider.future);
  return achievements.where((a) => a.check(context)).toList();
});

/// Provider for achievement count summary
final achievementSummaryProvider = FutureProvider<({int earned, int total})>((ref) async {
  final earned = await ref.watch(earnedAchievementsProvider.future);
  return (earned: earned.length, total: achievements.length);
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
  final activeWithdrawals = await ref.watch(activeWithdrawalsProvider.future);

  // Get repositories for additional queries
  final eggRepo = ref.read(eggRepositoryProvider);
  final expenseRepo = ref.read(expenseRepositoryProvider);

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
  final loggingStreak = await eggRepo.getCurrentLoggingStreak();
  final monthsWithEggs = await eggRepo.getMonthsWithEggs();
  final hasEarlyLog = await eggRepo.hasLogBeforeHour(8);
  final hasLateLog = await eggRepo.hasLogAfterHour(21);
  final daysWithLogs = await eggRepo.getDistinctLogDays();
  final hasDoubleYolk = await eggRepo.hasDoubleYolkEgg();
  final hasAbnormalEgg = await eggRepo.hasAbnormalEgg();

  // Check for ornamental breeds, overachievers, and rooster status
  bool hasOrnamentalBreed = false;
  bool hasOverachiever = false;
  bool hasRooster = false;
  bool allHens = true;

  for (final bird in birds) {
    // Check sex
    if (bird.isRooster) {
      hasRooster = true;
      allHens = false;
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

  // Get medication stats
  final medications = await ref.watch(medicationsProvider.future);
  final completedMeds = medications.where((m) =>
    m.endDate != null && m.endDate!.isBefore(now)
  ).length;

  // Count birds with health notes (approximate by checking if any health notes exist)
  // This would need a proper query - approximating for now
  final birdsWithHealthNotes = 0; // TODO: Implement proper count

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
    loggingStreakDays: loggingStreak,
    monthsWithEggs: monthsWithEggs,
    loggedBeforeEight: hasEarlyLog,
    loggedAfterNine: hasLateLog,
    hasDoubleYolk: hasDoubleYolk,
    hasAbnormalEgg: hasAbnormalEgg,
    hasOrnamentalBreed: hasOrnamentalBreed,
    hasOverachiever: hasOverachiever,
    hasRooster: hasRooster,
    allHens: allHens,
    totalExpenses: totalExpenses,
    totalIncome: totalIncome,
    costPerEgg: costPerEgg,
    expenseCount: expenses.length,
    incomeCount: incomes.length,
    medicationLogCount: medications.length,
    completedMedicationCount: completedMeds,
    birdsWithHealthNotes: birdsWithHealthNotes,
    hasActiveWithdrawal: activeWithdrawals.isNotEmpty,
    daysUsingApp: daysWithLogs,
    yearsKeepingChickens: yearsKeeping,
  );
});

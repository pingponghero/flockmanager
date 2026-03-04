import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/achievements_provider.dart';
import '../../providers/egg_value_provider.dart';
import '../../providers/bird_provider.dart';
import '../../providers/egg_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/trial_provider.dart';
import '../../utils/edge_insets.dart';
import '../../widgets/egg_quick_log.dart';
import '../../widgets/trial_banner.dart' show TrialBanner, showTrialExpiredDialog;
import 'widgets/birthday_callouts.dart';
import 'widgets/chicken_of_the_week.dart' show FlockSpotlight;
import 'widgets/greeting_header.dart';
import 'widgets/home_stats_row.dart';
import 'widgets/latest_achievement.dart';
import 'widgets/monthly_savings_card.dart';
import 'widgets/spark_line_card.dart';
import 'widgets/today_egg_card.dart';
import 'widgets/withdrawal_warning.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFlockId = ref.watch(selectedFlockIdProvider);
    final canEdit = ref.watch(canEditProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flock Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.push('/eggs'),
            tooltip: 'Egg History',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ScaffoldMessenger.of(context).clearSnackBars();
          // Egg stats
          ref.invalidate(todayEggCountByFlockProvider);
          ref.invalidate(yesterdayEggCountByFlockProvider);
          ref.invalidate(weekEggCountByFlockProvider);
          ref.invalidate(monthEggCountByFlockProvider);
          ref.invalidate(weeklyAverageEggCountProvider);
          ref.invalidate(recentEggLogsProvider);
          ref.invalidate(last7DaysEggCountsProvider);
          // Birds
          ref.invalidate(activeBirdsProvider);
          ref.invalidate(livingBirdsProvider);
          ref.invalidate(upcomingBirthdaysProvider);
          // Medications
          ref.invalidate(activeWithdrawalsProvider);
          // Achievements
          ref.invalidate(latestAchievementProvider);
          // Egg value
          ref.invalidate(allTimeEggValueProvider);
          ref.invalidate(achievementSummaryProvider);
          // Wait for data to actually refresh
          await Future.wait([
            ref.read(todayEggCountByFlockProvider.future),
            ref.read(last7DaysEggCountsProvider.future),
            ref.read(weekEggCountByFlockProvider.future),
            ref.read(monthEggCountByFlockProvider.future),
            ref.read(activeBirdsProvider.future),
            ref.read(allTimeEggValueProvider.future),
          ]);
        },
        child: ListView(
          padding: pagePadding(context),
          children: [
            // Date header
            const GreetingHeader(),

            // Trial expired banner (below date)
            const TrialBanner(),
            const SizedBox(height: 16),

            // Flock Spotlight (swipable bird gallery)
            const FlockSpotlight(),

            // Birthday callouts
            const BirthdayCallouts(),

            // Withdrawal warning banner
            const WithdrawalWarning(),

            // Today's eggs with comparison
            TodayEggCard(selectedFlockId: selectedFlockId),
            const SizedBox(height: 16),

            // Spark line (last 7 days)
            const SparkLineCard(),
            const SizedBox(height: 16),

            // Stats row
            HomeStatsRow(selectedFlockId: selectedFlockId),
            const SizedBox(height: 16),

            // Monthly savings vs store
            const MonthlySavingsCard(),
            const SizedBox(height: 24),

            // Latest achievement
            const LatestAchievement(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: canEdit
            ? () => showEggQuickLog(context)
            : () => showTrialExpiredDialog(context, ref),
        tooltip: 'Log Eggs',
        child: const Icon(Icons.egg),
      ),
    );
  }
}

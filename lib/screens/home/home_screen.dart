import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/egg_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/trial_provider.dart';
import '../../utils/edge_insets.dart';
import '../../widgets/egg_quick_log.dart';
import '../../widgets/trial_banner.dart' show TrialBanner, showTrialExpiredDialog;
import 'widgets/birthday_callouts.dart';
import 'widgets/chicken_of_the_week.dart';
import 'widgets/greeting_header.dart';
import 'widgets/home_stats_row.dart';
import 'widgets/latest_achievement.dart';
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
          ref.invalidate(todayEggCountByFlockProvider);
          ref.invalidate(yesterdayEggCountByFlockProvider);
          ref.invalidate(weekEggCountByFlockProvider);
          ref.invalidate(monthEggCountByFlockProvider);
          ref.invalidate(recentEggLogsProvider);
          ref.invalidate(last7DaysEggCountsProvider);
        },
        child: ListView(
          padding: pagePadding(context),
          children: [
            // Date header
            const GreetingHeader(),

            // Trial expired banner (below date)
            const TrialBanner(),
            const SizedBox(height: 16),

            // Chicken of the Week
            const ChickenOfTheWeek(),

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

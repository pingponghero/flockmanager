import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/analytics_provider.dart';
import '../../../providers/bird_provider.dart';
import '../../../providers/egg_provider.dart';
import '../../../widgets/stat_card.dart';

/// Row of stat cards showing weekly/monthly eggs and active birds
class HomeStatsRow extends ConsumerWidget {
  final String? selectedFlockId;

  const HomeStatsRow({super.key, this.selectedFlockId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekEggCountByFlockProvider);
    final monthAsync = ref.watch(monthEggCountByFlockProvider);
    final birdsAsync = ref.watch(activeBirdsProvider);

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'This Week',
            value: weekAsync.when(
              loading: () => '--',
              error: (error, stack) => '--',
              data: (count) => '$count',
            ),
            icon: Icon(
              Icons.calendar_view_week,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              ref.read(analyticsPeriodProvider.notifier).setPeriod(AnalyticsPeriod.week);
              context.go('/analytics');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            label: 'This Month',
            value: monthAsync.when(
              loading: () => '--',
              error: (error, stack) => '--',
              data: (count) => '$count',
            ),
            icon: Icon(
              Icons.calendar_month,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              ref.read(analyticsPeriodProvider.notifier).setPeriod(AnalyticsPeriod.month);
              context.go('/analytics');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            label: 'Active Birds',
            value: birdsAsync.when(
              loading: () => '--',
              error: (error, stack) => '--',
              data: (birds) => '${birds.length}',
            ),
            icon: Image.asset(
              'assets/icons/cute_hen.png',
              width: 20,
              height: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => context.go('/birds'),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/bird.dart';
import '../../../models/enums.dart';
import '../../../providers/egg_provider.dart';
import '../../../providers/trial_provider.dart';

/// Stats row showing egg counts and laying rate for a bird
class BirdStatsRow extends ConsumerWidget {
  final Bird bird;

  const BirdStatsRow({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalEggCountByBirdProvider(bird.id));
    final logsAsync = ref.watch(eggLogsByBirdProvider(bird.id));
    final trial = ref.watch(trialProvider);

    final now = DateTime.now();
    final isActive = bird.status == BirdStatus.active;

    int thisMonthCount = 0;
    String layingRate = '--%';

    if (logsAsync.hasValue) {
      final logs = logsAsync.value!;

      if (isActive) {
        // Active bird: show this month's eggs
        final monthStart = DateTime(now.year, now.month, 1);
        for (final log in logs) {
          if (log.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
            thisMonthCount += log.count;
          }
        }

        // Calculate laying rate (eggs per day over last N days)
        // Use min(30, daysUsingApp) so new users don't see artificially low rates
        if (logs.isNotEmpty) {
          final daysUsingApp = trial.installDate != null
              ? now.difference(trial.installDate!).inDays.clamp(1, 30)
              : 30;
          final periodStart = now.subtract(Duration(days: daysUsingApp));
          int periodEggs = 0;
          for (final log in logs) {
            if (log.date.isAfter(periodStart)) {
              periodEggs += log.count;
            }
          }
          final rate = (periodEggs / daysUsingApp * 100).round();
          layingRate = '$rate%';
        }
      } else {
        // Inactive bird: calculate lifetime average laying rate
        final lastDate = bird.statusDate ?? now;
        final totalDays = lastDate.difference(bird.createdAt).inDays.clamp(1, 9999);
        final totalEggs = logs.fold<int>(0, (sum, log) => sum + log.count);
        final rate = (totalEggs / totalDays * 100).round();
        layingRate = '$rate%';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: 'Total Eggs',
            value: totalAsync.when(
              loading: () => '--',
              error: (_, __) => '--',
              data: (count) => '$count',
            ),
            icon: Icons.egg,
          ),
          if (isActive)
            _StatItem(
              label: 'This Month',
              value: logsAsync.when(
                loading: () => '--',
                error: (_, __) => '--',
                data: (_) => '$thisMonthCount',
              ),
              icon: Icons.calendar_month,
            ),
          _StatItem(
            label: isActive ? 'Laying Rate' : 'Lifetime Rate',
            value: logsAsync.when(
              loading: () => '--%',
              error: (_, __) => '--%',
              data: (_) => layingRate,
            ),
            icon: Icons.trending_up,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

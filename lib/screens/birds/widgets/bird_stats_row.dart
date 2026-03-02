import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/bird.dart';
import '../../../models/enums.dart';
import '../../../providers/egg_provider.dart';

/// Stats row showing egg counts and age for a bird
class BirdStatsRow extends ConsumerWidget {
  final Bird bird;

  const BirdStatsRow({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalEggCountByBirdProvider(bird.id));
    final logsAsync = ref.watch(eggLogsByBirdProvider(bird.id));

    final now = DateTime.now();
    final isActive = bird.status == BirdStatus.active;

    int thisMonthCount = 0;

    if (logsAsync.hasValue) {
      final logs = logsAsync.value!;

      if (isActive) {
        final monthStart = DateTime(now.year, now.month, 1);
        for (final log in logs) {
          if (log.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
            thisMonthCount += log.count;
          }
        }
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
            label: 'Since',
            value: '${bird.createdAt.year}',
            icon: Icons.wb_sunny_outlined,
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

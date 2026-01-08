import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/bird_provider.dart';
import '../../../providers/egg_provider.dart';

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
          child: _StatCard(
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
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
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
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              icon,
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

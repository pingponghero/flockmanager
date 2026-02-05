import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/golden_egg_provider.dart';
import 'golden_egg_daily.dart';
import 'golden_egg_yearly.dart';

/// Main golden egg chart widget that switches between daily and monthly views
/// based on the selected analytics period.
class GoldenEggChart extends ConsumerWidget {
  const GoldenEggChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(goldenEggChartDataProvider);

    return chartDataAsync.when(
      data: (data) {
        if (data.totalEggs == 0) {
          return _EmptyState();
        }

        return switch (data.timeScale) {
          ChartTimeScale.daily => GoldenEggDailyChart(data: data),
          ChartTimeScale.monthly => GoldenEggYearlyChart(data: data),
        };
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading chart: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.egg_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No egg data yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging eggs to see your production chart',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

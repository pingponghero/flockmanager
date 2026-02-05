import 'package:flutter/material.dart';

import '../providers/golden_egg_provider.dart';

/// Weekly radial chart placeholder.
/// Will show weekly aggregates arranged radially (31-89 days of data).
class GoldenEggWeeklyChart extends StatelessWidget {
  final GoldenEggChartData data;

  const GoldenEggWeeklyChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_view_week_rounded,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Weekly View',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${data.daysOfData} days of data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coming soon',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            // Show summary stats
            _SummaryRow(
              label: 'Total eggs',
              value: '${data.totalEggs}',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Daily average',
              value: data.dailyAverage.toStringAsFixed(1),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

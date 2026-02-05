import 'package:flutter/material.dart';

import '../providers/golden_egg_provider.dart';

/// Yearly egg chart placeholder.
/// Will show the full golden egg visualization with daylight boundary (90+ days of data).
class GoldenEggYearlyChart extends StatelessWidget {
  final GoldenEggChartData data;

  const GoldenEggYearlyChart({
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
            // Golden egg icon placeholder
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFF8E1),
                    const Color(0xFFFDF3D7),
                    theme.colorScheme.secondary.withValues(alpha: 0.6),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                  center: const Alignment(-0.3, -0.3),
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: theme.colorScheme.secondary,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Golden Egg Chart',
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
              'Full yearly visualization coming soon',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Show summary stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _StatRow(
                    icon: Icons.egg,
                    label: 'Total eggs',
                    value: '${data.totalEggs}',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    icon: Icons.trending_up,
                    label: 'Daily average',
                    value: data.dailyAverage.toStringAsFixed(1),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    icon: Icons.calendar_today,
                    label: 'Days tracked',
                    value: '${data.daysOfData}',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/golden_egg_provider.dart';

/// Tooltip widget showing details for a selected day in the golden egg chart.
class GoldenEggTooltip extends StatelessWidget {
  final DailyEggData data;
  final double average;
  final VoidCallback? onClose;

  const GoldenEggTooltip({
    super.key,
    required this.data,
    required this.average,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMEd(); // Mon, Jan 15, 2024
    final difference = data.count - average;
    final isAboveAverage = difference > 0;
    final isAtAverage = difference.abs() < 0.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Egg icon with count
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${data.count}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Date and comparison
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateFormat.format(data.date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (!isAtAverage) ...[
                      Icon(
                        isAboveAverage
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: isAboveAverage
                            ? Colors.green.shade600
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isAtAverage
                          ? 'At average'
                          : '${difference.abs().toStringAsFixed(1)} ${isAboveAverage ? 'above' : 'below'} avg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isAtAverage
                            ? theme.colorScheme.onSurfaceVariant
                            : isAboveAverage
                                ? Colors.green.shade600
                                : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

/// Tooltip for weekly data.
class GoldenEggWeeklyTooltip extends StatelessWidget {
  final WeeklyEggData data;
  final VoidCallback? onClose;

  const GoldenEggWeeklyTooltip({
    super.key,
    required this.data,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.MMMd();
    final weekEnd = data.weekStart.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${data.totalCount}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${dateFormat.format(data.weekStart)} - ${dateFormat.format(weekEnd)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.dailyAverage.toStringAsFixed(1)} eggs/day avg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

/// Tooltip for monthly data.
class GoldenEggMonthlyTooltip extends StatelessWidget {
  final MonthlyEggData data;
  final double? averageDaylight;
  final VoidCallback? onClose;

  const GoldenEggMonthlyTooltip({
    super.key,
    required this.data,
    this.averageDaylight,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat.MMMM().format(DateTime(data.year, data.month));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${data.totalCount}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      monthName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!data.isActual) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'forecast',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.daysRecorded}d recorded • ${data.dailyAverage.toStringAsFixed(1)}/day',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (averageDaylight != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${averageDaylight!.toStringAsFixed(1)}h avg daylight',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Offers to spread a batch of eggs across days that weren't logged.
/// Pops true to spread, false to keep the batch on the selected date.
class SpreadEggsDialog extends StatelessWidget {
  /// Eggs per day, oldest first, ending with the selected log date.
  final Map<DateTime, int> perDay;

  const SpreadEggsDialog({super.key, required this.perDay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = perDay.keys.toList();
    final eggCount = perDay.values.fold(0, (a, b) => a + b);
    final missed = days.length - 1;
    final dayFormat = DateFormat.MMMEd();

    return AlertDialog(
      title: const Text('Spread across missed days?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nothing was logged for the previous '
                '${missed == 1 ? 'day' : '$missed days'}. '
                'Spread these $eggCount eggs as an estimate of when they '
                'were laid:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final entry in perDay.entries)
                _DayRow(label: dayFormat.format(entry.key), count: entry.value),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Keep on ${dayFormat.format(days.last)}'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Spread'),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final int count;

  const _DayRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

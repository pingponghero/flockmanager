import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/egg_provider.dart';

/// Card showing a spark line chart of the last 7 days of eggs
class SparkLineCard extends ConsumerWidget {
  const SparkLineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(last7DaysEggCountsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: countsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(child: Text('--')),
                data: (counts) {
                  if (counts.isEmpty) {
                    return Center(
                      child: Text(
                        'No data yet',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  // Get last 7 days in order
                  final now = DateTime.now();
                  final days = List.generate(7, (i) {
                    final date = DateTime(now.year, now.month, now.day - 6 + i);
                    return MapEntry(date, counts[date] ?? 0);
                  });

                  final maxCount = days
                      .map((e) => e.value)
                      .reduce((a, b) => a > b ? a : b);
                  final maxHeight = maxCount == 0 ? 1 : maxCount;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: days.map((entry) {
                      final isToday = entry.key.day == now.day;
                      final height = maxHeight == 0
                          ? 0.0
                          : (entry.value / maxHeight * 48);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (entry.value > 0)
                                Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isToday ? FontWeight.bold : null,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Container(
                                height: height.clamp(4.0, 48.0),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.E().format(entry.key).substring(0, 1),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isToday ? FontWeight.bold : null,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

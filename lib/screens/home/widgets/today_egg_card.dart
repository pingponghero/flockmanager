import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/egg_provider.dart';
import '../../../providers/trial_provider.dart';
import '../../../widgets/egg_quick_log.dart';
import '../../../widgets/trial_banner.dart' show showTrialExpiredDialog;

/// Card showing today's egg count with weekly average comparison
class TodayEggCard extends ConsumerWidget {
  final String? selectedFlockId;

  const TodayEggCard({super.key, this.selectedFlockId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayEggCountByFlockProvider);
    final avgAsync = ref.watch(weeklyAverageEggCountProvider);
    final canEdit = ref.watch(canEditProvider);

    final todayCount = todayAsync.value ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (todayCount == 0 && canEdit) {
            final log = await showEggQuickLog(context);
            if (log != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    log.count == 0
                        ? 'Logged: No eggs collected'
                        : 'Logged: ${log.count} egg${log.count == 1 ? '' : 's'}',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Edit',
                    onPressed: () => context.push('/eggs/log', extra: log),
                  ),
                ),
              );
            }
          } else if (todayCount == 0 && !canEdit) {
            showTrialExpiredDialog(context, ref);
          } else {
            context.push('/eggs');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Eggs",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    todayAsync.when(
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stack) => const Text('--'),
                      data: (today) => Text(
                        '$today',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              // Comparison with weekly average
              avgAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
                data: (avg) {
                  if (avg == 0) {
                    return const SizedBox.shrink();
                  }

                  // Only colorize for significant deviations (25%+ from average)
                  // Normal fluctuation stays gray
                  final percentDiff = (todayCount - avg) / avg;
                  final isSignificantlyUp = percentDiff >= 0.25;
                  final isSignificantlyDown = percentDiff <= -0.25;

                  final color = isSignificantlyUp
                      ? Colors.green
                      : isSignificantlyDown
                          ? Colors.red
                          : Colors.grey;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSignificantlyUp
                              ? Icons.arrow_upward
                              : isSignificantlyDown
                                  ? Icons.arrow_downward
                                  : Icons.remove,
                          size: 16,
                          color: color.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'avg ${avg.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: color.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

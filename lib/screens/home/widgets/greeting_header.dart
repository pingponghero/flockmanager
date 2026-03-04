import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/egg_provider.dart';

/// Header showing the current date and streak badge
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);
    final streakAsync = ref.watch(checkInStreakProvider);

    return Row(
      children: [
        Text(
          dateStr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const Spacer(),
        streakAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (streak) {
            if (streak < 2) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _showStreakInfo(context, ref, streak),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak day${streak == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showStreakInfo(BuildContext context, WidgetRef ref, int streak) {
    final totalDays = ref.read(totalLoggedDaysProvider).value ?? 0;
    final showStats = totalDays >= 30;

    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fire emoji with glow effect
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.shade100,
                      Colors.orange.shade50.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 16),
              // Streak count
              Text(
                '$streak Day Streak!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 16),
              // Stats for dedicated users (30+ days)
              if (showStats) ...[
                Consumer(
                  builder: (context, ref, _) {
                    final longestAsync = ref.watch(longestStreakProvider);
                    final totalDaysAsync = ref.watch(totalLoggedDaysProvider);

                    final longest = longestAsync.value ?? streak;
                    final totalDays = totalDaysAsync.value ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _StatRow(label: 'Current streak', value: '$streak days'),
                          const SizedBox(height: 8),
                          _StatRow(label: 'Longest streak', value: '$longest days'),
                          const SizedBox(height: 8),
                          _StatRow(label: 'Total days logged', value: '$totalDays'),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                // Simple description for newer users
                Text(
                  'Every day you check on your flock counts toward your streak — '
                      'even when the girls take a day off.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Keep it going!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Simple label-value row for streak stats
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

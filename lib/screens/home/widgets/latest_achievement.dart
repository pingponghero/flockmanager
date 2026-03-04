import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/achievements_provider.dart';
import '../../settings/achievements_screen.dart' show showAchievementDetails;

/// Displays the latest achievement earned with a link to all achievements
class LatestAchievement extends ConsumerWidget {
  const LatestAchievement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestAchievementProvider);

    return latestAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (achievement) {
        if (achievement == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => showAchievementDetails(
            context,
            achievement: achievement,
            earned: true,
            trailing: [
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/settings/achievements');
                },
                child: const Text('See all achievements'),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: achievement.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Badge icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: achievement.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement.icon,
                    color: achievement.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Achievement info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Achievement',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        achievement.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

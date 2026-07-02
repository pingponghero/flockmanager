import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/achievements_provider.dart';
import '../../providers/egg_provider.dart' show currencySymbolProvider;
import '../../utils/edge_insets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsByCategory = ref.watch(achievementsByCategoryProvider);
    final progressData = ref.watch(achievementProgressProvider);
    final summaryAsync = ref.watch(achievementSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          // Show summary in app bar
          summaryAsync.when(
            data: (summary) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${summary.earned}/${summary.total}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: achievementsByCategory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (categories) {
          final progress = progressData.value ?? {};

          // Define category order
          const categoryOrder = [
            'Layer Legends',
            'Variety Show',
            'The More the Merrier',
            'Golden Years',
            'Nest Egg',
            'Flock Doc',
            'Star Keeper',
            'Just for Clucks',
            'Four Seasons',
          ];

          final sortedCategories = categoryOrder
              .where((c) => categories.containsKey(c))
              .toList();

          return ListView.builder(
            padding: pagePadding(context),
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              final items = categories[category]!;
              final earnedCount = items.where((i) => i.earned).length;

              return _CategorySection(
                category: category,
                earnedCount: earnedCount,
                totalCount: items.length,
                items: items,
                progress: progress,
              );
            },
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final int earnedCount;
  final int totalCount;
  final List<({Achievement achievement, bool earned})> items;
  final Map<String, AchievementProgress> progress;

  const _CategorySection({
    required this.category,
    required this.earnedCount,
    required this.totalCount,
    required this.items,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Sort items: earned first, then locked
    final sortedItems = [...items]..sort((a, b) {
      if (a.earned && !b.earned) return -1;
      if (!a.earned && b.earned) return 1;
      return 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        // Achievement grid
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            const columns = 3;
            final tileWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
            final tileHeight = tileWidth * 1.25;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: sortedItems.map((item) {
                return SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: _AchievementTile(
                    achievement: item.achievement,
                    earned: item.earned,
                    progress: progress[item.achievement.id],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AchievementTile extends ConsumerWidget {
  final Achievement achievement;
  final bool earned;
  final AchievementProgress? progress;

  const _AchievementTile({
    required this.achievement,
    required this.earned,
    this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showProgress = !earned && progress != null && progress!.current > 0;

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned
              ? achievement.color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: earned
              ? Border.all(color: achievement.color.withValues(alpha: 0.3), width: 2)
              : null,
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: earned
                    ? achievement.color.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.icon,
                size: 24,
                color: earned
                    ? achievement.color
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            // Name and description (only if earned)
            if (earned) ...[
              Text(
                achievement.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                achievement.describeWith(ref.watch(currencySymbolProvider)),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              Text(
                achievement.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            // Progress bar (for unearned incremental achievements)
            if (showProgress) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress!.percent,
                  minHeight: 4,
                  backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${progress!.current}/${progress!.target}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showAchievementDetails(
      context,
      achievement: achievement,
      earned: earned,
      progress: progress,
    );
  }
}

/// Shows a bottom sheet with achievement details.
/// Used by both the achievements list and the home screen latest achievement.
void showAchievementDetails(
  BuildContext context, {
  required Achievement achievement,
  required bool earned,
  AchievementProgress? progress,
  List<Widget> trailing = const [],
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: earned
                    ? achievement.color.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: earned
                    ? Border.all(color: achievement.color, width: 3)
                    : null,
              ),
              child: Icon(
                achievement.icon,
                size: 40,
                color: earned
                    ? achievement.color
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              achievement.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: earned ? null : Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Description (only if earned)
            if (earned)
              Consumer(
                builder: (context, ref, _) => Text(
                  achievement.describeWith(ref.watch(currencySymbolProvider)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Text(
                '???',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            // Progress (if applicable)
            if (progress != null && !earned) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.percent,
                        minHeight: 8,
                        backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.current} / ${progress.target}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            // Status badge
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: earned
                    ? Colors.green.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    earned ? Icons.check_circle : Icons.lock_outline,
                    size: 16,
                    color: earned ? Colors.green : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    earned ? 'Unlocked' : 'Locked',
                    style: TextStyle(
                      color: earned ? Colors.green : Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Earned date (when recorded)
            if (earned)
              Consumer(
                builder: (context, ref, _) {
                  final earnedDate = ref
                      .watch(achievementEarnedDatesProvider)
                      .value?[achievement.id];
                  if (earnedDate == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Earned ${DateFormat.yMMMd().format(earnedDate)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                },
              ),
            ...trailing,
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/egg_log.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/bird_provider.dart';
import '../../providers/egg_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/medication_provider.dart';
import '../../widgets/egg_quick_log.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFlockId = ref.watch(selectedFlockIdProvider);
    final recentLogsAsync = ref.watch(recentEggLogsProvider);

    // Only show FAB when there are existing egg logs (empty state has its own CTA)
    final hasEggLogs = recentLogsAsync.valueOrNull?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flock Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/eggs'),
            tooltip: 'Egg History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayEggCountByFlockProvider);
          ref.invalidate(yesterdayEggCountByFlockProvider);
          ref.invalidate(weekEggCountByFlockProvider);
          ref.invalidate(monthEggCountByFlockProvider);
          ref.invalidate(recentEggLogsProvider);
          ref.invalidate(last7DaysEggCountsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date header
            const _GreetingHeader(),
            const SizedBox(height: 16),

            // Chicken of the Week
            const _ChickenOfTheWeek(),

            // Birthday callouts
            const _BirthdayCallouts(),

            // Withdrawal warning banner
            _WithdrawalWarning(),

            // Today's eggs with comparison
            _TodayEggCard(selectedFlockId: selectedFlockId),
            const SizedBox(height: 16),

            // Spark line (last 7 days)
            _SparkLineCard(),
            const SizedBox(height: 16),

            // Stats row
            _StatsRow(selectedFlockId: selectedFlockId),
            const SizedBox(height: 24),

            // Quick actions
            _QuickActions(),
            const SizedBox(height: 16),

            // Latest achievement
            const _LatestAchievement(),
            const SizedBox(height: 24),

            // Recent activity
            _RecentActivity(),
          ],
        ),
      ),
      floatingActionButton: hasEggLogs
          ? FloatingActionButton(
              onPressed: () => showEggQuickLog(context),
              tooltip: 'Log Eggs',
              child: const Icon(Icons.egg),
            )
          : null,
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Text(
      dateStr,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _WithdrawalWarning extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(activeWithdrawalsProvider);

    return withdrawalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (withdrawals) {
        if (withdrawals.isEmpty) return const SizedBox(height: 8);

        // Find the soonest withdrawal end
        int? minDays;
        for (final w in withdrawals) {
          final days = w.withdrawalDaysRemaining;
          if (days != null && (minDays == null || days < minDays)) {
            minDays = days;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => context.push('/medications'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Egg Withdrawal Active',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          minDays != null && minDays > 0
                              ? '$minDays days remaining'
                              : 'Ends today',
                          style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.amber.shade700),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodayEggCard extends ConsumerWidget {
  final String? selectedFlockId;

  const _TodayEggCard({this.selectedFlockId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayEggCountByFlockProvider);
    final avgAsync = ref.watch(weeklyAverageEggCountProvider);

    final todayCount = todayAsync.valueOrNull ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (todayCount == 0) {
            showEggQuickLog(context);
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
                  final diff = todayCount - avg;

                  if (avg == 0) {
                    return const SizedBox.shrink();
                  }

                  final isUp = diff > 0.5;
                  final isDown = diff < -0.5;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUp
                          ? Colors.green.shade50
                          : isDown
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.arrow_upward
                              : isDown
                                  ? Icons.arrow_downward
                                  : Icons.remove,
                          size: 16,
                          color: isUp
                              ? Colors.green.shade700
                              : isDown
                                  ? Colors.red.shade700
                                  : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'avg ${avg.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUp
                                ? Colors.green.shade700
                                : isDown
                                    ? Colors.red.shade700
                                    : Colors.grey.shade700,
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

class _SparkLineCard extends ConsumerWidget {
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

class _StatsRow extends ConsumerWidget {
  final String? selectedFlockId;

  const _StatsRow({this.selectedFlockId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekEggCountByFlockProvider);
    final monthAsync = ref.watch(monthEggCountByFlockProvider);
    final birdsAsync = ref.watch(activeBirdsProvider);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'This Week',
            value: weekAsync.when(
              loading: () => '--',
              error: (error, stack) => '--',
              data: (count) => '$count',
            ),
            icon: Icon(
              Icons.calendar_view_week,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'This Month',
            value: monthAsync.when(
              loading: () => '--',
              error: (error, stack) => '--',
              data: (count) => '$count',
            ),
            icon: Icon(
              Icons.calendar_month,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Active Birds',
            value: birdsAsync.when(
              loading: () => '--',
              error: (error, stack) => '--',
              data: (birds) => '${birds.length}',
            ),
            icon: Image.asset(
              'assets/icons/cute_hen.png',
              width: 20,
              height: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/flocks'),
                icon: const Icon(Icons.grid_view),
                label: const Text('Flocks'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/birds'),
                icon: Image.asset(
                  'assets/icons/cute_hen.png',
                  width: 24,
                  height: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: const Text('Birds'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/expenses'),
                icon: const Icon(Icons.attach_money),
                label: const Text('Finances'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/analytics'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Egg Stats'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(recentEggLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () => context.push('/eggs'),
              child: const Text('See all'),
            ),
          ],
        ),
        logsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Error: $error'),
            ),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.egg_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No eggs logged yet',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => showEggQuickLog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Log Your First Eggs'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Card(
              child: Column(
                children: logs.map((log) => _ActivityTile(log: log)).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  final EggLog log;

  const _ActivityTile({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show bird name if attributed to a specific bird, otherwise show flock name
    final subtitleWidget = log.birdId != null
        ? _buildBirdSubtitle(context, ref)
        : _buildFlockSubtitle(context, ref);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          '${log.count}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        '${log.count} egg${log.count == 1 ? '' : 's'} logged',
      ),
      subtitle: subtitleWidget,
      trailing: Text(
        _formatRelativeTime(log.createdAt),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      onTap: () => context.push('/eggs'),
    );
  }

  Widget _buildBirdSubtitle(BuildContext context, WidgetRef ref) {
    final birdAsync = ref.watch(birdByIdProvider(log.birdId!));
    return birdAsync.when(
      loading: () => const Text('...'),
      error: (_, __) => _buildFlockSubtitle(context, ref),
      data: (bird) => bird != null
          ? Text(bird.name)
          : _buildFlockSubtitle(context, ref),
    );
  }

  Widget _buildFlockSubtitle(BuildContext context, WidgetRef ref) {
    final flockAsync = ref.watch(flockByIdProvider(log.flockId));
    return flockAsync.when(
      loading: () => const Text('...'),
      error: (_, __) => const Text('Unknown flock'),
      data: (flock) => Text(flock?.name ?? 'Unknown flock'),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
}

class _ChickenOfTheWeek extends ConsumerWidget {
  const _ChickenOfTheWeek();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chickenAsync = ref.watch(chickenOfTheWeekProvider);

    return chickenAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        final bird = data.bird;
        final title = data.title;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/birds/${bird.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Photo or fallback
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: bird.photoPrimary != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.network(
                                bird.photoPrimary!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Image.asset(
                                    'assets/icons/cute_hen.png',
                                    width: 48,
                                    height: 48,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Image.asset(
                                'assets/icons/cute_hen.png',
                                width: 48,
                                height: 48,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                title,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Colors.amber.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bird.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (bird.breed != null)
                            Text(
                              bird.breed!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          if (bird.notes != null && bird.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bird.notes!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BirthdayCallouts extends ConsumerWidget {
  const _BirthdayCallouts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthdaysAsync = ref.watch(upcomingBirthdaysProvider);

    return birthdaysAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (birthdays) {
        if (birthdays.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: birthdays.map((b) {
              final isToday = b.daysUntil == 0;
              final message = isToday
                  ? '${b.bird.name} turns ${b.age} today!'
                  : b.daysUntil == 1
                      ? "${b.bird.name}'s birthday is tomorrow!"
                      : "${b.bird.name}'s birthday is in ${b.daysUntil} days";

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => context.push('/birds/${b.bird.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.pink.shade50 : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday ? Colors.pink.shade200 : Colors.purple.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isToday ? Icons.cake : Icons.event,
                          color: isToday ? Colors.pink.shade600 : Colors.purple.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: isToday ? Colors.pink.shade900 : Colors.purple.shade900,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isToday)
                          const Text(
                            '🎂',
                            style: TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _LatestAchievement extends ConsumerWidget {
  const _LatestAchievement();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestAchievementProvider);
    final summaryAsync = ref.watch(achievementSummaryProvider);

    return latestAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (achievement) {
        if (achievement == null) return const SizedBox.shrink();

        final summary = summaryAsync.valueOrNull;

        return GestureDetector(
          onTap: () => context.push('/achievements'),
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
                // Summary count
                if (summary != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${summary.earned}/${summary.total}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                const SizedBox(width: 8),
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

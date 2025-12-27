import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/egg_log.dart';
import '../../models/flock.dart';
import '../../providers/bird_provider.dart';
import '../../providers/egg_provider.dart';
import '../../providers/flock_provider.dart';
import '../../widgets/egg_quick_log.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFlockId = ref.watch(selectedFlockIdProvider);
    final selectedFlockAsync = ref.watch(selectedFlockProvider);
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
            // Greeting header
            _GreetingHeader(
              selectedFlock: selectedFlockAsync.valueOrNull,
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // Recent activity
            _RecentActivity(),
          ],
        ),
      ),
      floatingActionButton: hasEggLogs
          ? FloatingActionButton.extended(
              onPressed: () => showEggQuickLog(context),
              icon: const Icon(Icons.egg),
              label: const Text('Log Eggs'),
            )
          : null,
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final Flock? selectedFlock;

  const _GreetingHeader({this.selectedFlock});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (selectedFlock != null)
          Text(
            selectedFlock!.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          )
        else
          Text(
            'All Flocks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}

class _TodayEggCard extends ConsumerWidget {
  final String? selectedFlockId;

  const _TodayEggCard({this.selectedFlockId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayEggCountByFlockProvider);
    final yesterdayAsync = ref.watch(yesterdayEggCountByFlockProvider);

    return Card(
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
            // Comparison with yesterday
            yesterdayAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
              data: (yesterday) {
                final today = todayAsync.valueOrNull ?? 0;
                final diff = today - yesterday;

                if (diff == 0 && yesterday == 0) {
                  return const SizedBox.shrink();
                }

                final isUp = diff > 0;
                final isDown = diff < 0;

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
                        '${diff.abs()} vs yesterday',
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
              height: 60,
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
            icon: Icons.calendar_view_week,
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
            icon: Icons.calendar_month,
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
            icon: Icons.flutter_dash,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

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
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
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
                icon: const Icon(Icons.groups),
                label: const Text('Flocks'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/birds'),
                icon: const Icon(Icons.flutter_dash),
                label: const Text('Birds'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/eggs'),
                icon: const Icon(Icons.calendar_month),
                label: const Text('History'),
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
    final flockAsync = ref.watch(flockByIdProvider(log.flockId));

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
      subtitle: flockAsync.when(
        loading: () => const Text('...'),
        error: (error, stack) => const Text('Unknown flock'),
        data: (flock) => Text(flock?.name ?? 'Unknown flock'),
      ),
      trailing: Text(
        _formatRelativeTime(log.createdAt),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      onTap: () => context.push('/eggs'),
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

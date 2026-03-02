import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/egg_log.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/bird_provider.dart';
import '../../providers/egg_provider.dart';
import '../../providers/flock_provider.dart';
import '../../utils/edge_insets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(analyticsPeriodProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final flocksAsync = ref.watch(flocksProvider);
    final selectedFlockId = ref.watch(selectedFlockIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Stats'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ScaffoldMessenger.of(context).clearSnackBars();
          ref.invalidate(analyticsProvider);
        },
        child: ListView(
          padding: pagePadding(context),
          children: [
            // Flock filter (hidden if only 1 flock)
            flocksAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
              data: (flocks) {
                if (flocks.length <= 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownMenu<String?>(
                    initialSelection: selectedFlockId,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Flock'),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(
                        value: null,
                        label: 'All Flocks',
                      ),
                      ...flocks.map((flock) => DropdownMenuEntry(
                            value: flock.id,
                            label: flock.name,
                          )),
                    ],
                    onSelected: (value) {
                      ref.read(selectedFlockIdProvider.notifier).selectFlock(value);
                    },
                  ),
                );
              },
            ),

            // Period selector
            _PeriodSelector(
              selectedPeriod: selectedPeriod,
              onPeriodChanged: (period) {
                ref.read(analyticsPeriodProvider.notifier).setPeriod(period);
              },
            ),
            const SizedBox(height: 24),

            // Analytics content
            analyticsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                    ],
                  ),
                ),
              ),
              data: (analytics) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary stats
                  _SummaryStats(analytics: analytics),
                  const SizedBox(height: 24),

                  // Production chart
                  Text(
                    'Production',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _ProductionChart(dailyCounts: analytics.dailyCounts),
                  const SizedBox(height: 24),

                  // Trend indicator
                  _TrendCard(
                    periodChange: analytics.periodChange,
                    hasPreviousPeriodData: analytics.hasPreviousPeriodData,
                    period: selectedPeriod,
                  ),
                  const SizedBox(height: 24),

                  // Per-bird breakdown
                  if (analytics.birdStats.isNotEmpty) ...[
                    Text(
                      'Per-Bird Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _BirdBreakdown(birdStats: analytics.birdStats),
                    const SizedBox(height: 24),
                  ],

                  // Recent Activity
                  const _RecentActivity(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod selectedPeriod;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period.displayName),
              selected: isSelected,
              onSelected: (_) => onPeriodChanged(period),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryStats extends StatelessWidget {
  final AnalyticsSummary analytics;

  const _SummaryStats({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Eggs',
                value: '${analytics.totalEggs}',
                icon: Icons.egg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Daily Avg',
                value: analytics.dailyAverage.toStringAsFixed(1),
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Best Day',
                value: '${analytics.bestDayCount}',
                subtitle: analytics.bestDayDate != null
                    ? DateFormat.MMMd().format(analytics.bestDayDate!)
                    : null,
                icon: Icons.star,
                iconColor: Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Worst Day',
                value: '${analytics.worstDayCount}',
                subtitle: analytics.worstDayDate != null
                    ? DateFormat.MMMd().format(analytics.worstDayDate!)
                    : null,
                icon: Icons.trending_down,
                iconColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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

class _ProductionChart extends StatelessWidget {
  final List<DailyEggCount> dailyCounts;

  const _ProductionChart({required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    if (dailyCounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No data for this period',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final maxY = dailyCounts
        .map((e) => e.count)
        .reduce((a, b) => math.max(a, b))
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _calculateInterval(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= dailyCounts.length) {
                        return const SizedBox.shrink();
                      }
                      final date = dailyCounts[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat.MMMd().format(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (dailyCounts.length - 1).toDouble(),
              minY: 0,
              maxY: maxY + (maxY * 0.1).ceilToDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: dailyCounts.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.count.toDouble(),
                    );
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: dailyCounts.length <= 14,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final date = dailyCounts[index].date;
                      return LineTooltipItem(
                        '${DateFormat.MMMd().format(date)}\n${spot.y.toInt()} eggs',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateInterval() {
    if (dailyCounts.length <= 7) return 1;
    if (dailyCounts.length <= 14) return 2;
    if (dailyCounts.length <= 31) return 7;
    return (dailyCounts.length / 5).roundToDouble();
  }
}

class _TrendCard extends StatelessWidget {
  final double periodChange;
  final bool hasPreviousPeriodData;
  final AnalyticsPeriod period;

  const _TrendCard({
    required this.periodChange,
    required this.hasPreviousPeriodData,
    required this.period,
  });

  String get _periodLabel => switch (period) {
        AnalyticsPeriod.week => 'Week over Week',
        AnalyticsPeriod.month => 'Month over Month',
        AnalyticsPeriod.year => 'Year over Year',
        AnalyticsPeriod.allTime => 'Week over Week',
      };

  @override
  Widget build(BuildContext context) {
    // If no previous period data, show a different message
    if (!hasPreviousPeriodData) {
      return Card(
        color: Colors.grey.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _periodLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Not enough data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isUp = periodChange > 0;
    final isDown = periodChange < 0;

    Color color;
    IconData icon;
    String label;

    if (isUp) {
      color = Colors.green;
      icon = Icons.trending_up;
      label = '+${periodChange.toStringAsFixed(1)}%';
    } else if (isDown) {
      color = Colors.red;
      icon = Icons.trending_down;
      label = '${periodChange.toStringAsFixed(1)}%';
    } else {
      color = Colors.grey;
      icon = Icons.trending_flat;
      label = 'No change';
    }

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _periodLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
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

class _BirdBreakdown extends StatelessWidget {
  final List<BirdEggStats> birdStats;

  const _BirdBreakdown({required this.birdStats});

  @override
  Widget build(BuildContext context) {
    final maxEggs = birdStats.isEmpty
        ? 1
        : birdStats.map((s) => s.eggCount).reduce((a, b) => math.max(a, b));

    return Card(
      child: Column(
        children: birdStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stats = entry.value;
          final isTopPerformer = index == 0 && stats.eggCount > 0;

          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundImage: stats.bird.photoPrimary != null
                      ? FileImage(File(stats.bird.photoPrimary!))
                      : null,
                  child: stats.bird.photoPrimary == null
                      ? Image.asset(
                          'assets/icons/cute_hen.png',
                          width: 24,
                          height: 24,
                        )
                      : null,
                ),
                if (isTopPerformer)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(child: Text(stats.bird.name)),
                Text(
                  '${stats.eggCount} eggs',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: maxEggs > 0 ? stats.eggCount / maxEggs : 0,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
                if (stats.eggCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${stats.percentage.toStringAsFixed(0)}% - ${stats.eggCount} eggs / ${stats.activeDays} active days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

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
              onPressed: () => context.go('/eggs'),
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
                        'No recent activity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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
      onTap: () => context.push('/eggs/log', extra: log),
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

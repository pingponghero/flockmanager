import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/flock_provider.dart';

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
          ref.invalidate(analyticsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Flock filter
            flocksAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
              data: (flocks) => DropdownMenu<String?>(
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
            ),
            const SizedBox(height: 16),

            // Period selector
            _PeriodSelector(
              selectedPeriod: selectedPeriod,
              onPeriodChanged: (period) {
                ref.read(analyticsPeriodProvider.notifier).state = period;
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
                  _TrendCard(weekOverWeekChange: analytics.weekOverWeekChange),
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

                  // Freeloaders
                  if (analytics.freeloaders.isNotEmpty) ...[
                    _FreeloardersCard(freeloaders: analytics.freeloaders),
                    const SizedBox(height: 24),
                  ],
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
  final double weekOverWeekChange;

  const _TrendCard({required this.weekOverWeekChange});

  @override
  Widget build(BuildContext context) {
    final isUp = weekOverWeekChange > 0;
    final isDown = weekOverWeekChange < 0;

    Color color;
    IconData icon;
    String label;

    if (isUp) {
      color = Colors.green;
      icon = Icons.trending_up;
      label = '+${weekOverWeekChange.toStringAsFixed(1)}%';
    } else if (isDown) {
      color = Colors.red;
      icon = Icons.trending_down;
      label = '${weekOverWeekChange.toStringAsFixed(1)}%';
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
                    'Week over Week',
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
                const SizedBox(height: 4),
                Text(
                  '${stats.percentage.toStringAsFixed(1)}% • ${stats.layingRate.toStringAsFixed(1)} eggs/week',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FreeloardersCard extends StatelessWidget {
  final List<BirdEggStats> freeloaders;

  const _FreeloardersCard({required this.freeloaders});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Freeloaders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${freeloaders.length} bird${freeloaders.length == 1 ? '' : 's'} with no eggs this period:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: freeloaders.map((stats) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundImage: stats.bird.photoPrimary != null
                        ? FileImage(File(stats.bird.photoPrimary!))
                        : null,
                    child: stats.bird.photoPrimary == null
                        ? Image.asset(
                            'assets/icons/cute_hen.png',
                            width: 16,
                            height: 16,
                          )
                        : null,
                  ),
                  label: Text(stats.bird.name),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

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
import '../../widgets/flock_dropdown.dart';
import '../../utils/edge_insets.dart';
import '../../widgets/scaffold_with_nav_bar.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final ScrollController _scrollController = ScrollController();
  static const _statsTabIndex = 2;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for tab changes and reset scroll when Stats tab becomes active
    ref.listen<int>(tabChangeNotifierProvider, (previous, current) {
      if (current == _statsTabIndex && previous != _statsTabIndex) {
        _scrollToTop();
      }
    });

    final selectedPeriod = ref.watch(analyticsPeriodProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final selectedFlockId = ref.watch(selectedFlockIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Stats'),
      ),
      body: Column(
        children: [
          // Sticky selectors at top
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                // Flock filter (hidden if only 1 flock)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FlockDropdown(
                    selectedFlockId: selectedFlockId,
                    onChanged: (value) {
                      ref.read(selectedFlockIdProvider.notifier).selectFlock(value);
                    },
                  ),
                ),
                // Period selector
                DropdownMenu<AnalyticsPeriod>(
                  initialSelection: selectedPeriod,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Period'),
                  dropdownMenuEntries: AnalyticsPeriod.values
                      .map((period) => DropdownMenuEntry(
                            value: period,
                            label: period.displayName,
                          ))
                      .toList(),
                  onSelected: (value) {
                    if (value != null) {
                      ref.read(analyticsPeriodProvider.notifier).setPeriod(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Loading indicator (shows while refreshing, doesn't disrupt scroll)
          if (analyticsAsync.isLoading)
            const LinearProgressIndicator(),
          // Scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ScaffoldMessenger.of(context).clearSnackBars();
                ref.invalidate(analyticsProvider);
                // Wait for data to reload, then scroll to top
                await ref.read(analyticsProvider.future);
                _scrollToTop();
              },
              child: Builder(
                builder: (context) {
                  // Show error state
                  if (analyticsAsync.hasError && !analyticsAsync.hasValue) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${analyticsAsync.error}'),
                          ],
                        ),
                      ),
                    );
                  }

                  // Show loading spinner only on first load (no previous data)
                  final analytics = analyticsAsync.hasValue ? analyticsAsync.value : null;
                  if (analytics == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  // Show data (keeps previous data visible while loading new)
                  return ListView(
                    controller: _scrollController,
                    padding: pagePadding(context),
                    children: [
                      Column(
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
                        _ProductionChart(
                          chartData: analytics.chartData,
                          granularity: analytics.chartGranularity,
                        ),
                        const SizedBox(height: 16),

                        // Trend indicator (not shown for All Time - no meaningful comparison)
                        if (selectedPeriod != AnalyticsPeriod.allTime) ...[
                          _TrendCard(
                            periodChange: analytics.periodChange,
                            hasPreviousPeriodData: analytics.hasPreviousPeriodData,
                            comparisonEndDate: analytics.comparisonEndDate,
                            period: selectedPeriod,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Per-bird breakdown (collapsible)
                        if (analytics.birdStats.isNotEmpty) ...[
                          _CollapsibleBirdBreakdown(birdStats: analytics.birdStats),
                          const SizedBox(height: 16),
                        ],

                        // Recent Activity (collapsible)
                        const _CollapsibleRecentActivity(),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
}

class _SummaryStats extends StatelessWidget {
  final AnalyticsSummary analytics;

  const _SummaryStats({required this.analytics});

  static final _numberFormat = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Eggs',
                  value: _numberFormat.format(analytics.totalEggs),
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
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Best Day',
                  value: '${analytics.bestDayCount}',
                  subtitle: analytics.bestDayDate != null
                      ? DateFormat.yMMMd().format(analytics.bestDayDate!)
                      : null,
                  icon: Icons.star,
                  iconColor: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Days Logged',
                  value: '${analytics.daysWithData}',
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
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
  final List<ChartDataPoint> chartData;
  final ChartGranularity granularity;

  const _ProductionChart({
    required this.chartData,
    required this.granularity,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
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

    final maxY = chartData
        .map((e) => e.value)
        .reduce((a, b) => math.max(a, b));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Y-axis label
            Text(
              granularity.yAxisLabel,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
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
                          if (index < 0 || index >= chartData.length) {
                            return const SizedBox.shrink();
                          }
                          final point = chartData[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatXLabel(point),
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
                          // Show decimals for averages, integers for daily
                          final label = granularity == ChartGranularity.daily
                              ? value.toInt().toString()
                              : value.toStringAsFixed(1);
                          return Text(
                            label,
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
                  maxX: (chartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY + (maxY * 0.1).ceilToDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.value,
                        );
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: chartData.length <= 14,
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
                          final point = chartData[index];
                          return LineTooltipItem(
                            _formatTooltip(point),
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
          ],
        ),
      ),
    );
  }

  bool get _spansMultipleYears {
    if (chartData.isEmpty) return false;
    return chartData.first.startDate.year != chartData.last.startDate.year;
  }

  String _formatXLabel(ChartDataPoint point) {
    if (granularity == ChartGranularity.daily) {
      return DateFormat.MMMd().format(point.startDate);
    } else if (granularity == ChartGranularity.monthly) {
      // Include year if data spans multiple years
      if (_spansMultipleYears) {
        return DateFormat("MMM ''yy").format(point.startDate);
      }
      return DateFormat.MMM().format(point.startDate);
    } else {
      // Weekly — use short date; include year if spanning multiple years
      if (_spansMultipleYears) {
        return DateFormat("M/d/yy").format(point.startDate);
      }
      return DateFormat.MMMd().format(point.startDate);
    }
  }

  String _formatTooltip(ChartDataPoint point) {
    // Include year in tooltips if data spans multiple years
    final dateFormat = _spansMultipleYears ? DateFormat.yMMMd() : DateFormat.MMMd();

    if (granularity == ChartGranularity.daily) {
      return '${dateFormat.format(point.startDate)}\n${point.totalEggs} eggs';
    } else {
      // Show range and both total and average
      final dateRange = point.startDate == point.endDate
          ? dateFormat.format(point.startDate)
          : '${dateFormat.format(point.startDate)} - ${dateFormat.format(point.endDate)}';
      return '$dateRange\n${point.totalEggs} eggs (${point.value.toStringAsFixed(1)}/day)';
    }
  }

  double _calculateInterval() {
    // Aim for ~5-6 labels on the x-axis regardless of data length
    if (chartData.length <= 7) return 1;
    return (chartData.length / 5).ceilToDouble();
  }
}

class _TrendCard extends StatelessWidget {
  final double periodChange;
  final bool hasPreviousPeriodData;
  final DateTime? comparisonEndDate;
  final AnalyticsPeriod period;

  const _TrendCard({
    required this.periodChange,
    required this.hasPreviousPeriodData,
    this.comparisonEndDate,
    required this.period,
  });

  String get _periodLabel => switch (period) {
        AnalyticsPeriod.week => 'vs Previous 7 Days',
        AnalyticsPeriod.month => 'Month over Month',
        AnalyticsPeriod.year => 'Year over Year',
        AnalyticsPeriod.allTime => 'Week over Week',
      };

  String? get _comparisonSubtitle {
    if (comparisonEndDate == null) return null;
    return switch (period) {
      AnalyticsPeriod.week =>
        'vs ${DateFormat.MMMd().format(comparisonEndDate!.subtract(const Duration(days: 6)))} - ${DateFormat.MMMd().format(comparisonEndDate!)}',
      AnalyticsPeriod.allTime =>
        'vs ${DateFormat.EEEE().format(comparisonEndDate!)} last week',
      AnalyticsPeriod.month =>
        'vs the ${_ordinal(comparisonEndDate!.day)} last month',
      AnalyticsPeriod.year =>
        'vs ${DateFormat.MMMd().format(comparisonEndDate!)} last year',
    };
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }

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

    final subtitle = _comparisonSubtitle;

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
                  if (subtitle != null)
                    Text(
                      subtitle,
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

class _CollapsibleBirdBreakdown extends StatelessWidget {
  final List<BirdEggStats> birdStats;

  const _CollapsibleBirdBreakdown({required this.birdStats});

  @override
  Widget build(BuildContext context) {
    final maxEggs = birdStats.isEmpty
        ? 1
        : birdStats.map((s) => s.eggCount).reduce((a, b) => math.max(a, b));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          'Per-Bird Breakdown',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${birdStats.length} birds',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        initiallyExpanded: false,
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
                  value: maxEggs > 0 ? stats.eggCount.toDouble() / maxEggs : 0.0,
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

class _CollapsibleRecentActivity extends ConsumerWidget {
  const _CollapsibleRecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(recentEggLogsProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: logsAsync.when(
        loading: () => const ExpansionTile(
          title: Text('Recent Activity'),
          initiallyExpanded: false,
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
        error: (error, stack) => ExpansionTile(
          title: Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          initiallyExpanded: false,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $error'),
              ),
            ),
          ],
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return ExpansionTile(
              title: Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'No recent activity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              initiallyExpanded: false,
              children: const [],
            );
          }

          return ExpansionTile(
            title: Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Row(
              children: [
                Text(
                  '${logs.length} recent logs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.go('/eggs'),
                  child: Text(
                    'See all',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
            initiallyExpanded: false,
            children: logs.map((log) => _ActivityTile(log: log)).toList(),
          );
        },
      ),
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

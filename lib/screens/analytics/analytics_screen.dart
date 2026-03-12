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
import '../../providers/forecast_provider.dart';
import '../../utils/daylight_calculator.dart';
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

                        // Trend indicator (not shown for All Time or when no comparison data exists)
                        if (selectedPeriod != AnalyticsPeriod.allTime &&
                            analytics.hasPreviousPeriodData) ...[
                          _TrendCard(
                            periodChange: analytics.periodChange,
                            hasPreviousPeriodData: analytics.hasPreviousPeriodData,
                            comparisonEndDate: analytics.comparisonEndDate,
                            period: selectedPeriod,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Forecast card
                        const _ForecastCard(),
                        const SizedBox(height: 24),

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
                  maxY: maxY + (maxY * 0.2).ceilToDouble(),
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
                      preventCurveOverShooting: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: chartData.length <= 14,
                        getDotPainter: (spot, percent, barData, index) {
                          final isProjected = index < chartData.length &&
                              chartData[index].isProjected;
                          if (isProjected) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Theme.of(context).colorScheme.surface,
                              strokeWidth: 2,
                              strokeColor:
                                  Theme.of(context).colorScheme.primary,
                            );
                          }
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
      final suffix = point.isProjected ? ' (projected)' : '';
      return '${dateFormat.format(point.startDate)}\n${point.totalEggs} eggs$suffix';
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
        AnalyticsPeriod.last30Days => 'vs Previous 30 Days',
        AnalyticsPeriod.month => 'Month over Month',
        AnalyticsPeriod.year => 'Year over Year',
        AnalyticsPeriod.allTime => 'Week over Week',
      };

  String? get _comparisonSubtitle {
    if (comparisonEndDate == null) return null;
    return switch (period) {
      AnalyticsPeriod.week =>
        'vs ${DateFormat.MMMd().format(comparisonEndDate!.subtract(const Duration(days: 6)))} - ${DateFormat.MMMd().format(comparisonEndDate!)}',
      AnalyticsPeriod.last30Days =>
        'vs ${DateFormat.MMMd().format(comparisonEndDate!.subtract(const Duration(days: 29)))} - ${DateFormat.MMMd().format(comparisonEndDate!)}',
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

class _ForecastCard extends ConsumerWidget {
  const _ForecastCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastProvider);
    final period = ref.watch(analyticsPeriodProvider);

    return forecastAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (forecast) {
        if (!forecast.hasEnoughData) return const SizedBox.shrink();

        final year = DateTime.now().year;

        // Choose which projection to highlight based on period
        final isYearView = period == AnalyticsPeriod.year ||
            period == AnalyticsPeriod.allTime;

        final (label, value, subtitle) = switch (period) {
          AnalyticsPeriod.week => (
              'Next 7 Days',
              '${forecast.projectedWeek} eggs',
              '${forecast.currentPerHenRate.toStringAsFixed(2)}/hen/day · ${forecast.activeHens} hens',
            ),
          AnalyticsPeriod.last30Days ||
          AnalyticsPeriod.month =>
            (
              'Next 30 Days',
              '${forecast.projectedMonth} eggs',
              '${forecast.currentPerHenRate.toStringAsFixed(2)}/hen/day · ${forecast.activeHens} hens',
            ),
          AnalyticsPeriod.year ||
          AnalyticsPeriod.allTime =>
            (
              '$year Forecast',
              '${NumberFormat('#,###').format(forecast.projectedYear)} eggs',
              'daylight-adjusted · ${forecast.activeHens} hens',
            ),
        };

        return GestureDetector(
          onTap: () => _showForecastDetails(context, forecast, year, period),
          child: Card(
            color: Colors.amber.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_graph,
                        color: Colors.amber[800],
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[800],
                        size: 20,
                      ),
                    ],
                  ),
                  // Monthly breakdown for year/all-time views
                  if (isYearView && forecast.monthlyForecasts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _MonthlyForecastBars(months: forecast.monthlyForecasts),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showForecastDetails(
    BuildContext context,
    ForecastResult forecast,
    int year,
    AnalyticsPeriod period,
  ) {
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final isYearView =
        period == AnalyticsPeriod.year || period == AnalyticsPeriod.allTime;

    // Count months with actual data
    final monthsWithData =
        forecast.monthlyForecasts.where((m) => m.isActual).length;
    final totalDaysRecorded = forecast.monthlyForecasts
        .fold(0, (sum, m) => sum + m.daysRecorded);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'How this forecast works',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Data summary
            _DetailSection(
              icon: Icons.data_usage,
              title: 'Your Data',
              body: '$totalDaysRecorded days of egg logs across '
                  '$monthsWithData month${monthsWithData == 1 ? '' : 's'} '
                  'in $year. You have ${forecast.activeHens} active '
                  'hen${forecast.activeHens == 1 ? '' : 's'}.',
            ),
            const SizedBox(height: 12),

            // Per-hen rate
            _DetailSection(
              icon: Icons.calculate,
              title: 'Per-Hen Rate',
              body: 'Your flock currently lays '
                  '${forecast.currentPerHenRate.toStringAsFixed(2)} '
                  'eggs per hen per day. We use per-hen rates instead '
                  'of raw totals so the forecast stays accurate even '
                  'if your flock size changes.',
            ),
            const SizedBox(height: 12),

            // Short-term explanation
            if (!isYearView) ...[
              _DetailSection(
                icon: Icons.straighten,
                title: 'Short-Term Projection',
                body: 'This forecast multiplies your current per-hen '
                    'rate by your ${forecast.activeHens} active hens. '
                    'It assumes recent production continues at the same '
                    'pace — accurate for the next few weeks.',
              ),
              const SizedBox(height: 12),
              _DetailSection(
                icon: Icons.wb_sunny,
                title: 'Daylight',
                body: 'For longer-range forecasts, switch to "This Year" '
                    'or "All Time" to see daylight-adjusted projections '
                    'that account for seasonal changes in production.',
              ),
            ],

            // Daylight adjustment (year views)
            if (isYearView) ...[
              _DetailSection(
                icon: Icons.wb_sunny,
                title: 'Daylight Adjustment',
                body: 'Chickens lay more eggs in longer days. At your '
                    'latitude (${forecast.latitude}°), daylight ranges from '
                    '${_minDaylight(forecast.latitude)} to '
                    '${_maxDaylight(forecast.latitude)} hours. For months '
                    'without data yet, we blend your existing months\' rates '
                    'weighted by how similar their daylight hours are.',
              ),
              const SizedBox(height: 24),

              // Monthly table
              Text(
                'Monthly Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // Header row
              Row(
                children: [
                  const SizedBox(width: 48, child: Text('Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  const Expanded(child: Text('Eggs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                  const SizedBox(width: 60, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                  const SizedBox(width: 48, child: Text('Light', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                  const SizedBox(width: 56, child: Text('Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                ],
              ),
              const Divider(),

              ...forecast.monthlyForecasts.map((m) {
                final isPast = m.month < now.month;
                final isCurrent = m.month == now.month;
                final eggs = isPast ? m.actualEggs : m.forecastEggs;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          monthNames[m.month - 1],
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$eggs',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          m.perHenRate > 0 ? m.perHenRate.toStringAsFixed(2) : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${m.daylightHours.toStringAsFixed(1)}h',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          isPast
                              ? 'actual'
                              : isCurrent
                                  ? 'partial'
                                  : 'forecast',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: isPast ? FontStyle.normal : FontStyle.italic,
                            color: isPast
                                ? Theme.of(context).colorScheme.primary
                                : Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              // Total row
              const Divider(),
              Row(
                children: [
                  const SizedBox(
                    width: 48,
                    child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Expanded(
                    child: Text(
                      '${NumberFormat('#,###').format(forecast.projectedYear)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 60),
                  const SizedBox(width: 48),
                  const SizedBox(width: 56),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _minDaylight(int latitude) {
    final curve = DaylightCalculator.getMonthlyDaylightCurve(latitude);
    return curve.reduce(math.min).toStringAsFixed(1);
  }

  String _maxDaylight(int latitude) {
    final curve = DaylightCalculator.getMonthlyDaylightCurve(latitude);
    return curve.reduce(math.max).toStringAsFixed(1);
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyForecastBars extends StatelessWidget {
  final List<MonthForecast> months;

  const _MonthlyForecastBars({required this.months});

  static const _monthLabels = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];

  @override
  Widget build(BuildContext context) {
    final maxEggs = months
        .map((m) => math.max(m.actualEggs, m.forecastEggs))
        .fold(0, (a, b) => math.max(a, b));

    if (maxEggs == 0) return const SizedBox.shrink();

    final now = DateTime.now();
    final currentMonth = now.month;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final m = months[i];
          final eggs = m.month < currentMonth ? m.actualEggs : m.forecastEggs;
          final fraction = maxEggs > 0 ? eggs / maxEggs : 0.0;
          final isActual = m.month < currentMonth;
          final isCurrent = m.month == currentMonth;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: (fraction * 70).clamp(2.0, 70.0),
                    decoration: BoxDecoration(
                      color: isActual
                          ? primary
                          : isCurrent
                              ? primary.withValues(alpha: 0.5)
                              : Colors.amber[300],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _monthLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent
                          ? primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/golden_egg_provider.dart';
import 'golden_egg_tooltip.dart';

/// Daily radial chart showing egg production for the last 14-30 days.
/// Days are arranged radially with most recent at top (12 o'clock).
class GoldenEggDailyChart extends StatefulWidget {
  final GoldenEggChartData data;

  const GoldenEggDailyChart({
    super.key,
    required this.data,
  });

  @override
  State<GoldenEggDailyChart> createState() => _GoldenEggDailyChartState();
}

class _GoldenEggDailyChartState extends State<GoldenEggDailyChart> {
  DailyEggData? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeekView = widget.data.dailyCounts.length <= 7;
    final periodLabel = isWeekView ? 'This Week' : 'This Month';
    final prevPeriodLabel = isWeekView ? 'Last Week' : 'Last Month';
    final prevTotal = widget.data.prevPeriodTotal;

    return Column(
      children: [
        // Chart - centered and full width
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth;

                  return GestureDetector(
                    onTapDown: (details) => _handleTap(details, size),
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _DailyRadialPainter(
                        data: widget.data,
                        selectedDay: _selectedDay,
                        primaryColor: theme.colorScheme.primary,
                        secondaryColor: theme.colorScheme.secondary,
                        surfaceColor: theme.colorScheme.surface,
                        onSurfaceColor: theme.colorScheme.onSurface,
                        onSurfaceVariantColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Legend - vertical stack
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              // Previous period (if data exists)
              if (prevTotal > 0)
                _LegendRow(
                  indicator: Container(
                    width: 14,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  label: prevPeriodLabel,
                  value: '$prevTotal eggs',
                  theme: theme,
                  isMuted: true,
                ),
              // Current period
              _LegendRow(
                indicator: Container(
                  width: 14,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                label: periodLabel,
                value: '${widget.data.totalEggs} eggs',
                theme: theme,
              ),
              // Daily average
              _LegendRow(
                indicator: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
                label: 'Average',
                value: '${widget.data.dailyAverage.toStringAsFixed(1)}/day',
                theme: theme,
                isMuted: true,
              ),
            ],
          ),
        ),
        // Tooltip
        if (_selectedDay != null) ...[
          const SizedBox(height: 8),
          GoldenEggTooltip(
            data: _selectedDay!,
            average: widget.data.dailyAverage,
            onClose: () => setState(() => _selectedDay = null),
          ),
        ],
      ],
    );
  }

  void _handleTap(TapDownDetails details, double size) {
    final center = Offset(size / 2, size / 2);
    final tapPosition = details.localPosition;

    // Calculate angle and distance from center
    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Ignore taps in center area or outside bars (matching new proportions)
    final radius = size / 2;
    final innerRadius = radius * 0.15;
    final outerRadius = radius * 0.80;
    if (distance < innerRadius || distance > outerRadius) {
      setState(() => _selectedDay = null);
      return;
    }

    // Calculate angle (0 = top, clockwise)
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    // Find which day was tapped
    final days = widget.data.dailyCounts;
    if (days.isEmpty) return;

    final anglePerDay = 2 * math.pi / days.length;
    final dayIndex = (angle / anglePerDay).floor();

    if (dayIndex >= 0 && dayIndex < days.length) {
      setState(() {
        _selectedDay = _selectedDay?.dayIndex == days[dayIndex].dayIndex
            ? null // Toggle off if same day
            : days[dayIndex];
      });
    }
  }
}

class _DailyRadialPainter extends CustomPainter {
  final GoldenEggChartData data;
  final DailyEggData? selectedDay;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color onSurfaceVariantColor;

  _DailyRadialPainter({
    required this.data,
    required this.selectedDay,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.onSurfaceVariantColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Radii for different elements (matching yearly chart proportions)
    final chartInner = radius * 0.12;
    final chartOuter = radius * 0.82;
    final barStartRadius = radius * 0.20;
    final barMaxRadius = radius * 0.75;
    final labelRadius = radius * 0.90; // Outside the outer boundary circle

    // Draw grid lines first (like yearly view)
    _drawGridLines(canvas, center, chartInner, chartOuter, barStartRadius, barMaxRadius);

    // Draw spokes for each day
    _drawDaySpokes(canvas, center, chartInner, chartOuter);

    // Draw average reference circle
    if (data.maxDailyCount > 0 && data.dailyAverage > 0) {
      final avgRadius = barStartRadius +
          (barMaxRadius - barStartRadius) *
              (data.dailyAverage / data.maxDailyCount);
      final avgPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, avgRadius, avgPaint);
    }

    // Draw bars for each day
    _drawDayBars(canvas, center, barStartRadius, barMaxRadius);

    // Draw day labels
    _drawDayLabels(canvas, center, labelRadius);

    // Draw center point (like yearly view - subtle ring + dot)
    _drawCenterPoint(canvas, center, radius);
  }

  void _drawGridLines(
    Canvas canvas,
    Offset center,
    double chartInner,
    double chartOuter,
    double barStartRadius,
    double barMaxRadius,
  ) {
    final gridPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Outer boundary circle for containment
    canvas.drawCircle(center, chartOuter, gridPaint);

    // Concentric circles (4 rings for daily view)
    const ringCount = 4;
    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final maxCount = data.maxDailyCount;

    // Round max to a nice number for grid labels
    final roundedMax = _roundToNice(maxCount);
    final step = roundedMax ~/ ringCount;

    for (var i = 1; i <= ringCount; i++) {
      // Grid circles span from bar start to bar max
      final ringRadius = barStartRadius + (barMaxRadius - barStartRadius) * (i / ringCount);
      canvas.drawCircle(center, ringRadius, gridPaint);

      // Value labels on inner circles only (skip outermost - like yearly)
      if (step > 0 && i < ringCount) {
        final value = step * i;
        labelPainter.text = TextSpan(
          text: '$value',
          style: TextStyle(
            color: onSurfaceVariantColor.withValues(alpha: 0.4),
            fontSize: 8,
          ),
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(center.dx + ringRadius + 2, center.dy - labelPainter.height / 2),
        );
      }
    }
  }

  void _drawDaySpokes(
    Canvas canvas,
    Offset center,
    double chartInner,
    double chartOuter,
  ) {
    final days = data.dailyCounts;
    if (days.isEmpty) return;

    final gridPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final anglePerDay = 2 * math.pi / days.length;

    for (var i = 0; i < days.length; i++) {
      final angle = -math.pi / 2 + i * anglePerDay;
      final start = Offset(
        center.dx + chartInner * math.cos(angle),
        center.dy + chartInner * math.sin(angle),
      );
      final end = Offset(
        center.dx + chartOuter * math.cos(angle),
        center.dy + chartOuter * math.sin(angle),
      );
      canvas.drawLine(start, end, gridPaint);
    }
  }

  void _drawDayBars(
    Canvas canvas,
    Offset center,
    double barStartRadius,
    double barMaxRadius,
  ) {
    final days = data.dailyCounts;
    if (days.isEmpty) return;

    final anglePerDay = 2 * math.pi / days.length;
    final barWidth = anglePerDay * 0.6; // 60% of available angle

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final startAngle = -math.pi / 2 + i * anglePerDay - barWidth / 2;

      // Calculate bar length based on count
      final normalizedCount =
          data.maxDailyCount > 0 ? day.count / data.maxDailyCount : 0.0;
      final barEndRadius =
          barStartRadius + (barMaxRadius - barStartRadius) * normalizedCount;

      // Determine if this day is selected
      final isSelected = selectedDay?.dayIndex == day.dayIndex;

      // Bar paint
      final barPaint = Paint()
        ..color = isSelected
            ? secondaryColor
            : primaryColor.withValues(alpha: 0.6 + normalizedCount * 0.4)
        ..style = PaintingStyle.fill;

      // Draw bar as arc
      if (day.count > 0) {
        final barPath = Path();
        barPath.addArc(
          Rect.fromCircle(center: center, radius: barStartRadius),
          startAngle,
          barWidth,
        );
        barPath.arcTo(
          Rect.fromCircle(center: center, radius: barEndRadius),
          startAngle + barWidth,
          -barWidth,
          false,
        );
        barPath.close();
        canvas.drawPath(barPath, barPaint);

        // Draw bar outline
        final outlinePaint = Paint()
          ..color = isSelected ? secondaryColor : primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.5 : 0.5;
        canvas.drawPath(barPath, outlinePaint);
      }

      // Draw tick mark for zero days
      if (day.count == 0) {
        final tickPaint = Paint()
          ..color = onSurfaceVariantColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final tickAngle = startAngle + barWidth / 2;
        final tickStart = Offset(
          center.dx + barStartRadius * math.cos(tickAngle),
          center.dy + barStartRadius * math.sin(tickAngle),
        );
        final tickEnd = Offset(
          center.dx + (barStartRadius + 4) * math.cos(tickAngle),
          center.dy + (barStartRadius + 4) * math.sin(tickAngle),
        );
        canvas.drawLine(tickStart, tickEnd, tickPaint);
      }
    }
  }

  void _drawDayLabels(Canvas canvas, Offset center, double labelRadius) {
    final days = data.dailyCounts;
    if (days.isEmpty) return;

    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final isWeekView = days.length <= 7;
    final anglePerDay = 2 * math.pi / days.length;

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final angle = -math.pi / 2 + i * anglePerDay;
      final isSelected = selectedDay?.dayIndex == day.dayIndex;

      final labelX = center.dx + labelRadius * math.cos(angle);
      final labelY = center.dy + labelRadius * math.sin(angle);

      // Week view: show day letter (M, T, W...)
      // Month view: show day number (1, 2, 3... 28/31)
      final labelText = isWeekView
          ? DateFormat.E().format(day.date).substring(0, 1)
          : '${day.date.day}';

      final baseColor = isSelected ? secondaryColor : onSurfaceVariantColor;
      // Smaller font for month view to fit all 28-31 labels
      final fontSize = isSelected ? 11.0 : (isWeekView ? 10.0 : 8.0);

      // Style label with count like yearly view (only for week view)
      final count = day.count;
      labelPainter.text = TextSpan(
        children: [
          TextSpan(
            text: labelText,
            style: TextStyle(
              color: baseColor,
              fontSize: fontSize,
              fontWeight: isWeekView ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (count > 0 && isWeekView)
            TextSpan(
              text: ' $count',
              style: TextStyle(
                color: baseColor,
                fontSize: fontSize,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(labelX - labelPainter.width / 2, labelY - labelPainter.height / 2),
      );
    }
  }

  void _drawCenterPoint(Canvas canvas, Offset center, double radius) {
    // Simple center reference point - subtle ring (like yearly view)
    final ringRadius = radius * 0.04;

    // Outer ring
    final ringPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, ringRadius, ringPaint);

    // Center dot
    final dotPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, dotPaint);
  }

  /// Round a number to a nice value for grid labels
  int _roundToNice(int value) {
    if (value <= 0) return 0;
    if (value <= 4) return 4;
    if (value <= 8) return 8;
    if (value <= 12) return 12;
    if (value <= 16) return 16;
    if (value <= 20) return 20;
    if (value <= 25) return 25;
    // Round up to nearest 5
    return ((value + 4) ~/ 5) * 5;
  }

  @override
  bool shouldRepaint(_DailyRadialPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Legend row widget for consistent formatting (matching yearly view)
class _LegendRow extends StatelessWidget {
  final Widget indicator;
  final String label;
  final String value;
  final ThemeData theme;
  final bool isMuted;

  const _LegendRow({
    required this.indicator,
    required this.label,
    required this.value,
    required this.theme,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 20, child: Center(child: indicator)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isMuted
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
              fontWeight: isMuted ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

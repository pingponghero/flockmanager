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

    return Column(
      children: [
        // Chart
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = math.min(constraints.maxWidth, constraints.maxHeight);

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

    // Ignore taps in center area
    final innerRadius = size * 0.25;
    final outerRadius = size * 0.45;
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

    // Radii for different elements
    final innerRadius = radius * 0.3;
    final barStartRadius = radius * 0.35;
    final barMaxRadius = radius * 0.75;
    final labelRadius = radius * 0.88;

    // Draw background circle
    final bgPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.85, bgPaint);

    // Draw average reference circle
    if (data.maxDailyCount > 0) {
      final avgRadius = barStartRadius +
          (barMaxRadius - barStartRadius) *
              (data.dailyAverage / data.maxDailyCount);
      final avgPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, avgRadius, avgPaint);
    }

    // Draw bars for each day
    final days = data.dailyCounts;
    if (days.isEmpty) return;

    final anglePerDay = 2 * math.pi / days.length;
    final barWidth = anglePerDay * 0.7; // 70% of available angle

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
            : primaryColor.withValues(alpha: 0.7 + normalizedCount * 0.3)
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
          ..strokeWidth = isSelected ? 2 : 1;
        canvas.drawPath(barPath, outlinePaint);
      }

      // Draw tick mark even for zero days
      if (day.count == 0) {
        final tickPaint = Paint()
          ..color = onSurfaceVariantColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final tickAngle = startAngle + barWidth / 2;
        final tickStart = Offset(
          center.dx + barStartRadius * math.cos(tickAngle),
          center.dy + barStartRadius * math.sin(tickAngle),
        );
        final tickEnd = Offset(
          center.dx + (barStartRadius + 5) * math.cos(tickAngle),
          center.dy + (barStartRadius + 5) * math.sin(tickAngle),
        );
        canvas.drawLine(tickStart, tickEnd, tickPaint);
      }
    }

    // Draw day labels
    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final dateFormat = DateFormat.E(); // Mon, Tue, etc.

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final angle = -math.pi / 2 + i * anglePerDay;
      final isSelected = selectedDay?.dayIndex == day.dayIndex;

      // Only show labels for every few days if there are many
      final showLabel = days.length <= 14 || i % 2 == 0;
      if (!showLabel && !isSelected) continue;

      final labelX = center.dx + labelRadius * math.cos(angle);
      final labelY = center.dy + labelRadius * math.sin(angle);

      labelPainter.text = TextSpan(
        text: dateFormat.format(day.date).substring(0, 1), // First letter: M, T, W...
        style: TextStyle(
          color: isSelected ? secondaryColor : onSurfaceVariantColor,
          fontSize: isSelected ? 12 : 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(labelX - labelPainter.width / 2, labelY - labelPainter.height / 2),
      );
    }

    // Draw center circle with total
    final centerCirclePaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, centerCirclePaint);

    final centerBorderPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, innerRadius, centerBorderPaint);

    // Draw total eggs count in center
    final totalPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${data.totalEggs}\n',
            style: TextStyle(
              color: onSurfaceColor,
              fontSize: innerRadius * 0.5,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: 'eggs',
            style: TextStyle(
              color: onSurfaceVariantColor,
              fontSize: innerRadius * 0.25,
              height: 1.0,
            ),
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    totalPainter.layout();
    totalPainter.paint(
      canvas,
      Offset(
        center.dx - totalPainter.width / 2,
        center.dy - totalPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_DailyRadialPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.primaryColor != primaryColor;
  }
}

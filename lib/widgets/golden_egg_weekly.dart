import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/golden_egg_provider.dart';
import 'golden_egg_tooltip.dart';

/// Weekly radial chart showing egg production for the last 12 weeks.
/// Weeks are arranged radially with most recent at top (12 o'clock).
class GoldenEggWeeklyChart extends StatefulWidget {
  final GoldenEggChartData data;

  const GoldenEggWeeklyChart({
    super.key,
    required this.data,
  });

  @override
  State<GoldenEggWeeklyChart> createState() => _GoldenEggWeeklyChartState();
}

class _GoldenEggWeeklyChartState extends State<GoldenEggWeeklyChart> {
  WeeklyEggData? _selectedWeek;

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
                  painter: _WeeklyRadialPainter(
                    data: widget.data,
                    selectedWeek: _selectedWeek,
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
        if (_selectedWeek != null) ...[
          const SizedBox(height: 8),
          GoldenEggWeeklyTooltip(
            data: _selectedWeek!,
            onClose: () => setState(() => _selectedWeek = null),
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
      setState(() => _selectedWeek = null);
      return;
    }

    // Calculate angle (0 = top, clockwise)
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    // Find which week was tapped
    final weeks = widget.data.weeklyCounts;
    if (weeks.isEmpty) return;

    final anglePerWeek = 2 * math.pi / weeks.length;
    final weekIndex = (angle / anglePerWeek).floor();

    if (weekIndex >= 0 && weekIndex < weeks.length) {
      setState(() {
        final tappedWeek = weeks[weekIndex];
        _selectedWeek = _selectedWeek?.weekStart == tappedWeek.weekStart
            ? null // Toggle off if same week
            : tappedWeek;
      });
    }
  }
}

class _WeeklyRadialPainter extends CustomPainter {
  final GoldenEggChartData data;
  final WeeklyEggData? selectedWeek;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color onSurfaceVariantColor;

  _WeeklyRadialPainter({
    required this.data,
    required this.selectedWeek,
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
    final weeks = data.weeklyCounts;
    if (weeks.isNotEmpty && data.maxDailyCount > 0) {
      final avgWeekly = weeks.map((w) => w.totalCount).reduce((a, b) => a + b) / weeks.length;
      final avgRadius = barStartRadius +
          (barMaxRadius - barStartRadius) * (avgWeekly / data.maxDailyCount);
      final avgPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, avgRadius, avgPaint);
    }

    // Draw bars for each week
    if (weeks.isEmpty) return;

    final anglePerWeek = 2 * math.pi / weeks.length;
    final barWidth = anglePerWeek * 0.7; // 70% of available angle

    for (var i = 0; i < weeks.length; i++) {
      final week = weeks[i];
      final startAngle = -math.pi / 2 + i * anglePerWeek - barWidth / 2;

      // Calculate bar length based on count
      final normalizedCount =
          data.maxDailyCount > 0 ? week.totalCount / data.maxDailyCount : 0.0;
      final barEndRadius =
          barStartRadius + (barMaxRadius - barStartRadius) * normalizedCount;

      // Determine if this week is selected
      final isSelected = selectedWeek?.weekStart == week.weekStart;

      // Bar paint
      final barPaint = Paint()
        ..color = isSelected
            ? secondaryColor
            : primaryColor.withValues(alpha: 0.7 + normalizedCount * 0.3)
        ..style = PaintingStyle.fill;

      // Draw bar as arc
      if (week.totalCount > 0) {
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

      // Draw tick mark even for zero weeks
      if (week.totalCount == 0) {
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

    // Draw week labels
    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final dateFormat = DateFormat.Md(); // 1/15

    for (var i = 0; i < weeks.length; i++) {
      final week = weeks[i];
      final angle = -math.pi / 2 + i * anglePerWeek;
      final isSelected = selectedWeek?.weekStart == week.weekStart;

      final labelX = center.dx + labelRadius * math.cos(angle);
      final labelY = center.dy + labelRadius * math.sin(angle);

      labelPainter.text = TextSpan(
        text: dateFormat.format(week.weekStart),
        style: TextStyle(
          color: isSelected ? secondaryColor : onSurfaceVariantColor,
          fontSize: isSelected ? 10 : 8,
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
  bool shouldRepaint(_WeeklyRadialPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedWeek != selectedWeek ||
        oldDelegate.primaryColor != primaryColor;
  }
}

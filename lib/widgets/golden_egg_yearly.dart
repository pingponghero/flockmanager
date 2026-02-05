import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/golden_egg_provider.dart';
import '../utils/daylight_calculator.dart';
import 'golden_egg_tooltip.dart';

/// Yearly egg chart showing monthly production with daylight curve overlay.
/// Shows the full "golden egg" visualization for 90+ days of data.
class GoldenEggYearlyChart extends ConsumerStatefulWidget {
  final GoldenEggChartData data;

  const GoldenEggYearlyChart({
    super.key,
    required this.data,
  });

  @override
  ConsumerState<GoldenEggYearlyChart> createState() => _GoldenEggYearlyChartState();
}

class _GoldenEggYearlyChartState extends ConsumerState<GoldenEggYearlyChart> {
  MonthlyEggData? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latitude = ref.watch(userLatitudeProvider);
    final daylightCurve = DaylightCalculator.getMonthlyDaylightCurve(latitude);

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
                  painter: _YearlyEggPainter(
                    data: widget.data,
                    selectedMonth: _selectedMonth,
                    daylightCurve: daylightCurve,
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
        if (_selectedMonth != null) ...[
          const SizedBox(height: 8),
          GoldenEggMonthlyTooltip(
            data: _selectedMonth!,
            averageDaylight: daylightCurve[_selectedMonth!.month - 1],
            onClose: () => setState(() => _selectedMonth = null),
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

    // Ignore taps in center area or outside
    final innerRadius = size * 0.2;
    final outerRadius = size * 0.42;
    if (distance < innerRadius || distance > outerRadius) {
      setState(() => _selectedMonth = null);
      return;
    }

    // Calculate angle (0 = top/January, clockwise)
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    // Find which month was tapped
    final months = widget.data.monthlyCounts;
    if (months.isEmpty) return;

    final anglePerMonth = 2 * math.pi / 12;
    final monthIndex = (angle / anglePerMonth).floor();

    // Find the month data for this index
    final targetMonth = (monthIndex % 12) + 1; // 1-12
    final matchingMonth = months.where((m) => m.month == targetMonth).firstOrNull;

    if (matchingMonth != null) {
      setState(() {
        _selectedMonth = _selectedMonth?.month == matchingMonth.month
            ? null // Toggle off if same month
            : matchingMonth;
      });
    }
  }
}

class _YearlyEggPainter extends CustomPainter {
  final GoldenEggChartData data;
  final MonthlyEggData? selectedMonth;
  final List<double> daylightCurve;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color onSurfaceVariantColor;

  _YearlyEggPainter({
    required this.data,
    required this.selectedMonth,
    required this.daylightCurve,
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

    // Draw the egg-shaped background
    _drawEggBackground(canvas, center, radius);

    // Draw the daylight curve
    _drawDaylightCurve(canvas, center, radius);

    // Draw monthly production bars
    _drawMonthlyBars(canvas, center, radius);

    // Draw month labels
    _drawMonthLabels(canvas, center, radius);

    // Draw center stats
    _drawCenterStats(canvas, center, radius);
  }

  void _drawEggBackground(Canvas canvas, Offset center, double radius) {
    // Egg shape using a slightly vertically stretched ellipse
    final eggRadius = radius * 0.85;

    // Draw gradient background
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - eggRadius * 0.2, center.dy - eggRadius * 0.3),
        eggRadius * 1.2,
        [
          const Color(0xFFFFFBF0), // Warm cream
          const Color(0xFFFFF8E1), // Light cream
          secondaryColor.withValues(alpha: 0.15),
        ],
        [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, eggRadius, bgPaint);

    // Draw subtle border
    final borderPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, eggRadius, borderPaint);
  }

  void _drawDaylightCurve(Canvas canvas, Offset center, double radius) {
    if (daylightCurve.isEmpty) return;

    // Normalize daylight values (typically 8-17 hours)
    final minDaylight = daylightCurve.reduce(math.min);
    final maxDaylight = daylightCurve.reduce(math.max);
    final range = maxDaylight - minDaylight;

    if (range < 0.1) return; // Skip if no variation (equator)

    final innerRadius = radius * 0.35;
    final outerRadius = radius * 0.75;

    // Draw daylight curve as filled area
    final daylightPath = Path();
    final anglePerMonth = 2 * math.pi / 12;

    for (var i = 0; i < 12; i++) {
      final normalized = (daylightCurve[i] - minDaylight) / range;
      final curveRadius = innerRadius + (outerRadius - innerRadius) * normalized;
      final angle = -math.pi / 2 + i * anglePerMonth;

      final x = center.dx + curveRadius * math.cos(angle);
      final y = center.dy + curveRadius * math.sin(angle);

      if (i == 0) {
        daylightPath.moveTo(x, y);
      } else {
        // Smooth curve between points
        final prevAngle = -math.pi / 2 + (i - 1) * anglePerMonth;
        final prevNormalized = (daylightCurve[i - 1] - minDaylight) / range;

        final midAngle = prevAngle + anglePerMonth / 2;
        final midNormalized = (prevNormalized + normalized) / 2;
        final midRadius = innerRadius + (outerRadius - innerRadius) * midNormalized;

        final midX = center.dx + midRadius * math.cos(midAngle);
        final midY = center.dy + midRadius * math.sin(midAngle);

        daylightPath.quadraticBezierTo(midX, midY, x, y);
      }
    }

    // Close the path smoothly
    final firstNormalized = (daylightCurve[0] - minDaylight) / range;
    final firstRadius = innerRadius + (outerRadius - innerRadius) * firstNormalized;
    final firstAngle = -math.pi / 2;
    final firstX = center.dx + firstRadius * math.cos(firstAngle);
    final firstY = center.dy + firstRadius * math.sin(firstAngle);

    final lastNormalized = (daylightCurve[11] - minDaylight) / range;
    final lastAngle = -math.pi / 2 + 11 * anglePerMonth;
    final midAngle = lastAngle + anglePerMonth / 2;
    final midNormalized = (lastNormalized + firstNormalized) / 2;
    final midRadius = innerRadius + (outerRadius - innerRadius) * midNormalized;
    final midX = center.dx + midRadius * math.cos(midAngle);
    final midY = center.dy + midRadius * math.sin(midAngle);

    daylightPath.quadraticBezierTo(midX, midY, firstX, firstY);
    daylightPath.close();

    // Fill with semi-transparent gold
    final fillPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(daylightPath, fillPaint);

    // Draw outline
    final strokePaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(daylightPath, strokePaint);
  }

  void _drawMonthlyBars(Canvas canvas, Offset center, double radius) {
    final months = data.monthlyCounts;
    if (months.isEmpty) return;

    final innerRadius = radius * 0.28;
    final maxBarRadius = radius * 0.7;
    final anglePerMonth = 2 * math.pi / 12;
    final barWidth = anglePerMonth * 0.6;

    // Create a map for quick lookup
    final monthMap = <int, MonthlyEggData>{};
    for (final m in months) {
      monthMap[m.month] = m;
    }

    for (var month = 1; month <= 12; month++) {
      final monthData = monthMap[month];
      final startAngle = -math.pi / 2 + (month - 1) * anglePerMonth - barWidth / 2;

      if (monthData == null || monthData.totalCount == 0) {
        // Draw tick mark for empty months
        final tickPaint = Paint()
          ..color = onSurfaceVariantColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final tickAngle = startAngle + barWidth / 2;
        final tickStart = Offset(
          center.dx + innerRadius * math.cos(tickAngle),
          center.dy + innerRadius * math.sin(tickAngle),
        );
        final tickEnd = Offset(
          center.dx + (innerRadius + 5) * math.cos(tickAngle),
          center.dy + (innerRadius + 5) * math.sin(tickAngle),
        );
        canvas.drawLine(tickStart, tickEnd, tickPaint);
        continue;
      }

      // Calculate bar length
      final normalizedCount =
          data.maxDailyCount > 0 ? monthData.totalCount / data.maxDailyCount : 0.0;
      final barEndRadius = innerRadius + (maxBarRadius - innerRadius) * normalizedCount;

      final isSelected = selectedMonth?.month == month;

      // Bar paint
      final barPaint = Paint()
        ..color = isSelected
            ? secondaryColor
            : primaryColor.withValues(alpha: 0.6 + normalizedCount * 0.4)
        ..style = PaintingStyle.fill;

      // Draw bar as arc
      final barPath = Path();
      barPath.addArc(
        Rect.fromCircle(center: center, radius: innerRadius),
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
  }

  void _drawMonthLabels(Canvas canvas, Offset center, double radius) {
    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final labelRadius = radius * 0.88;
    final anglePerMonth = 2 * math.pi / 12;

    final monthNames = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    for (var i = 0; i < 12; i++) {
      final month = i + 1;
      final angle = -math.pi / 2 + i * anglePerMonth;
      final isSelected = selectedMonth?.month == month;

      final labelX = center.dx + labelRadius * math.cos(angle);
      final labelY = center.dy + labelRadius * math.sin(angle);

      labelPainter.text = TextSpan(
        text: monthNames[i],
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
  }

  void _drawCenterStats(Canvas canvas, Offset center, double radius) {
    final innerRadius = radius * 0.22;

    // Draw center circle
    final centerPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, centerPaint);

    final borderPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, innerRadius, borderPaint);

    // Draw stats
    final totalPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${data.totalEggs}\n',
            style: TextStyle(
              color: onSurfaceColor,
              fontSize: innerRadius * 0.55,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: 'eggs',
            style: TextStyle(
              color: onSurfaceVariantColor,
              fontSize: innerRadius * 0.3,
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
  bool shouldRepaint(_YearlyEggPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedMonth != selectedMonth ||
        oldDelegate.daylightCurve != daylightCurve ||
        oldDelegate.primaryColor != primaryColor;
  }
}

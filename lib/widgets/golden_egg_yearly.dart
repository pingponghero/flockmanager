import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/golden_egg_provider.dart';
import '../utils/daylight_calculator.dart';
import 'golden_egg_tooltip.dart';

/// Yearly egg chart showing monthly production with daylight curve overlay.
/// Winter is always at the bottom of the chart.
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
    final isNorthern = latitude >= 0;

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
                    onTapDown: (details) => _handleTap(details, size, isNorthern),
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _YearlyEggPainter(
                        data: widget.data,
                        selectedMonth: _selectedMonth,
                        daylightCurve: daylightCurve,
                        isNorthernHemisphere: isNorthern,
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
        // Daylight legend
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Daylight hours',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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

  void _handleTap(TapDownDetails details, double size, bool isNorthern) {
    final center = Offset(size / 2, size / 2);
    final tapPosition = details.localPosition;

    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final innerRadius = size * 0.2;
    final outerRadius = size * 0.42;
    if (distance < innerRadius || distance > outerRadius) {
      setState(() => _selectedMonth = null);
      return;
    }

    // Calculate angle from top, clockwise
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    final anglePerMonth = 2 * math.pi / 12;

    // Adjust for hemisphere rotation (Northern: July at top, Southern: January at top)
    final rotationOffset = isNorthern ? 6 : 0; // 6 months = 180 degrees
    final adjustedAngle = (angle + rotationOffset * anglePerMonth) % (2 * math.pi);
    final monthIndex = (adjustedAngle / anglePerMonth).floor();
    final targetMonth = (monthIndex % 12) + 1;

    final months = widget.data.monthlyCounts;
    final matchingMonth = months.where((m) => m.month == targetMonth).firstOrNull;

    if (matchingMonth != null) {
      setState(() {
        _selectedMonth = _selectedMonth?.month == matchingMonth.month
            ? null
            : matchingMonth;
      });
    }
  }
}

class _YearlyEggPainter extends CustomPainter {
  final GoldenEggChartData data;
  final MonthlyEggData? selectedMonth;
  final List<double> daylightCurve;
  final bool isNorthernHemisphere;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color onSurfaceVariantColor;

  _YearlyEggPainter({
    required this.data,
    required this.selectedMonth,
    required this.daylightCurve,
    required this.isNorthernHemisphere,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.onSurfaceVariantColor,
  });

  // Get angle for a month (1-12), with winter at bottom
  // Northern: July (7) at top, Jan (1) at bottom
  // Southern: January (1) at top, July (7) at bottom
  double _angleForMonth(int month) {
    final anglePerMonth = 2 * math.pi / 12;
    if (isNorthernHemisphere) {
      // July (month 7) at top (-pi/2)
      return -math.pi / 2 + (month - 7) * anglePerMonth;
    } else {
      // January (month 1) at top (-pi/2)
      return -math.pi / 2 + (month - 1) * anglePerMonth;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    _drawEggBackground(canvas, center, radius);
    _drawDaylightCurve(canvas, center, radius);
    _drawMonthlyBars(canvas, center, radius);
    _drawMonthLabels(canvas, center, radius);
    _drawCenterStats(canvas, center, radius);
  }

  void _drawEggBackground(Canvas canvas, Offset center, double radius) {
    final eggRadius = radius * 0.85;

    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - eggRadius * 0.2, center.dy - eggRadius * 0.3),
        eggRadius * 1.2,
        [
          const Color(0xFFFFFBF0),
          const Color(0xFFFFF8E1),
          secondaryColor.withValues(alpha: 0.15),
        ],
        [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, eggRadius, bgPaint);

    final borderPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, eggRadius, borderPaint);
  }

  void _drawDaylightCurve(Canvas canvas, Offset center, double radius) {
    if (daylightCurve.isEmpty) return;

    final minDaylight = daylightCurve.reduce(math.min);
    final maxDaylight = daylightCurve.reduce(math.max);
    final range = maxDaylight - minDaylight;

    if (range < 0.1) return;

    final innerRadius = radius * 0.35;
    final outerRadius = radius * 0.75;

    // Use 72 points for a smooth curve (6 per month)
    const pointsPerMonth = 6;
    const totalPoints = 12 * pointsPerMonth;

    final daylightPath = Path();

    for (var i = 0; i < totalPoints; i++) {
      // Interpolate between monthly values using cosine interpolation for smoothness
      final monthFraction = i / pointsPerMonth;
      final monthIndex = monthFraction.floor() % 12;
      final nextMonthIndex = (monthIndex + 1) % 12;
      final t = monthFraction - monthIndex;

      // Cosine interpolation for smoother curve
      final smoothT = (1 - math.cos(t * math.pi)) / 2;
      final interpolatedDaylight = daylightCurve[monthIndex] +
          (daylightCurve[nextMonthIndex] - daylightCurve[monthIndex]) * smoothT;

      final normalized = (interpolatedDaylight - minDaylight) / range;
      final curveRadius = innerRadius + (outerRadius - innerRadius) * normalized;

      // Calculate angle for this point
      final month = monthFraction + 1;
      final anglePerMonth = 2 * math.pi / 12;
      final angle = isNorthernHemisphere
          ? -math.pi / 2 + (month - 7) * anglePerMonth
          : -math.pi / 2 + (month - 1) * anglePerMonth;

      final x = center.dx + curveRadius * math.cos(angle);
      final y = center.dy + curveRadius * math.sin(angle);

      if (i == 0) {
        daylightPath.moveTo(x, y);
      } else {
        daylightPath.lineTo(x, y);
      }
    }

    daylightPath.close();

    // Golden radiant fill - like sunshine
    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        outerRadius,
        [
          const Color(0xFFFFF9C4).withValues(alpha: 0.6), // Bright yellow center
          const Color(0xFFFFD54F).withValues(alpha: 0.4), // Golden
          const Color(0xFFFFB300).withValues(alpha: 0.2), // Amber edge
        ],
        [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(daylightPath, fillPaint);

    // Soft golden glow outline
    final strokePaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(daylightPath, strokePaint);
  }

  void _drawMonthlyBars(Canvas canvas, Offset center, double radius) {
    final months = data.monthlyCounts;
    if (months.isEmpty) return;

    final innerRadius = radius * 0.28;
    final maxBarRadius = radius * 0.7;
    final anglePerMonth = 2 * math.pi / 12;
    final barWidth = anglePerMonth * 0.6;

    final monthMap = <int, MonthlyEggData>{};
    for (final m in months) {
      monthMap[m.month] = m;
    }

    for (var month = 1; month <= 12; month++) {
      final monthData = monthMap[month];
      final centerAngle = _angleForMonth(month);
      final startAngle = centerAngle - barWidth / 2;

      if (monthData == null || monthData.totalCount == 0) {
        final tickPaint = Paint()
          ..color = onSurfaceVariantColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final tickStart = Offset(
          center.dx + innerRadius * math.cos(centerAngle),
          center.dy + innerRadius * math.sin(centerAngle),
        );
        final tickEnd = Offset(
          center.dx + (innerRadius + 5) * math.cos(centerAngle),
          center.dy + (innerRadius + 5) * math.sin(centerAngle),
        );
        canvas.drawLine(tickStart, tickEnd, tickPaint);
        continue;
      }

      final normalizedCount =
          data.maxDailyCount > 0 ? monthData.totalCount / data.maxDailyCount : 0.0;
      final barEndRadius = innerRadius + (maxBarRadius - innerRadius) * normalizedCount;

      final isSelected = selectedMonth?.month == month;

      final barPaint = Paint()
        ..color = isSelected
            ? secondaryColor
            : primaryColor.withValues(alpha: 0.6 + normalizedCount * 0.4)
        ..style = PaintingStyle.fill;

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

    final monthNames = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    for (var i = 0; i < 12; i++) {
      final month = i + 1;
      final angle = _angleForMonth(month);
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

    final centerPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, centerPaint);

    final borderPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, innerRadius, borderPaint);

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
        oldDelegate.isNorthernHemisphere != isNorthernHemisphere ||
        oldDelegate.primaryColor != primaryColor;
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/golden_egg_provider.dart';
import '../utils/daylight_calculator.dart';
import 'golden_egg_tooltip.dart';

/// Month abbreviations for labels
const _monthAbbrev = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

/// Yearly egg chart showing monthly production with daylight curve as the boundary.
/// The golden daylight curve forms the egg shape, with production bars reaching toward it.
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
                        latitude: latitude,
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
        // Legend - vertical stack
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              // Previous year (if data exists)
              if (widget.data.prevYearMonthlyCounts.any((m) => m.isActual))
                _LegendRow(
                  indicator: Container(
                    width: 14,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  label: '${DateTime.now().year - 1}',
                  value: '${_getPrevYearTotal()} eggs',
                  theme: theme,
                  isMuted: true,
                ),
              // Current year
              _LegendRow(
                indicator: Container(
                  width: 14,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                label: '${DateTime.now().year}',
                value: '${widget.data.totalEggs} eggs so far',
                theme: theme,
              ),
              // Forecast
              if (widget.data.allTimeDailyAverage > 0)
                _LegendRow(
                  indicator: Container(
                    width: 14,
                    height: 2,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _DashedLinePainter(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  label: 'Forecast',
                  value: '${_calculateYearlyForecast(widget.data, latitude)} this year',
                  theme: theme,
                  isMuted: true,
                ),
              // Daylight
              _LegendRow(
                indicator: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFCA28),
                      width: 1,
                    ),
                  ),
                ),
                label: 'Daylight',
                value: '${latitude >= 0 ? latitude : -latitude}°${latitude >= 0 ? 'N' : 'S'}',
                theme: theme,
                isMuted: true,
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

  int _getPrevYearTotal() {
    var total = 0;
    for (final month in widget.data.prevYearMonthlyCounts) {
      if (month.isActual) {
        total += month.totalCount;
      }
    }
    return total;
  }

  String _calculateYearlyForecast(GoldenEggChartData data, int latitude) {
    final daylightCurve = DaylightCalculator.getMonthlyDaylightCurve(latitude);
    final daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    final now = DateTime.now();
    final currentMonth = now.month;

    // Current active bird count — this is what we project forward with
    final currentFlockSize = data.activeFlockSize;
    if (currentFlockSize == 0) {
      // No birds, can't calculate meaningful forecast
      return '0/yr';
    }

    // Collect months with reliable data (10+ days recorded)
    // Map of 0-indexed month -> per-bird daily rate
    final actualRates = <int, double>{};
    for (final month in data.monthlyCounts) {
      if (month.isActual &&
          month.daysRecorded >= 10 &&
          month.totalCount > 0 &&
          month.avgFlockSize > 0) {
        // bird-days = avg flock size that month × days recorded
        final birdDays = month.avgFlockSize * month.daysRecorded;
        actualRates[month.month - 1] = month.totalCount / birdDays;
      }
    }

    if (actualRates.isEmpty) {
      // No usable monthly data — simple fallback using all-time average
      // Assume current flock size for projection
      final yearlyEstimate =
          (data.allTimeDailyAverage * 365).round();
      return '$yearlyEstimate/yr';
    }

    var yearlyTotal = 0.0;

    for (var i = 0; i < 12; i++) {
      final month1Indexed = i + 1;
      final monthData = data.monthlyCounts
          .where((m) => m.month == month1Indexed)
          .firstOrNull;

      if (_isMonthInPast(month1Indexed, currentMonth)) {
        // Past month — use actual total
        yearlyTotal += monthData?.totalCount ?? 0;
      } else if (month1Indexed == currentMonth && monthData != null) {
        // Current month — actual eggs so far + forecast for remaining days
        final daysRemaining = daysPerMonth[i] - monthData.daysRecorded;
        if (actualRates.containsKey(i) && daysRemaining > 0) {
          // Use this month's actual per-bird rate for remaining days
          yearlyTotal += monthData.totalCount +
              (actualRates[i]! * currentFlockSize * daysRemaining);
        } else {
          // Use daylight-twin for remaining days
          final forecastRate =
              _getForecastRate(i, actualRates, daylightCurve);
          yearlyTotal += monthData.totalCount +
              (forecastRate * currentFlockSize * daysRemaining);
        }
      } else {
        // Future month — forecast using daylight-twin matching
        final forecastRate =
            _getForecastRate(i, actualRates, daylightCurve);
        yearlyTotal += forecastRate * currentFlockSize * daysPerMonth[i];
      }
    }

    return '${yearlyTotal.round()}/yr';
  }

  /// Check if a month is in the past relative to the current month.
  bool _isMonthInPast(int month, int currentMonth) {
    return month < currentMonth;
  }

  /// Get forecasted per-bird rate for a month using daylight-twin matching.
  double _getForecastRate(
    int monthIndex,
    Map<int, double> actualRates,
    List<double> daylightCurve,
  ) {
    if (actualRates.isEmpty) return 0;

    // Find the recorded month with the most similar daylight
    final targetDL = daylightCurve[monthIndex];
    int? bestMonth;
    var bestDiff = double.infinity;

    for (final m in actualRates.keys) {
      final diff = (daylightCurve[m] - targetDL).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestMonth = m;
      }
    }

    if (bestMonth != null) {
      final matchedRate = actualRates[bestMonth]!;
      final matchedDL = daylightCurve[bestMonth];
      // Dampened ratio — 0.6 exponent prevents overcorrection
      final ratio = math.pow(targetDL / matchedDL, 0.6);
      return matchedRate * ratio;
    }

    return 0;
  }

  void _handleTap(TapDownDetails details, double size, bool isNorthern) {
    final center = Offset(size / 2, size / 2);
    final tapPosition = details.localPosition;

    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final innerRadius = size * 0.10;
    final outerRadius = size * 0.45; // Tap area covers production zone
    if (distance < innerRadius || distance > outerRadius) {
      setState(() => _selectedMonth = null);
      return;
    }

    // Calculate angle from top, clockwise
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    final anglePerMonth = 2 * math.pi / 12;

    // Adjust for hemisphere rotation
    final rotationOffset = isNorthern ? 6 : 0;
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
  final int latitude;
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
    required this.latitude,
    required this.isNorthernHemisphere,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.onSurfaceVariantColor,
  });

  // Get angle for a month (1-12), with winter at bottom
  double _angleForMonth(double month) {
    final anglePerMonth = 2 * math.pi / 12;
    if (isNorthernHemisphere) {
      return -math.pi / 2 + (month - 7) * anglePerMonth;
    } else {
      return -math.pi / 2 + (month - 1) * anglePerMonth;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // The daylight curve is the egg boundary
    _drawDaylightEgg(canvas, center, radius);
    // Grid lines on top of egg
    _drawGridLines(canvas, center, radius);
    _drawProductionLine(canvas, center, radius);
    _drawMonthLabels(canvas, center, radius);
    _drawCenterPoint(canvas, center, radius);
  }

  void _drawGridLines(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = onSurfaceVariantColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Grid extends full width of chart
    final chartInner = radius * 0.12;
    final chartOuter = radius * 0.94;

    // Concentric circles (5 rings) - extend to full chart width
    const ringCount = 5;
    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final maxCount = data.maxDailyCount;

    // Round max to a nice number for grid labels
    final roundedMax = _roundToNice(maxCount);
    final step = roundedMax ~/ ringCount;

    for (var i = 1; i <= ringCount; i++) {
      // Grid circles extend to full chart
      final ringRadius = chartInner + (chartOuter - chartInner) * (i / ringCount);
      canvas.drawCircle(center, ringRadius, gridPaint);

      // Value labels on inner circles only (skip outermost - overlaps month label)
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

    // Month spokes (12 lines) - extend to full chart width
    for (var month = 1; month <= 12; month++) {
      final angle = _angleForMonth(month.toDouble());
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

  /// Round a number to a nice value for grid labels (10, 20, 50, 100, etc.)
  int _roundToNice(int value) {
    if (value <= 0) return 0;
    if (value <= 10) return 10;
    if (value <= 25) return 25;
    if (value <= 50) return 50;
    if (value <= 100) return 100;
    if (value <= 250) return 250;
    if (value <= 500) return 500;
    if (value <= 1000) return 1000;
    // Round up to nearest 500
    return ((value + 499) ~/ 500) * 500;
  }

  /// Get the egg's minimum radius (winter) for this latitude
  double _getEggMinRadius(double radius) {
    final outerBoundary = radius * 0.94;

    // Calculate min/max daylight for this latitude
    double minDaylight = 24;
    double maxDaylight = 0;
    for (var day = 1; day <= 365; day++) {
      final hours = DaylightCalculator.calculateDaylightHours(day, latitude);
      if (hours < minDaylight) minDaylight = hours;
      if (hours > maxDaylight) maxDaylight = hours;
    }

    // 0-max scale: min radius = outerBoundary × (minDaylight / maxDaylight)
    return outerBoundary * (minDaylight / maxDaylight);
  }

  void _drawDaylightEgg(Canvas canvas, Offset center, double radius) {
    // Egg always touches outer boundary at max daylight
    final outerBoundary = radius * 0.94;

    // Use actual solar formula for 365 points (one per day) - true smooth curve
    const totalPoints = 365;

    final daylightValues = <double>[];
    for (var day = 1; day <= 365; day++) {
      final hours = DaylightCalculator.calculateDaylightHours(day, latitude);
      daylightValues.add(hours);
    }

    final minDaylight = daylightValues.reduce(math.min);
    final maxDaylight = daylightValues.reduce(math.max);

    // Check if near equator (very small variance)
    if (maxDaylight - minDaylight < 0.5) {
      // Near equator - draw a circle at outer boundary
      _drawGoldenCircle(canvas, center, outerBoundary, outerBoundary);
      return;
    }

    final daylightPath = Path();

    for (var i = 0; i < totalPoints; i++) {
      final daylight = daylightValues[i];

      // 0-max scale: radius directly proportional to daylight hours
      final curveRadius = outerBoundary * (daylight / maxDaylight);

      // Convert day of year to month fraction (1-13)
      final dayOfYear = i + 1;
      final monthFraction = 1 + (dayOfYear - 1) * 12 / 365;
      final angle = _angleForMonth(monthFraction);

      final x = center.dx + curveRadius * math.cos(angle);
      final y = center.dy + curveRadius * math.sin(angle);

      if (i == 0) {
        daylightPath.moveTo(x, y);
      } else {
        daylightPath.lineTo(x, y);
      }
    }

    daylightPath.close();

    // Golden radiant fill - the egg shape with softer amber edge
    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.1, center.dy - radius * 0.15),
        outerBoundary * 1.3,
        [
          const Color(0xFFFFFDE7), // Bright warm white center
          const Color(0xFFFFF8E1), // Very light cream
          const Color(0xFFFFECB3), // Light golden
          const Color(0xFFFFE082), // Soft golden
          const Color(0xFFFFD54F), // Warm amber (softer)
        ],
        [0.0, 0.25, 0.5, 0.75, 1.0],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(daylightPath, fillPaint);

    // Soft outer glow (instead of hard stroke)
    final outerGlowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(daylightPath, outerGlowPaint);

    // Subtle golden edge
    final strokePaint = Paint()
      ..color = const Color(0xFFFFCA28).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(daylightPath, strokePaint);

    // Add subtle inner glow
    final innerGlowPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(daylightPath, innerGlowPaint);
  }

  void _drawGoldenCircle(Canvas canvas, Offset center, double radius, double outerBoundary) {
    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        outerBoundary,
        [
          const Color(0xFFFFFDE7),
          const Color(0xFFFFE082),
        ],
        [0.0, 1.0],
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, strokePaint);
  }

  void _drawProductionLine(Canvas canvas, Offset center, double radius) {
    final months = data.monthlyCounts;
    if (months.isEmpty) return;

    // Production fits inside the egg's minimum boundary (winter)
    final innerRadius = radius * 0.12;
    final eggMinRadius = _getEggMinRadius(radius);

    final monthMap = <int, MonthlyEggData>{};
    for (final m in months) {
      monthMap[m.month] = m;
    }

    // Build previous year month map
    final prevYearMap = <int, MonthlyEggData>{};
    for (final m in data.prevYearMonthlyCounts) {
      prevYearMap[m.month] = m;
    }

    // Calculate max for normalization across both years
    var maxMonthlyTotal = 0;
    for (final m in months) {
      if (m.totalCount > maxMonthlyTotal) maxMonthlyTotal = m.totalCount;
    }
    for (final m in data.prevYearMonthlyCounts) {
      if (m.totalCount > maxMonthlyTotal) maxMonthlyTotal = m.totalCount;
    }

    // Draw previous year ghost layer first (behind current year)
    if (data.prevYearMonthlyCounts.any((m) => m.isActual)) {
      _drawYearCurve(
        canvas,
        center,
        prevYearMap,
        innerRadius,
        eggMinRadius,
        maxMonthlyTotal,
        isGhostLayer: true,
      );
    }

    // Draw current year
    _drawYearCurve(
      canvas,
      center,
      monthMap,
      innerRadius,
      eggMinRadius,
      maxMonthlyTotal,
      isGhostLayer: false,
    );
  }

  /// Draw a year's production curve with smooth Catmull-Rom spline
  void _drawYearCurve(
    Canvas canvas,
    Offset center,
    Map<int, MonthlyEggData> monthMap,
    double innerRadius,
    double productionOuter,
    int maxMonthlyTotal, {
    required bool isGhostLayer,
  }) {
    if (maxMonthlyTotal == 0) return;

    final currentMonth = DateTime.now().month;

    // Collect points for months with actual data
    // For current year, exclude current month from the curve (partial data)
    final List<_ProductionPoint> actualPoints = [];

    for (var month = 1; month <= 12; month++) {
      final monthData = monthMap[month];
      if (monthData == null || !monthData.isActual || monthData.totalCount == 0) {
        continue;
      }

      // Skip current month for curve (it's partial) - only for current year
      if (!isGhostLayer && month == currentMonth) {
        continue;
      }

      final centerAngle = _angleForMonth(month.toDouble());
      final normalizedCount = monthData.totalCount / maxMonthlyTotal;
      final lineRadius = innerRadius + (productionOuter - innerRadius) * normalizedCount;

      actualPoints.add(_ProductionPoint(
        offset: Offset(
          center.dx + lineRadius * math.cos(centerAngle),
          center.dy + lineRadius * math.sin(centerAngle),
        ),
        isActual: true,
        month: month,
      ));
    }

    if (actualPoints.isEmpty) return;

    // Build smooth Catmull-Rom spline path
    final path = _buildSmoothPath(actualPoints, closed: actualPoints.length >= 6);

    if (isGhostLayer) {
      // Ghost layer: thin solid, low opacity
      final ghostPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, ghostPaint);
    } else {
      // Current year: solid curve
      final curvePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, curvePaint);

      // Draw dots for current year
      _drawProductionDots(canvas, center, monthMap, innerRadius, productionOuter, maxMonthlyTotal);
    }
  }

  /// Build a smooth Catmull-Rom spline path through the given points
  Path _buildSmoothPath(List<_ProductionPoint> points, {bool closed = false}) {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points[0].offset, radius: 2));
      return path;
    }
    if (points.length == 2) {
      path.moveTo(points[0].offset.dx, points[0].offset.dy);
      path.lineTo(points[1].offset.dx, points[1].offset.dy);
      return path;
    }

    // Catmull-Rom spline with tension 0.5
    const tension = 0.5;

    path.moveTo(points[0].offset.dx, points[0].offset.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1].offset : points[i].offset;
      final p1 = points[i].offset;
      final p2 = points[i + 1].offset;
      final p3 = i + 2 < points.length ? points[i + 2].offset : p2;

      // Calculate control points
      final cp1x = p1.dx + (p2.dx - p0.dx) * tension / 3;
      final cp1y = p1.dy + (p2.dy - p0.dy) * tension / 3;
      final cp2x = p2.dx - (p3.dx - p1.dx) * tension / 3;
      final cp2y = p2.dy - (p3.dy - p1.dy) * tension / 3;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // Close the path if we have enough points and it's a full year
    if (closed && points.length >= 6) {
      final p0 = points[points.length - 2].offset;
      final p1 = points[points.length - 1].offset;
      final p2 = points[0].offset;
      final p3 = points[1].offset;

      final cp1x = p1.dx + (p2.dx - p0.dx) * tension / 3;
      final cp1y = p1.dy + (p2.dy - p0.dy) * tension / 3;
      final cp2x = p2.dx - (p3.dx - p1.dx) * tension / 3;
      final cp2y = p2.dy - (p3.dy - p1.dy) * tension / 3;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    return path;
  }

  /// Draw production dots for current year data
  void _drawProductionDots(
    Canvas canvas,
    Offset center,
    Map<int, MonthlyEggData> monthMap,
    double innerRadius,
    double productionOuter,
    int maxMonthlyTotal,
  ) {
    final currentMonth = DateTime.now().month;

    for (var month = 1; month <= 12; month++) {
      final monthData = monthMap[month];
      if (monthData == null || !monthData.isActual || monthData.totalCount == 0) {
        continue;
      }

      final isSelected = selectedMonth?.month == month;
      final isCurrentMonth = month == currentMonth;

      final centerAngle = _angleForMonth(month.toDouble());
      final normalizedCount = monthData.totalCount / maxMonthlyTotal;
      final dotRadius = innerRadius + (productionOuter - innerRadius) * normalizedCount;
      final dotOffset = Offset(
        center.dx + dotRadius * math.cos(centerAngle),
        center.dy + dotRadius * math.sin(centerAngle),
      );

      // Smaller dots (60% of original)
      final dotSize = isSelected ? 4.8 : 3.6;

      if (isCurrentMonth) {
        // Hollow dot for current month (in progress)
        final hollowPaint = Paint()
          ..color = isSelected ? secondaryColor : primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(dotOffset, dotSize, hollowPaint);
      } else {
        // Solid filled dot for past months (complete)
        final dotPaint = Paint()
          ..color = isSelected ? secondaryColor : primaryColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(dotOffset, dotSize, dotPaint);
      }
    }
  }

  void _drawMonthLabels(Canvas canvas, Offset center, double radius) {
    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    // Fixed circle for labels, just outside maximum egg extent
    final labelRadius = radius * 0.96;

    // Build month map for counts
    final monthMap = <int, MonthlyEggData>{};
    for (final m in data.monthlyCounts) {
      monthMap[m.month] = m;
    }

    for (var i = 0; i < 12; i++) {
      final month = i + 1;
      final angle = _angleForMonth(month.toDouble());
      final isSelected = selectedMonth?.month == month;
      final monthData = monthMap[month];
      final count = monthData?.totalCount ?? 0;

      final labelX = center.dx + labelRadius * math.cos(angle);
      final labelY = center.dy + labelRadius * math.sin(angle);

      final baseColor = isSelected ? secondaryColor : onSurfaceVariantColor;
      final fontSize = isSelected ? 11.0 : 9.0;

      // Month letter bold, count plain
      labelPainter.text = TextSpan(
        children: [
          TextSpan(
            text: _monthAbbrev[i],
            style: TextStyle(
              color: baseColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (count > 0)
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
    // Simple center reference point - subtle ring
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

  @override
  bool shouldRepaint(_YearlyEggPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedMonth != selectedMonth ||
        oldDelegate.latitude != latitude ||
        oldDelegate.isNorthernHemisphere != isNorthernHemisphere ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Helper class for production line points
class _ProductionPoint {
  final Offset offset;
  final bool isActual;
  final int month;

  _ProductionPoint({
    required this.offset,
    required this.isActual,
    required this.month,
  });
}

/// Legend row widget for consistent formatting
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

/// Dashed line painter for forecast indicator
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    var startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => color != oldDelegate.color;
}

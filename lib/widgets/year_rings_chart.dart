import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/year_rings.dart';

/// Ring chart for a year of egg logs (#1).
///
/// Each ring is a year or a hen; each block a week, running clockwise from
/// January at the top over 300°. The gap at the top left holds the ring
/// labels. Colour is lay rate (or eggs per day without a headcount); in years
/// mode a ring's thickness follows how many laying-age hens there were. A
/// thin band outside the rings shows daylight through the year.
class YearRingsChart extends StatelessWidget {
  final YearRingsData data;

  /// Highlighted ring; the others are dimmed. Null highlights none.
  final int? selected;
  final ValueChanged<int>? onRingTap;

  /// Ring labels and month letters. Off for small previews.
  final bool showLabels;
  final String? centerValue;
  final String? centerLabel;

  const YearRingsChart({
    super.key,
    required this.data,
    this.selected,
    this.onRingTap,
    this.showLabels = true,
    this.centerValue,
    this.centerLabel,
  });

  static const sweepDegrees = 300.0;
  static const todayColor = Color(0xFFE0603A);
  static const daylightColor = Color(0xFFE0A63A);

  /// Colour for a block of the given intensity (0–1), shared with the legend.
  static Color blockColor(ColorScheme scheme, double intensity) {
    final low = Color.lerp(scheme.surfaceContainerHighest, scheme.primary, 0.08)!;
    return Color.lerp(low, scheme.primary, math.pow(intensity, 0.9).toDouble())!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final geometry = _Geometry(size, data.rings.length);
        return Semantics(
          label: _describe(data),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onRingTap == null
                ? null
                : (details) {
                    final i = geometry.ringAt(details.localPosition);
                    if (i != null) onRingTap!(i);
                  },
            child: CustomPaint(
              size: Size.square(size),
              painter: _YearRingsPainter(
                data: data,
                geometry: geometry,
                selected: selected,
                showLabels: showLabels,
                centerValue: centerValue,
                centerLabel: centerLabel,
                scheme: theme.colorScheme,
                textStyle: theme.textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _describe(YearRingsData data) {
    if (data.isEmpty) return 'Year rings: no eggs logged yet.';
    final kind = data.mode == RingMode.years ? 'one ring per year' : 'one ring per hen';
    final rings = data.rings
        .map((r) => '${r.label}: ${r.eggs} eggs'
            '${r.layRate != null ? ', ${(r.layRate! * 100).round()}% lay rate' : ''}')
        .join('; ');
    return 'Year rings, $kind, one block per week from January. $rings.';
  }
}

class _Geometry {
  final double size;
  final int count;
  _Geometry(this.size, this.count);

  Offset get center => Offset(size / 2, size / 2);
  double get radius => size / 2;
  double get inner => radius * 0.22;
  double get outer => radius * 0.80;
  double get step => count == 0 ? 0 : (outer - inner) / count;
  double ringCenter(int i) => inner + step * (i + 0.5);
  double get maxThickness => math.min(step * 0.82, radius * 0.13);
  double get bandInner => radius * 0.835;
  double get bandOuter => radius * 0.865;
  double get monthRadius => radius * 0.935;

  /// Ring under [p], including taps on its label in the gap.
  int? ringAt(Offset p) {
    if (count == 0) return null;
    final d = (p - center).distance;
    if (d < inner || d > outer) return null;
    return ((d - inner) / step).floor().clamp(0, count - 1);
  }
}

/// Canvas angle (radians) for [degrees] clockwise from the top.
double _angle(double degrees) => (degrees - 90) * math.pi / 180;

class _YearRingsPainter extends CustomPainter {
  final YearRingsData data;
  final _Geometry geometry;
  final int? selected;
  final bool showLabels;
  final String? centerValue;
  final String? centerLabel;
  final ColorScheme scheme;
  final TextStyle textStyle;

  _YearRingsPainter({
    required this.data,
    required this.geometry,
    required this.selected,
    required this.showLabels,
    required this.centerValue,
    required this.centerLabel,
    required this.scheme,
    required this.textStyle,
  });

  static const _blockGapDegrees = 0.4;

  void _sector(Canvas canvas, Paint paint, double a0, double a1, double r0, double r1) {
    final c = geometry.center;
    final start = _angle(a0);
    final sweep = (a1 - a0) * math.pi / 180;
    final path = Path()
      ..arcTo(Rect.fromCircle(center: c, radius: r1), start, sweep, true)
      ..arcTo(Rect.fromCircle(center: c, radius: r0), start + sweep, -sweep, false)
      ..close();
    canvas.drawPath(path, paint);
  }

  double _weekDegrees(int w) => w * YearRingsChart.sweepDegrees / kWeeksPerRing;

  @override
  void paint(Canvas canvas, Size size) {
    _paintDaylight(canvas);
    for (var i = 0; i < data.rings.length; i++) {
      _paintRing(canvas, i);
    }
    _paintToday(canvas);
    if (showLabels) {
      _paintRingLabels(canvas);
      _paintMonths(canvas);
    }
    _paintCenter(canvas);
  }

  void _paintDaylight(Canvas canvas) {
    final hours = data.weeklyDaylight;
    if (hours.isEmpty) return;
    final lo = hours.reduce(math.min), hi = hours.reduce(math.max);
    final base = scheme.surfaceContainerHighest;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var w = 0; w < hours.length; w++) {
      final t = hi > lo ? (hours[w] - lo) / (hi - lo) : 0.5;
      paint.color = Color.lerp(base, YearRingsChart.daylightColor, 0.15 + 0.75 * t)!;
      _sector(canvas, paint, _weekDegrees(w), _weekDegrees(w + 1) + 0.05,
          geometry.bandInner, geometry.bandOuter);
    }
  }

  void _paintRing(Canvas canvas, int i) {
    final ring = data.rings[i];
    final dim = selected != null && selected != i;
    final rc = geometry.ringCenter(i);
    final fill = Paint()..style = PaintingStyle.fill;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = scheme.onSurface.withValues(alpha: dim ? 0.08 : 0.2);

    for (final b in ring.blocks) {
      if (b.state == RingBlockState.empty || b.state == RingBlockState.unknown) continue;
      final thickness = _thickness(b.hens);
      final r0 = rc - thickness / 2, r1 = rc + thickness / 2;
      final a0 = _weekDegrees(b.week) + _blockGapDegrees;
      final a1 = _weekDegrees(b.week + 1) - _blockGapDegrees;
      if (b.state == RingBlockState.future) {
        _sector(canvas, outline, a0, a1, r0, r1);
        continue;
      }
      final color = YearRingsChart.blockColor(scheme, b.intensity);
      fill.color = dim ? color.withValues(alpha: 0.35) : color;
      _sector(canvas, fill, a0, a1, r0, r1);
    }
  }

  double _thickness(double hens) {
    final max = geometry.maxThickness;
    if (data.mode == RingMode.hens || data.maxHens <= 0) return max * 0.85;
    return max * (0.3 + 0.7 * (hens / data.maxHens).clamp(0.0, 1.0));
  }

  void _paintToday(Canvas canvas) {
    final today = data.today;
    if (today.year != data.year) return;
    final a = _angle((dayOfYear(today) - 1) / 365 * YearRingsChart.sweepDegrees);
    final c = geometry.center;
    final dir = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(
      c + dir * (geometry.inner - 4),
      c + dir * geometry.bandOuter,
      Paint()
        ..color = YearRingsChart.todayColor
        ..strokeWidth = 1.6,
    );
  }

  void _paintRingLabels(Canvas canvas) {
    final fontSize = (geometry.step * 0.62).clamp(7.0, 12.0);
    if (geometry.step < 9) return; // too many rings for labels to fit
    final c = geometry.center;
    for (var i = 0; i < data.rings.length; i++) {
      final isSelected = selected == i;
      final tp = TextPainter(
        text: TextSpan(
          text: data.rings[i].label,
          style: textStyle.copyWith(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? scheme.primary : scheme.onSurface,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: geometry.radius * 0.55);
      tp.paint(
        canvas,
        Offset(c.dx - 5 - tp.width, c.dy - geometry.ringCenter(i) - tp.height / 2),
      );
    }
  }

  void _paintMonths(Canvas canvas) {
    const letters = 'JFMAMJJASOND';
    final fontSize = (geometry.radius * 0.06).clamp(8.0, 12.0);
    final c = geometry.center;
    for (var m = 0; m < 12; m++) {
      final doy = dayOfYear(DateTime(data.year, m + 1, 15));
      final a = _angle((doy - 1) / 365 * YearRingsChart.sweepDegrees);
      final p = c + Offset(math.cos(a), math.sin(a)) * geometry.monthRadius;
      final tp = TextPainter(
        text: TextSpan(
          text: letters[m],
          style: textStyle.copyWith(fontSize: fontSize, color: scheme.onSurfaceVariant),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _paintCenter(Canvas canvas) {
    if (centerValue == null) return;
    final c = geometry.center;
    final maxWidth = geometry.inner * 1.9;
    final value = TextPainter(
      text: TextSpan(
        text: centerValue,
        style: textStyle.copyWith(
          fontSize: (geometry.inner * 0.42).clamp(10.0, 20.0),
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    final label = centerLabel == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: centerLabel,
              style: textStyle.copyWith(
                fontSize: (geometry.inner * 0.22).clamp(7.0, 11.0),
                color: scheme.onSurfaceVariant,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: maxWidth));
    final total = value.height + (label?.height ?? 0);
    value.paint(canvas, Offset(c.dx - value.width / 2, c.dy - total / 2));
    label?.paint(canvas, Offset(c.dx - label.width / 2, c.dy - total / 2 + value.height));
  }

  @override
  bool shouldRepaint(_YearRingsPainter old) =>
      old.data != data ||
      old.selected != selected ||
      old.showLabels != showLabels ||
      old.centerValue != centerValue ||
      old.scheme != scheme ||
      old.geometry.size != geometry.size;
}

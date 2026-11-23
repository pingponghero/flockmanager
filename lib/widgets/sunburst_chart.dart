import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/year_rings.dart';
import 'year_rings_chart.dart';

/// The sunburst (#1): one ray per day of the year on a night-sky disc.
///
/// Gold rays are daylight, measured from the centre, so together they draw
/// the year's egg shape: longest day at the top. Cream rays are the eggs
/// laid that day; days still ahead show faint expected rays. A coral hand
/// marks [selectedDay].
class SunburstChart extends StatelessWidget {
  final List<DayPoint> days;

  /// Day of the year (1-based) under the hand.
  final int selectedDay;
  final bool southernHemisphere;
  final String? centerValue;
  final String? centerLabel;

  const SunburstChart({
    super.key,
    required this.days,
    required this.selectedDay,
    this.southernHemisphere = false,
    this.centerValue,
    this.centerLabel,
  });

  static const night = Color(0xFF221C16);
  static const nightText = Color(0xFFF6EBD3);
  static const nightMuted = Color(0xFFCDBFA6);
  static const sun = Color(0xFFE9C46A);
  static const egg = Color(0xFFFFF1CF);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest.shortestSide;
      return CustomPaint(
        size: Size.square(size),
        painter: _SunburstPainter(
          days: days,
          selectedDay: selectedDay,
          anchorDay: southernHemisphere ? 355 : 172,
          centerValue: centerValue,
          centerLabel: centerLabel,
          textStyle: textStyle,
        ),
      );
    });
  }
}

class _SunburstPainter extends CustomPainter {
  final List<DayPoint> days;
  final int selectedDay;
  final int anchorDay;
  final String? centerValue;
  final String? centerLabel;
  final TextStyle textStyle;

  _SunburstPainter({
    required this.days,
    required this.selectedDay,
    required this.anchorDay,
    required this.centerValue,
    required this.centerLabel,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rIn = radius * 0.16;
    final rMax = radius * 0.80;
    final n = days.length;

    final maxLight = days.map((d) => d.daylight).reduce(math.max);
    final maxEggs = days
        .map((d) => d.state == RingBlockState.logged ? d.eggs.toDouble() : (d.expected ?? 0))
        .fold<double>(1, math.max);
    // The busiest day reaches just inside the shortest day's daylight, so
    // the gold egg always shows around the eggs.
    final minLight = days.map((d) => d.daylight).reduce(math.min);
    final eggScale = (rMax * minLight / maxLight * 0.92 - rIn) / maxEggs;
    final width = math.max(1.0, 2 * math.pi * rMax / n * 0.62);

    Offset dir(int doy) {
      final a = (doy - anchorDay) / n * 2 * math.pi - math.pi / 2;
      return Offset(math.cos(a), math.sin(a));
    }

    // Daylight as one filled egg (drawn as rays it moirés where they meet):
    // brighter for days gone, dimmer for days ahead.
    Offset edge(DayPoint d) => c + dir(d.dayOfYear) * (rMax * d.daylight / maxLight);
    final gone = days.where((d) => d.state != RingBlockState.future).toList();
    final coming = days.where((d) => d.state == RingBlockState.future).toList();
    final past = Path()..moveTo(c.dx, c.dy);
    for (final d in gone) {
      final p = edge(d);
      past.lineTo(p.dx, p.dy);
    }
    if (coming.isEmpty && gone.isNotEmpty) {
      final p = edge(gone.first);
      past.lineTo(p.dx, p.dy);
    }
    final ahead = Path()..moveTo(c.dx, c.dy);
    if (gone.isNotEmpty && coming.isNotEmpty) {
      final p = edge(gone.last);
      ahead.lineTo(p.dx, p.dy);
    }
    for (final d in coming) {
      final p = edge(d);
      ahead.lineTo(p.dx, p.dy);
    }
    final anyAhead = coming.isNotEmpty;
    past.close();
    ahead.close();
    canvas.drawPath(past, Paint()..color = SunburstChart.sun.withValues(alpha: 0.42));
    if (anyAhead) {
      canvas.drawPath(ahead, Paint()..color = SunburstChart.sun.withValues(alpha: 0.16));
    }

    final eggs = Paint()..strokeWidth = math.max(0.8, width * 0.55);
    for (final d in days) {
      final u = dir(d.dayOfYear);
      final ahead = d.state == RingBlockState.future;

      final count = d.state == RingBlockState.logged ? d.eggs.toDouble() : (ahead ? d.expected : null);
      if (count != null && count > 0.05) {
        eggs.color = SunburstChart.egg.withValues(alpha: ahead ? 0.32 : 1);
        canvas.drawLine(c + u * rIn, c + u * (rIn + count * eggScale), eggs);
      }
    }

    // Hand.
    final hand = dir(selectedDay);
    final tip = c + hand * (radius * 0.86);
    final handPaint = Paint()
      ..color = YearRingsChart.todayColor
      ..strokeWidth = 1.6;
    canvas.drawLine(c, tip, handPaint);
    canvas.drawCircle(tip, math.max(3, radius * 0.022), handPaint);

    // Month labels at mid-month.
    final year = days.first.date.year;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStyle = textStyle.copyWith(
      fontSize: (radius * 0.055).clamp(8.0, 12.0),
      color: SunburstChart.nightMuted,
    );
    for (var m = 0; m < 12; m++) {
      final p = c + dir(dayOfYear(DateTime(year, m + 1, 15))) * (radius * 0.94);
      _text(canvas, months[m], p, monthStyle);
    }

    // Centre.
    canvas.drawCircle(c, rIn - 1, Paint()..color = SunburstChart.night);
    if (centerValue != null) {
      final valueStyle = textStyle.copyWith(
        fontSize: (rIn * 0.42).clamp(10.0, 20.0),
        fontWeight: FontWeight.w700,
        color: SunburstChart.nightText,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      final labelStyle = textStyle.copyWith(
        fontSize: (rIn * 0.2).clamp(7.0, 11.0),
        color: SunburstChart.nightMuted,
      );
      _text(canvas, centerValue!, c - Offset(0, rIn * 0.14), valueStyle);
      if (centerLabel != null) _text(canvas, centerLabel!, c + Offset(0, rIn * 0.34), labelStyle);
    }
  }

  void _text(Canvas canvas, String s, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_SunburstPainter old) =>
      old.days != days ||
      old.selectedDay != selectedDay ||
      old.anchorDay != anchorDay ||
      old.centerValue != centerValue;
}

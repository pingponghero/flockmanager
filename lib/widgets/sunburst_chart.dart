import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../utils/year_rings.dart';
import 'chart_center_text.dart';

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
    this.palette = SunburstPalette.eggInspired,
  });

  /// Colours for the chart and the panel around it.
  final SunburstPalette palette;


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
          palette: palette,
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
    required this.palette,
  });

  final SunburstPalette palette;

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
    Paint daylight(double alpha) => Paint()
      ..shader = RadialGradient(
        colors: [
          palette.daylightInner.withValues(alpha: alpha),
          palette.daylightOuter.withValues(alpha: alpha),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: rMax));
    canvas.drawPath(past, daylight(palette.daylightAlpha));
    if (anyAhead) {
      canvas.drawPath(ahead, daylight(palette.aheadAlpha));
    }

    final eggs = Paint()..strokeWidth = math.max(0.8, width * 0.55);
    for (final d in days) {
      final u = dir(d.dayOfYear);
      final ahead = d.state == RingBlockState.future;

      final count = d.state == RingBlockState.logged ? d.eggs.toDouble() : (ahead ? d.expected : null);
      if (count != null && count > 0.05) {
        eggs.color = palette.egg.withValues(alpha: ahead ? 0.32 : 1);
        canvas.drawLine(c + u * rIn, c + u * (rIn + count * eggScale), eggs);
      }
    }

    // Hand.
    final hand = dir(selectedDay);
    final tip = c + hand * (radius * 0.86);
    final handPaint = Paint()
      ..color = palette.hand
      ..strokeWidth = 1.6;
    canvas.drawLine(c, tip, handPaint);
    canvas.drawCircle(tip, math.max(3, radius * 0.022), handPaint);

    // Month labels at mid-month.
    final year = days.first.date.year;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStyle = textStyle.copyWith(
      fontSize: (radius * 0.055).clamp(8.0, 12.0),
      color: palette.muted,
    );
    for (var m = 0; m < 12; m++) {
      final p = c + dir(dayOfYear(DateTime(year, m + 1, 15))) * (radius * 0.94);
      _text(canvas, months[m], p, monthStyle);
    }

    // Centre.
    canvas.drawCircle(c, rIn - 1, Paint()..color = palette.background);
    if (centerValue != null) {
      final valueStyle = textStyle.copyWith(
        fontSize: (rIn * 0.42).clamp(10.0, 20.0),
        fontWeight: FontWeight.w700,
        color: palette.text,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      final labelStyle = textStyle.copyWith(
        fontSize: (rIn * 0.2).clamp(7.0, 11.0),
        color: palette.muted,
      );
      // Shrinks to fit the dark disc, so long totals don't spill onto the rays.
      final value = fitCenterText(centerValue!, valueStyle, maxWidth: rIn * 1.7);
      value.paint(canvas, c - Offset(0, rIn * 0.14) - Offset(value.width / 2, value.height / 2));
      if (centerLabel != null) {
        final label = fitCenterText(centerLabel!, labelStyle, maxWidth: rIn * 1.7, minFontSize: 6);
        label.paint(canvas, c + Offset(0, rIn * 0.34) - Offset(label.width / 2, label.height / 2));
      }
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
      old.centerValue != centerValue ||
      old.palette != palette;
}

/// Colours for the sunburst (#1). Daylight is painted as a radial gradient
/// from [daylightInner] at the centre to [daylightOuter] at the rim.
class SunburstPalette {
  final String name;
  final Color background;
  final Color daylightInner;
  final Color daylightOuter;

  /// Opacity of daylight for days gone, and for days ahead.
  final double daylightAlpha;
  final double aheadAlpha;
  final Color egg;
  final Color hand;
  final Color text;
  final Color muted;

  const SunburstPalette({
    required this.name,
    required this.background,
    required this.daylightInner,
    required this.daylightOuter,
    this.daylightAlpha = 0.42,
    this.aheadAlpha = 0.16,
    required this.egg,
    this.hand = const Color(0xFFE0603A),
    required this.text,
    required this.muted,
  });

  /// Barn Red: a deep barn-red night, daylight glowing to the palette's gold.
  static const barnRed = SunburstPalette(
    name: 'Barn Red',
    background: Color(0xFF3A1A1B),
    daylightInner: Color(0xFFFFE9A8),
    daylightOuter: Color(0xFFE8A83E),
    daylightAlpha: 0.9,
    aheadAlpha: 0.3,
    egg: Color(0xFFFFF8EC),
    hand: Color(0xFFFF7F6A),
    text: Color(0xFFFFF3E6),
    muted: Color(0xFFE6C9C4),
  );

  /// Sage & Terracotta: a deep sage night, daylight glowing to terracotta.
  static const sage = SunburstPalette(
    name: 'Sage & Terracotta',
    background: Color(0xFF1E2A22),
    daylightInner: Color(0xFFFFEBB8),
    daylightOuter: Color(0xFFE08A5F),
    daylightAlpha: 0.9,
    aheadAlpha: 0.3,
    egg: Color(0xFFFFFFFF),
    hand: Color(0xFFFFD166),
    text: Color(0xFFF3F7F1),
    muted: Color(0xFFC7D6C9),
  );

  /// Egg-Inspired: a deep teal night, daylight glowing to yolk yellow.
  static const eggInspired = SunburstPalette(
    name: 'Egg-Inspired',
    background: Color(0xFF10302C),
    daylightInner: Color(0xFFFFF2B8),
    daylightOuter: Color(0xFFF2B544),
    daylightAlpha: 0.9,
    aheadAlpha: 0.3,
    egg: Color(0xFFFFFFFF),
    hand: Color(0xFFFF7F6A),
    text: Color(0xFFF2FBF9),
    muted: Color(0xFFBFD9D4),
  );

  /// The sunburst palette that goes with the user's chosen app palette.
  static SunburstPalette forApp(AppPalette palette) => switch (palette) {
        AppPalette.barnRed => barnRed,
        AppPalette.sage => sage,
        AppPalette.eggInspired => eggInspired,
      };
}

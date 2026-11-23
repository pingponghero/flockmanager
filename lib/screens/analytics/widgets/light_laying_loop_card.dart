import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../utils/light_laying_loop.dart';
import '../../../widgets/year_rings_chart.dart';
import 'year_info_sheets.dart';

/// "Light and laying" insight card (#1): weekly lay rate against daylight,
/// with a plain-language comparison of spring and autumn at the same light.
class LightLayingLoopCard extends StatelessWidget {
  final LightLayingLoop loop;
  final int year;

  /// Marks the last point as "now" when showing the current year.
  final bool isCurrentYear;

  const LightLayingLoopCard({
    super.key,
    required this.loop,
    required this.year,
    required this.isCurrentYear,
  });

  String _month(int week) => DateFormat.MMMM().format(
    DateTime(year).add(Duration(days: week * 7 + 3)),
  );

  String? get _insight {
    final pair = loop.sameLight;
    if (pair == null) return null;
    final hours = ((pair.rising.daylight + pair.falling.daylight) / 2).round();
    final up = (pair.rising.layRate * 100).round();
    final down = (pair.falling.layRate * 100).round();
    final m1 = _month(pair.rising.week), m2 = _month(pair.falling.week);
    if ((up - down).abs() < 5) {
      return 'With about $hours hours of daylight, your hens laid about the same '
          'in $m1 and $m2 ($up% and $down%).';
    }
    final link = up > down ? 'but only' : 'and';
    return 'With about $hours hours of daylight, your hens laid $up% in '
        '$m1 $link $down% in $m2.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final insight = _insight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Light and laying',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        loop.hasDaylightSwing
                            ? '${loop.label} \u00b7 one dot per week'
                            : loop.label,
                        style: muted,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Reading the loop',
                  onPressed: () => showLoopHelp(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!loop.hasDaylightSwing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Day length here barely changes through the year '
                  '(${loop.shortestDay.toStringAsFixed(1)}\u2013${loop.longestDay.toStringAsFixed(1)} h), '
                  'so there\u2019s no light-and-laying loop. Laying follows other '
                  'things, like heat, rain and molt.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else ...[
              Semantics(
                label:
                    'Weekly lay rate plotted against daylight hours for ${loop.label}. '
                    '${insight ?? ''}',
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: CustomPaint(
                    painter: _LoopPainter(
                      loop: loop,
                      isCurrentYear: isCurrentYear,
                      scheme: theme.colorScheme,
                      textStyle: theme.textTheme.bodySmall ?? const TextStyle(),
                      monthLetter: (w) => _month(w)[0],
                      monthOf: (w) =>
                          DateTime(year).add(Duration(days: w * 7 + 3)).month,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                insight ??
                    'Spring and autumn are compared once the year has both.',
                style: insight != null ? theme.textTheme.bodyMedium : muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoopPainter extends CustomPainter {
  final LightLayingLoop loop;
  final bool isCurrentYear;
  final ColorScheme scheme;
  final TextStyle textStyle;
  final String Function(int week) monthLetter;
  final int Function(int week) monthOf;

  _LoopPainter({
    required this.loop,
    required this.isCurrentYear,
    required this.scheme,
    required this.textStyle,
    required this.monthLetter,
    required this.monthOf,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, bottom = 22.0, top = 6.0, right = 8.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final pts = loop.points;

    final xLo = pts.map((p) => p.daylight).reduce(math.min).floorToDouble();
    final xHi = math.max(
      xLo + 1,
      pts.map((p) => p.daylight).reduce(math.max).ceilToDouble(),
    );
    final yHi = math.max(
      0.9,
      (pts.map((p) => p.layRate).reduce(math.max) * 10).ceil() / 10,
    );
    Offset at(LoopPoint p) => Offset(
      plot.left + (p.daylight - xLo) / (xHi - xLo) * plot.width,
      plot.bottom - (p.layRate / yHi).clamp(0.0, 1.0) * plot.height,
    );

    // Grid and axis labels.
    final grid = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    final label = textStyle.copyWith(
      fontSize: 10,
      color: scheme.onSurfaceVariant,
    );
    for (var h = xLo; h <= xHi; h++) {
      final x = plot.left + (h - xLo) / (xHi - xLo) * plot.width;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      _text(
        canvas,
        '${h.round()}h',
        Offset(x, plot.bottom + 4),
        label,
        center: true,
      );
    }
    for (var r = 0.0; r <= yHi + 0.001; r += 0.25) {
      final y = plot.bottom - r / yHi * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(
        canvas,
        '${(r * 100).round()}%',
        Offset(plot.left - 4, y - 6),
        label,
        alignRight: true,
      );
    }

    final offsets = pts.map(at).toList();
    final path = _smooth(offsets);
    final color = scheme.primary;

    if (pts.length >= 40) {
      canvas.drawPath(
        Path.from(path)..close(),
        Paint()..color = color.withValues(alpha: 0.08),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    // Direction arrows.
    for (final f in const [0.25, 0.5, 0.75]) {
      final i = (offsets.length * f).floor().clamp(1, offsets.length - 2);
      final dir = offsets[i + 1] - offsets[i - 1];
      if (dir.distance == 0) continue;
      final u = dir / dir.distance;
      final n = Offset(-u.dy, u.dx);
      final p = offsets[i];
      canvas.drawPath(
        Path()
          ..moveTo(p.dx + u.dx * 6, p.dy + u.dy * 6)
          ..lineTo(p.dx - u.dx * 4 + n.dx * 4, p.dy - u.dy * 4 + n.dy * 4)
          ..lineTo(p.dx - u.dx * 4 - n.dx * 4, p.dy - u.dy * 4 - n.dy * 4)
          ..close(),
        Paint()..color = color,
      );
    }

    // A small dot for every week, so "one dot per week" is what you see.
    final weekDot = Paint()..color = color.withValues(alpha: 0.7);
    for (final o in offsets) {
      canvas.drawCircle(o, 2.2, weekDot);
    }

    // Month starts: larger hollow dots, labelled outward from the middle.
    final mid = offsets.reduce((a, b) => a + b) / offsets.length.toDouble();
    final dot = Paint()..color = scheme.surface;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    var lastMonth = '';
    final placed = <Rect>[];
    for (var i = 0; i < pts.length; i++) {
      final m = monthLetter(pts[i].week);
      final key = '${monthOf(pts[i].week)}';
      if (key == lastMonth) continue;
      lastMonth = key;
      final p = offsets[i];
      canvas.drawCircle(p, 3, dot);
      canvas.drawCircle(p, 3, ring);
      final out = p - mid;
      final dir = out.distance == 0 ? const Offset(0, -1) : out / out.distance;
      // Where the loop crosses itself, skip a letter rather than overprint.
      final spot = Rect.fromCenter(center: p + dir * 12, width: 12, height: 14);
      if (placed.any((r) => r.overlaps(spot))) continue;
      placed.add(spot);
      _text(
        canvas,
        m,
        p + dir * 12 - const Offset(0, 6),
        label.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
        center: true,
      );
    }

    if (isCurrentYear) {
      canvas.drawCircle(
        offsets.last,
        5.5,
        Paint()..color = YearRingsChart.todayColor,
      );
      canvas.drawCircle(
        offsets.last,
        5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = scheme.surface,
      );
    }
  }

  Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = p[math.max(0, i - 1)], p1 = p[i], p2 = p[i + 1];
      final p3 = p[math.min(p.length - 1, i + 2)];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    TextStyle style, {
    bool center = false,
    bool alignRight = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? tp.width / 2 : (alignRight ? tp.width : 0.0);
    tp.paint(canvas, at - Offset(dx, 0));
  }

  @override
  bool shouldRepaint(_LoopPainter old) =>
      old.loop != loop ||
      old.scheme != scheme ||
      old.isCurrentYear != isCurrentYear;
}

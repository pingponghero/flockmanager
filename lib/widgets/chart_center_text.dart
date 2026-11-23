import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Helpers for the number in the middle of a ring chart (#1), where space is
/// a small circle and totals can run to six or seven digits.

/// Formats an egg total for a chart's centre: exact with separators up to
/// 999,999 ("123,456"), compact from a million ("1.2M"), where the exact
/// figure stops being readable at a glance anyway.
String formatCenterCount(int n) => n < 1000000
    ? NumberFormat.decimalPattern().format(n)
    : NumberFormat.compact().format(n);

/// Lays out [text] on one line at [style]'s size, shrinking it (down to
/// [minFontSize]) until it fits [maxWidth], so a long total never spills
/// out of the centre circle.
TextPainter fitCenterText(
  String text,
  TextStyle style, {
  required double maxWidth,
  double minFontSize = 7,
}) {
  var size = style.fontSize ?? 14;
  TextPainter layout(double fontSize) => TextPainter(
        text: TextSpan(text: text, style: style.copyWith(fontSize: fontSize)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
  var painter = layout(size);
  if (painter.width > maxWidth && painter.width > 0) {
    size = math.max(minFontSize, size * maxWidth / painter.width);
    painter = layout(size);
  }
  return painter;
}

import 'year_rings.dart';

/// The "light and laying" loop (#1): each week of a year plotted as daylight
/// hours against lay rate. Hens speed up as days lengthen and slow down (and
/// molt) as they shorten, so at the same daylight spring usually beats
/// autumn and the year traces a loop rather than a line.

class LoopPoint {
  final int week;
  final double daylight;
  final double layRate;
  const LoopPoint(this.week, this.daylight, this.layRate);
}

class LightLayingLoop {
  final String label;
  final List<LoopPoint> points;

  /// A week with lengthening days and one with shortening days at about the
  /// same daylight, when the data has both.
  final ({LoopPoint rising, LoopPoint falling})? sameLight;

  const LightLayingLoop({
    required this.label,
    required this.points,
    required this.sameLight,
  });
}

/// Weeks need at least this many counted days to be plotted.
const kLoopMinDaysPerWeek = 4;

/// A loop needs this many plotted weeks to be worth drawing.
const kLoopMinWeeks = 20;

/// Builds the loop for [ring], or null when there isn't enough data or no
/// lay rate (flock totals with no birds entered).
LightLayingLoop? buildLightLayingLoop(RingSeries ring, List<double> weeklyDaylight) {
  final points = <LoopPoint>[
    for (final b in ring.blocks)
      if (b.state == RingBlockState.logged &&
          b.layRate != null &&
          b.knownDays >= kLoopMinDaysPerWeek &&
          b.week < weeklyDaylight.length)
        LoopPoint(b.week, weeklyDaylight[b.week], b.layRate!),
  ];
  if (points.length < kLoopMinWeeks) return null;

  final lo = weeklyDaylight.reduce((a, b) => a < b ? a : b);
  final hi = weeklyDaylight.reduce((a, b) => a > b ? a : b);
  final target = (lo + hi) / 2;
  // Near the equator there's no meaningful swing to compare across.
  final tolerance = (hi - lo) * 0.12;

  bool rising(int w) =>
      weeklyDaylight[(w + 1) % weeklyDaylight.length] > weeklyDaylight[w];

  LoopPoint? nearest(bool wantRising) {
    LoopPoint? best;
    for (final p in points) {
      if (rising(p.week) != wantRising) continue;
      if (best == null || (p.daylight - target).abs() < (best.daylight - target).abs()) {
        best = p;
      }
    }
    return best != null && (best.daylight - target).abs() <= tolerance ? best : null;
  }

  final up = hi - lo >= 1.5 ? nearest(true) : null;
  final down = hi - lo >= 1.5 ? nearest(false) : null;
  return LightLayingLoop(
    label: ring.label,
    points: points,
    sameLight: up != null && down != null ? (rising: up, falling: down) : null,
  );
}

import 'dart:math' as math;

import '../models/bird.dart';
import '../models/bird_status_event.dart';
import '../models/egg_log.dart';
import '../models/enums.dart';
import 'daylight_calculator.dart';

/// Builds the data behind the year rings chart (#1).
///
/// The chart draws a year as a ring of 52 week blocks running clockwise from
/// January at the top. What a ring stands for depends on [RingMode]: one ring
/// per calendar year (flock totals), or one ring per hen for a chosen year.
///
/// Everything here is pure: callers pass logs, birds and status events in,
/// so the rules are easy to test.

/// What each ring represents.
enum RingMode { years, hens }

/// How a block's colour should be read.
enum RingColorScale {
  /// Eggs per hen per day (needs a known headcount).
  layRate,

  /// Eggs per day, relative to the busiest week shown (no headcount known).
  eggsPerDay,
}

/// The state of one week block.
enum RingBlockState {
  /// Nothing to draw: before logging started, or the hen wasn't in the flock
  /// (or wasn't laying age yet).
  empty,

  /// Inside a long run of unlogged days, so we don't know. Drawn blank and
  /// left out of rates.
  unknown,

  /// At least one day we can count. Short unlogged gaps count as zero eggs.
  logged,

  /// Entirely after today.
  future,
}

/// A run of this many unlogged days or more is treated as "unknown" instead
/// of zero eggs: the keeper was probably away or had stopped logging.
const kLongGapDays = 7;

/// Birds are counted toward headcount from this age (about 20 weeks).
const kLayingAgeDays = 140;

/// Lay rate drawn as the darkest block colour.
const kFullLayRate = 0.85;

/// A week with more eggs than this many per counted hen-day means the
/// headcount is wrong (birds entered after their eggs were logged), so its
/// lay rate is hidden rather than shown above 100%.
const kMaxPlausibleLayRate = 1.1;

/// Share of a year's eggs logged to hens needed to offer hens mode at all.
const kMinHenAttribution = 0.3;

/// Share needed to open on hens mode, or to show one hen's own rings.
const kAutoHensAttribution = 0.6;

/// Year rings mode shows at most this many recent years.
const kMaxYearRings = 6;

/// Weeks per ring. The last block absorbs days 358–366.
const kWeeksPerRing = 52;

class RingBlock {
  final int week;
  final RingBlockState state;

  /// Eggs counted in this block (known days only).
  final int eggs;

  /// Days in this block we could count.
  final int knownDays;

  /// Average laying-age hens across the block's in-scope days. For hens mode
  /// this is 1 while the hen was in the flock.
  final double hens;

  /// Eggs per hen per day, when headcount is known.
  final double? layRate;

  /// 0–1 colour strength, already scaled for [RingColorScale].
  final double intensity;

  const RingBlock({
    required this.week,
    required this.state,
    this.eggs = 0,
    this.knownDays = 0,
    this.hens = 0,
    this.layRate,
    this.intensity = 0,
  });

  double get eggsPerDay => knownDays > 0 ? eggs / knownDays : 0;
}

class RingSeries {
  /// Year as a string in years mode, bird id in hens mode.
  final String id;
  final String label;
  final List<RingBlock> blocks;
  final int eggs;
  final int knownDays;

  /// Laying-age hens summed over known days, in weeks where the headcount
  /// is plausible.
  final int henDays;

  /// Eggs in those same weeks, so [layRate] compares like with like.
  final int rateEggs;

  /// Weeks whose lay rate was hidden because the headcount was too low.
  final int implausibleWeeks;

  /// Set in hens mode.
  final Bird? bird;

  const RingSeries({
    required this.id,
    required this.label,
    required this.blocks,
    required this.eggs,
    required this.knownDays,
    required this.henDays,
    this.rateEggs = 0,
    this.implausibleWeeks = 0,
    this.bird,
  });

  /// Several rings added together, for the year table's "All" row: lay rate
  /// is total eggs over total hen-days, not an average of yearly rates.
  factory RingSeries.combined(String label, List<RingSeries> rings) => RingSeries(
        id: 'all',
        label: label,
        blocks: [for (final r in rings) ...r.blocks],
        eggs: rings.fold(0, (s, r) => s + r.eggs),
        knownDays: rings.fold(0, (s, r) => s + r.knownDays),
        henDays: rings.fold(0, (s, r) => s + r.henDays),
        rateEggs: rings.fold(0, (s, r) => s + r.rateEggs),
        implausibleWeeks: rings.fold(0, (s, r) => s + r.implausibleWeeks),
      );

  double? get layRate => henDays > 0 ? rateEggs / henDays : null;
  double get eggsPerDay => knownDays > 0 ? eggs / knownDays : 0;
  double get averageHens {
    var sum = 0.0, days = 0;
    for (final b in blocks) {
      if (b.state != RingBlockState.logged) continue;
      sum += b.hens * b.knownDays;
      days += b.knownDays;
    }
    return days > 0 ? sum / days : 0;
  }
}

class YearRingsData {
  final RingMode mode;

  /// The year shown in hens mode; the current year in years mode.
  final int year;

  /// Innermost first.
  final List<RingSeries> rings;
  final RingColorScale colorScale;

  /// Largest headcount in any block, for scaling ring thickness.
  final double maxHens;

  /// Busiest block's eggs per day (for the eggs-per-day scale).
  final double maxEggsPerDay;

  /// Daylight hours at the middle of each week, at the user's latitude.
  final List<double> weeklyDaylight;
  final DateTime today;

  /// Years that have any logs, oldest first.
  final List<int> availableYears;

  /// Eggs in [year] logged as flock totals rather than to a hen. Only shown
  /// in hens mode, where they can't be placed on a ring.
  final int unassignedEggs;

  /// Share of [year]'s eggs that were logged to a hen.
  final double attributedShare;

  const YearRingsData({
    required this.mode,
    required this.year,
    required this.rings,
    required this.colorScale,
    required this.maxHens,
    required this.maxEggsPerDay,
    required this.weeklyDaylight,
    required this.today,
    required this.availableYears,
    required this.unassignedEggs,
    required this.attributedShare,
  });

  bool get isEmpty => rings.isEmpty;

  /// Weeks (across all rings) whose lay rate was hidden for a too-low
  /// headcount.
  int get implausibleWeeks => rings.fold(0, (s, r) => s + r.implausibleWeeks);

  /// Whether hens mode would be meaningful for [year]: below this share,
  /// most eggs sit in flock totals and every hen looks like she barely lays.
  bool get canShowHens => attributedShare >= kMinHenAttribution;

  /// Whether a single hen's rings are worth showing (her Eggs tab).
  bool get henRingsMeaningful => attributedShare >= kAutoHensAttribution;
}

/// One day of the sunburst view (#1).
class DayPoint {
  final DateTime date;
  final int dayOfYear;
  final double daylight;
  final RingBlockState state;

  /// Eggs logged (zero on a short unlogged gap). Meaningful when [state] is
  /// [RingBlockState.logged].
  final int eggs;

  /// Expected eggs for a future day, when there's enough history to guess.
  final double? expected;

  /// Laying-age hens that day.
  final int hens;

  const DayPoint({
    required this.date,
    required this.dayOfYear,
    required this.daylight,
    required this.state,
    this.eggs = 0,
    this.expected,
    this.hens = 0,
  });
}

/// Days of history behind the forecast baseline.
const kForecastBaselineDays = 28;

// ==================== Day arithmetic ====================

/// Days since 1970-01-01 for the calendar date of [d] (DST-safe).
int dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1970)).inDays;

DateTime _dateOf(int n) => DateTime.utc(1970).add(Duration(days: n));

/// 1-based day of the year, counted in UTC so DST changes can't shift it.
int dayOfYear(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(d.year)).inDays + 1;

int _weekOf(DateTime d) => math.min(kWeeksPerRing - 1, (dayOfYear(d) - 1) ~/ 7);

/// A half-open span of day numbers, [start, end). `end == null` is ongoing.
class _Span {
  final int start;
  final int? end;
  const _Span(this.start, this.end);
  bool contains(int n) => n >= start && (end == null || n < end!);
}

/// Spans when [bird] was in the flock and of laying age.
/// Her acquired date when set and not in the future, otherwise when she was
/// entered in the app. (Matches `Bird.joinedDate` from #88.)
DateTime _joinedDate(Bird bird) {
  final acquired = bird.acquiredDate;
  return acquired != null && !acquired.isAfter(DateTime.now()) ? acquired : bird.createdAt;
}

List<_Span> _layingSpans(Bird bird, List<BirdStatusEvent> events) {
  final spans = <_Span>[];
  if (events.isNotEmpty) {
    var sorted = [...events]..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    // When she joined, by her own record: acquired date, else when entered.
    final joinedN = dayNumber(_joinedDate(bird));

    // Older imports wrote an 'active' event for every bird at import time,
    // after real deaths and sales. If she isn't active now, an 'active'
    // event after her last status change is spurious (#88).
    if (bird.status != BirdStatus.active) {
      final lastChange = sorted.lastIndexWhere((e) => e.status != 'active');
      if (lastChange >= 0) sorted = sorted.sublist(0, lastChange + 1);
    }

    // A history that starts with a death or sale means she was active before
    // it, from when she joined.
    int? from = sorted.first.status != 'active' && joinedN < dayNumber(sorted.first.eventDate)
        ? joinedN
        : null;
    for (final e in sorted) {
      final n = dayNumber(e.eventDate);
      if (e.status == 'active') {
        from ??= n;
      } else if (from != null) {
        spans.add(_Span(from, n));
        from = null;
      }
    }
    if (from != null) spans.add(_Span(from, null));
    // The app dates a bird's first 'active' event when she was entered, not
    // when she joined. Her joined date is the better start (#88).
    if (spans.isNotEmpty && sorted.first.status == 'active' && joinedN < spans.first.start) {
      spans[0] = _Span(joinedN, spans.first.end);
    }
  } else {
    final start = dayNumber(bird.acquiredDate ?? bird.createdAt);
    final end = bird.status == BirdStatus.active || bird.statusDate == null
        ? null
        : dayNumber(bird.statusDate!);
    spans.add(_Span(start, end));
  }

  final hatch = bird.hatchDate;
  if (hatch == null) return spans;
  final ofAge = dayNumber(hatch) + kLayingAgeDays;
  return [
    for (final s in spans)
      if (s.end == null || s.end! > ofAge)
        _Span(math.max(s.start, ofAge), s.end),
  ];
}

// ==================== Builder ====================

class YearRingsBuilder {
  final List<EggLog> logs;
  final List<Bird> birds;
  final List<BirdStatusEvent> events;
  final DateTime today;
  final int latitude;

  late final int _todayN = dayNumber(today);
  final Map<int, int> _eggsByDay = {};
  final Map<String, Map<int, int>> _eggsByBirdDay = {};
  final Map<int, int> _unassignedByDay = {};
  final Set<int> _unknownDays = {};
  int? _firstN;
  late final List<Bird> _hens;
  late final Map<String, List<_Span>> _spans;

  YearRingsBuilder({
    required this.logs,
    required this.birds,
    required this.events,
    required this.today,
    required this.latitude,
  }) {
    for (final log in logs) {
      final n = dayNumber(log.date);
      _eggsByDay[n] = (_eggsByDay[n] ?? 0) + log.count;
      if (log.birdId != null) {
        final m = _eggsByBirdDay.putIfAbsent(log.birdId!, () => {});
        m[n] = (m[n] ?? 0) + log.count;
      } else {
        _unassignedByDay[n] = (_unassignedByDay[n] ?? 0) + log.count;
      }
      if (_firstN == null || n < _firstN!) _firstN = n;
    }

    // Long unlogged runs between the first log and today are "unknown".
    if (_firstN != null) {
      int? runStart;
      for (var n = _firstN!; n <= _todayN + 1; n++) {
        final logged = n <= _todayN && _eggsByDay.containsKey(n);
        if (!logged && n <= _todayN) {
          runStart ??= n;
        } else if (runStart != null) {
          if (n - runStart >= kLongGapDays) {
            for (var g = runStart; g < n; g++) {
              _unknownDays.add(g);
            }
          }
          runStart = null;
        }
      }
    }

    _hens = birds.where((b) => b.sex == BirdSex.female).toList();
    final eventsByBird = <String, List<BirdStatusEvent>>{};
    for (final e in events) {
      eventsByBird.putIfAbsent(e.birdId, () => []).add(e);
    }
    _spans = {
      for (final b in _hens) b.id: _layingSpans(b, eventsByBird[b.id] ?? const []),
    };
  }

  RingBlockState _dayState(int n) {
    if (n > _todayN) return RingBlockState.future;
    if (_firstN == null || n < _firstN!) return RingBlockState.empty;
    if (_unknownDays.contains(n)) return RingBlockState.unknown;
    return RingBlockState.logged;
  }

  int _headcount(int n) {
    var c = 0;
    for (final b in _hens) {
      if (_spans[b.id]!.any((s) => s.contains(n))) c++;
    }
    return c;
  }

  List<int> get availableYears {
    if (_firstN == null) return const [];
    final first = _dateOf(_firstN!).year;
    return [for (var y = first; y <= today.year; y++) y];
  }

  List<double> _weeklyDaylight() => [
        for (var w = 0; w < kWeeksPerRing; w++)
          DaylightCalculator.calculateDaylightHours(w * 7 + 4, latitude),
      ];

  ({int unassigned, double share}) _attribution(int year) {
    var total = 0, unassigned = 0;
    for (final e in _eggsByDay.entries) {
      if (_dateOf(e.key).year == year) total += e.value;
    }
    for (final e in _unassignedByDay.entries) {
      if (_dateOf(e.key).year == year) unassigned += e.value;
    }
    return (
      unassigned: unassigned,
      share: total > 0 ? (total - unassigned) / total : 0.0,
    );
  }

  /// Day numbers in [year], grouped into week blocks.
  List<List<int>> _weeksOf(int year) {
    final weeks = List.generate(kWeeksPerRing, (_) => <int>[]);
    final start = dayNumber(DateTime.utc(year));
    final end = dayNumber(DateTime.utc(year + 1));
    for (var n = start; n < end; n++) {
      weeks[_weekOf(_dateOf(n))].add(n);
    }
    return weeks;
  }

  /// Every day of [year] for the sunburst: daylight, eggs, and for days
  /// still ahead an expected count. The forecast uses the same day last year
  /// when it was logged, otherwise the last four weeks' average scaled by
  /// daylight (dampened, since laying doesn't track light one-for-one).
  List<DayPoint> buildDays(int year) {
    final start = dayNumber(DateTime.utc(year));
    final end = dayNumber(DateTime.utc(year + 1));

    double? baseline, baselineLight;
    var sum = 0, days = 0;
    var light = 0.0;
    for (var n = _todayN; n > _todayN - 365 && days < kForecastBaselineDays; n--) {
      if (_dayState(n) != RingBlockState.logged) continue;
      sum += _eggsByDay[n] ?? 0;
      light += DaylightCalculator.calculateDaylightHours(dayOfYear(_dateOf(n)), latitude);
      days++;
    }
    if (days >= 7) {
      baseline = sum / days;
      baselineLight = light / days;
    }

    return [
      for (var n = start; n < end; n++)
        () {
          final date = _dateOf(n);
          final doy = n - start + 1;
          final daylight = DaylightCalculator.calculateDaylightHours(doy, latitude);
          final state = _dayState(n);
          double? expected;
          if (state == RingBlockState.future) {
            final lastYear = dayNumber(DateTime.utc(year - 1, date.month, date.day));
            if (_dayState(lastYear) == RingBlockState.logged) {
              expected = (_eggsByDay[lastYear] ?? 0).toDouble();
            } else if (baseline != null && baselineLight! > 0) {
              expected = baseline * math.pow(daylight / baselineLight, 0.6);
            }
          }
          return DayPoint(
            date: DateTime(date.year, date.month, date.day),
            dayOfYear: doy,
            daylight: daylight,
            state: state,
            eggs: state == RingBlockState.logged ? (_eggsByDay[n] ?? 0) : 0,
            expected: expected,
            hens: _headcount(n),
          );
        }(),
    ];
  }

  /// Picks hens mode when most of the year's eggs were logged to hens.
  RingMode autoMode(int year) =>
      _attribution(year).share >= kAutoHensAttribution ? RingMode.hens : RingMode.years;

  YearRingsData build({RingMode? mode, int? year}) {
    final y = year ?? today.year;
    final m = mode ?? autoMode(y);
    final rings = m == RingMode.years ? _yearRings() : _henRings(y);
    return _finish(m, y, rings, alwaysLayRate: m == RingMode.hens);
  }

  /// One hen's years (#1): a ring per year she was in the flock, coloured by
  /// her own lay rate. The flock's logs decide which days were logged, so a
  /// day she didn't lay counts as a zero rather than a gap.
  YearRingsData buildForHen(String birdId) {
    final hen = _hens.where((b) => b.id == birdId).firstOrNull;
    if (hen == null) return _finish(RingMode.years, today.year, const []);
    final spans = _spans[hen.id]!;
    bool inScope(int n) => spans.any((s) => s.contains(n));
    final years = [
      for (final y in availableYears)
        if (_weeksOf(y).expand((w) => w).any((n) => n <= _todayN && inScope(n))) y,
    ];
    final shown = years.length > kMaxYearRings
        ? years.sublist(years.length - kMaxYearRings)
        : years;
    final rings = [
      for (final y in shown)
        _series(
          id: '$y',
          label: '$y',
          bird: hen,
          weeks: _weeksOf(y),
          inScope: inScope,
          eggsOn: (n) => _eggsByBirdDay[hen.id]?[n] ?? 0,
          hensOn: (_) => 1,
        ),
    ];
    return _finish(RingMode.years, today.year, rings, alwaysLayRate: true);
  }

  YearRingsData _finish(
    RingMode m,
    int y,
    List<RingSeries> rings, {
    bool alwaysLayRate = false,
  }) {
    final attribution = _attribution(y);
    var maxHens = 0.0, maxEpd = 0.0;
    var countedDays = 0, daysWithHeadcount = 0;
    for (final r in rings) {
      for (final b in r.blocks) {
        maxHens = math.max(maxHens, b.hens);
        if (b.state == RingBlockState.logged) {
          maxEpd = math.max(maxEpd, b.eggsPerDay);
          countedDays += b.knownDays;
          if (b.layRate != null) daysWithHeadcount += b.knownDays;
        }
      }
    }
    // A single hen always knows its headcount (one). Flock totals need birds
    // entered for most of the logged days, otherwise lay rate would be noise.
    final scale = alwaysLayRate ||
            (countedDays > 0 && daysWithHeadcount / countedDays >= 0.8)
        ? RingColorScale.layRate
        : RingColorScale.eggsPerDay;

    double intensity(RingBlock b) {
      if (b.state != RingBlockState.logged) return 0;
      if (scale == RingColorScale.layRate) {
        return ((b.layRate ?? 0) / kFullLayRate).clamp(0.0, 1.0);
      }
      return maxEpd > 0 ? (b.eggsPerDay / maxEpd).clamp(0.0, 1.0) : 0;
    }

    final scored = [
      for (final r in rings)
        RingSeries(
          id: r.id,
          label: r.label,
          eggs: r.eggs,
          knownDays: r.knownDays,
          henDays: r.henDays,
          rateEggs: r.rateEggs,
          implausibleWeeks: r.implausibleWeeks,
          bird: r.bird,
          blocks: [
            for (final b in r.blocks)
              RingBlock(
                week: b.week,
                state: b.state,
                eggs: b.eggs,
                knownDays: b.knownDays,
                hens: b.hens,
                layRate: b.layRate,
                intensity: intensity(b),
              ),
          ],
        ),
    ];

    return YearRingsData(
      mode: m,
      year: y,
      rings: scored,
      colorScale: scale,
      maxHens: maxHens,
      maxEggsPerDay: maxEpd,
      weeklyDaylight: _weeklyDaylight(),
      today: today,
      availableYears: availableYears,
      unassignedEggs: attribution.unassigned,
      attributedShare: attribution.share,
    );
  }

  List<RingSeries> _yearRings() {
    final years = availableYears;
    final shown = years.length > kMaxYearRings
        ? years.sublist(years.length - kMaxYearRings)
        : years;
    return [
      for (final y in shown)
        _series(
          id: '$y',
          label: '$y',
          weeks: _weeksOf(y),
          inScope: (_) => true,
          eggsOn: (n) => _eggsByDay[n] ?? 0,
          hensOn: _headcount,
        ),
    ];
  }

  List<RingSeries> _henRings(int year) {
    final start = dayNumber(DateTime.utc(year));
    final end = math.min(dayNumber(DateTime.utc(year + 1)), _todayN + 1);
    final present = <({Bird bird, int from})>[];
    for (final b in _hens) {
      final spans = _spans[b.id]!;
      int? from;
      for (var n = start; n < end; n++) {
        if (spans.any((s) => s.contains(n))) {
          from = n;
          break;
        }
      }
      if (from != null) present.add((bird: b, from: from));
    }
    // Oldest members inside: the ring order reads as flock history.
    present.sort((a, b) {
      final ka = a.bird.acquiredDate ?? a.bird.hatchDate ?? a.bird.createdAt;
      final kb = b.bird.acquiredDate ?? b.bird.hatchDate ?? b.bird.createdAt;
      final c = ka.compareTo(kb);
      return c != 0 ? c : a.from.compareTo(b.from);
    });

    final weeks = _weeksOf(year);
    return [
      for (final p in present)
        _series(
          id: p.bird.id,
          label: p.bird.name,
          bird: p.bird,
          weeks: weeks,
          inScope: (n) => _spans[p.bird.id]!.any((s) => s.contains(n)),
          eggsOn: (n) => _eggsByBirdDay[p.bird.id]?[n] ?? 0,
          hensOn: (_) => 1,
        ),
    ];
  }

  RingSeries _series({
    required String id,
    required String label,
    required List<List<int>> weeks,
    required bool Function(int n) inScope,
    required int Function(int n) eggsOn,
    required int Function(int n) hensOn,
    Bird? bird,
  }) {
    final blocks = <RingBlock>[];
    var eggs = 0, known = 0, henDays = 0, rateEggs = 0, implausible = 0;
    for (var w = 0; w < weeks.length; w++) {
      var bEggs = 0, bKnown = 0, bHenDays = 0, bHensSum = 0, bScope = 0;
      var anyUnknown = false, anyFuture = false, futureHens = 0;
      for (final n in weeks[w]) {
        final s = _dayState(n);
        if (s == RingBlockState.future) {
          anyFuture = true;
          if (inScope(_todayN)) futureHens = math.max(futureHens, hensOn(_todayN));
          continue;
        }
        if (s == RingBlockState.empty || !inScope(n)) continue;
        final h = hensOn(n);
        bScope++;
        bHensSum += h;
        if (s == RingBlockState.unknown) {
          anyUnknown = true;
          continue;
        }
        bKnown++;
        bEggs += eggsOn(n);
        bHenDays += h;
      }

      final RingBlockState state;
      if (bKnown > 0) {
        state = RingBlockState.logged;
      } else if (anyUnknown) {
        state = RingBlockState.unknown;
      } else if (anyFuture && (futureHens > 0 || bird == null)) {
        state = RingBlockState.future;
      } else {
        state = RingBlockState.empty;
      }
      final hens = state == RingBlockState.future
          ? futureHens.toDouble()
          : (bScope > 0 ? bHensSum / bScope : 0.0);

      final plausible = bHenDays > 0 && bEggs <= bHenDays * kMaxPlausibleLayRate;
      if (bHenDays > 0 && !plausible) implausible++;
      blocks.add(RingBlock(
        week: w,
        state: state,
        eggs: bEggs,
        knownDays: bKnown,
        hens: hens,
        layRate: plausible ? bEggs / bHenDays : null,
      ));
      eggs += bEggs;
      known += bKnown;
      if (plausible) {
        henDays += bHenDays;
        rateEggs += bEggs;
      }
    }
    return RingSeries(
      id: id,
      label: label,
      blocks: blocks,
      eggs: eggs,
      knownDays: known,
      henDays: henDays,
      rateEggs: rateEggs,
      implausibleWeeks: implausible,
      bird: bird,
    );
  }
}

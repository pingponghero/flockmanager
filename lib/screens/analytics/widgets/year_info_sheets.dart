import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/year_rings.dart';
import '../../../widgets/info_sheet.dart';

/// The "how is this worked out" sheets behind the year view (#1). The
/// screens show the numbers; the reasoning and formulas live here.

final _fmt = NumberFormat.decimalPattern();
String _pct(double r) => '${(r * 100).round()}%';

/// How the rings are counted, with the parts that apply to this data.
Future<void> showHowYearIsCounted(BuildContext context, YearRingsData data) {
  final hours = data.weeklyDaylight;
  final byHen = data.mode == RingMode.hens;
  final rate = data.colorScale == RingColorScale.layRate;
  return InfoSheet.show(
    context,
    title: 'How your year is counted',
    sections: [
      InfoSection(
        icon: Icons.donut_large,
        title: 'Rings and blocks',
        body: 'Each ring is ${byHen ? 'a hen' : 'a year'}, and each block is one week, '
            'starting with January at the top and running clockwise. Darker '
            'blocks mean ${rate ? 'a higher lay rate' : 'more eggs a day'}.',
      ),
      if (rate)
        const InfoSection(
          icon: Icons.calculate_outlined,
          title: 'Lay rate',
          body: 'Eggs divided by hen-days: the number of laying-age hens (about '
              '20 weeks and older) on each day counted, added up.',
          formula: 'lay rate = eggs ÷ hen-days\n'
              'e.g. 7 hens × 7 days = 49 hen-days; 35 eggs ÷ 49 = 71%',
        )
      else
        const InfoSection(
          icon: Icons.calculate_outlined,
          title: 'Eggs per day',
          body: 'There aren’t enough hens entered for these dates to work out a '
              'lay rate, so colour shows eggs per day instead, compared with your '
              'busiest week.',
        ),
      const InfoSection(
        icon: Icons.event_busy_outlined,
        title: 'Days you didn’t log',
        body: 'A day with nothing logged counts as zero eggs, as on the rest of '
            'Stats. A run of $kLongGapDays days or more is treated as time away: '
            'left blank and kept out of the rate.',
      ),
      if (!byHen && data.maxHens > 0)
        const InfoSection(
          icon: Icons.line_weight,
          title: 'Ring thickness',
          body: 'A thicker ring means more laying-age hens that week, so you can '
              'see the flock grow and shrink.',
        ),
      if (data.implausibleWeeks > 0) _implausibleSection(data),
      if (byHen && data.unassignedEggs > 0) _unassignedSection(data),
      if (hours.isNotEmpty)
        InfoSection(
          icon: Icons.wb_sunny_outlined,
          title: 'Daylight band',
          body: 'The thin outer band shows day length where you live, from '
              '${hours.reduce(math.min).toStringAsFixed(1)} to '
              '${hours.reduce(math.max).toStringAsFixed(1)} hours. You can change '
              'your latitude in Settings.',
        ),
    ],
  );
}

InfoSection _implausibleSection(YearRingsData data) => InfoSection(
      icon: Icons.help_outline,
      title: 'Weeks without a lay rate',
      body: 'In ${data.implausibleWeeks} '
          '${data.implausibleWeeks == 1 ? 'week' : 'weeks'} more eggs were logged '
          'than there were hens in the flock. That usually means hens were added '
          'to the app after their eggs were logged. Setting each hen’s acquired '
          'date fixes it.',
    );

InfoSection _unassignedSection(YearRingsData data) => InfoSection(
      icon: Icons.egg_outlined,
      title: 'Eggs not on a hen’s ring',
      body: '${_fmt.format(data.unassignedEggs)} eggs in ${data.year} were logged as '
          'flock totals. They count in the Years view but can’t be placed on any '
          'one hen’s ring.',
    );

/// Short notices for the year view; each opens the full explanation.
List<({IconData icon, String text})> yearNotices(YearRingsData data) => [
      if (data.implausibleWeeks > 0)
        (
          icon: Icons.help_outline,
          text: '${data.implausibleWeeks} '
              '${data.implausibleWeeks == 1 ? 'week' : 'weeks'} without a lay rate',
        ),
      if (data.mode == RingMode.hens && data.unassignedEggs > 0)
        (
          icon: Icons.egg_outlined,
          text: '${_fmt.format(data.unassignedEggs)} eggs logged as flock totals',
        ),
    ];

/// The sums behind one ring's numbers.
Future<void> showRingMath(BuildContext context, YearRingsData data, RingSeries ring) {
  final rate = ring.layRate;
  final blankWeeks = ring.blocks.where((b) => b.state == RingBlockState.unknown).length;
  return InfoSheet.show(
    context,
    title: ring.label,
    sections: [
      if (rate != null)
        InfoSection(
          icon: Icons.calculate_outlined,
          title: data.colorScale == RingColorScale.layRate
              ? 'Lay rate'
              : 'Lay rate, where hens were recorded',
          body: data.mode == RingMode.hens
              ? 'Her eggs divided by the days she was in the flock and counted.'
              : data.colorScale == RingColorScale.layRate
                  ? 'Eggs divided by hen-days (laying-age hens on each counted day, added up).'
                  : 'Only weeks with enough hens recorded are included, so this is a '
                      'partial figure. The chart uses eggs per day instead.',
          formula: '${_fmt.format(ring.rateEggs)} eggs ÷ '
              '${_fmt.format(ring.henDays)} ${data.mode == RingMode.hens ? 'days' : 'hen-days'}'
              ' = ${_pct(rate)}',
        ),
      InfoSection(
        icon: Icons.egg_outlined,
        title: 'Eggs per day',
        body: 'Eggs divided by the days counted.',
        formula: '${_fmt.format(ring.eggs)} eggs ÷ ${_fmt.format(ring.knownDays)} days'
            ' = ${ring.eggsPerDay.toStringAsFixed(1)} a day',
      ),
      InfoSection(
        icon: Icons.event_available_outlined,
        title: 'Days counted',
        body: '${_fmt.format(ring.knownDays)} days: every day from your first log to '
            'today, with short unlogged gaps counted as zero'
            '${blankWeeks > 0 ? '. $blankWeeks ${blankWeeks == 1 ? 'week was' : 'weeks were'} '
                'left out as time away ($kLongGapDays+ days with nothing logged)' : ''}.',
      ),
      if (ring.implausibleWeeks > 0)
        InfoSection(
          icon: Icons.help_outline,
          title: 'Weeks left out of the lay rate',
          body: '${ring.implausibleWeeks} '
              '${ring.implausibleWeeks == 1 ? 'week has' : 'weeks have'} more eggs than '
              'hens recorded, so ${ring.implausibleWeeks == 1 ? 'it isn’t' : 'they aren’t'} '
              'in the lay rate. Setting acquired dates on your hens fixes it.',
        ),
    ],
  );
}

Future<void> showLoopHelp(BuildContext context) => InfoSheet.show(
      context,
      title: 'Reading the loop',
      sections: const [
        InfoSection(
          icon: Icons.scatter_plot_outlined,
          title: 'Week by week',
          body: 'The line follows the year a week at a time: how much daylight '
              'there was (across) and your lay rate (up). Dots mark the start of '
              'each month, and the arrows show which way the year is moving.',
        ),
        InfoSection(
          icon: Icons.autorenew,
          title: 'Why it’s a loop',
          body: 'Hens respond to days getting longer, not just to how long they '
              'are, and most molt in autumn. So at the same daylight, spring '
              'usually beats autumn and the year traces a loop rather than a line.',
        ),
        InfoSection(
          icon: Icons.compare_arrows,
          title: 'The comparison',
          body: 'We pick a spring week and an autumn week with about the same '
              'daylight and compare their lay rates. The wider the loop, the harder '
              'autumn hit your flock.',
        ),
      ],
    );

Future<void> showSunburstHelp(BuildContext context) => InfoSheet.show(
      context,
      title: 'Reading the sunburst',
      sections: const [
        InfoSection(
          icon: Icons.wb_sunny_outlined,
          title: 'The gold egg is daylight',
          body: 'Measured from the centre, the gold shape is each day’s length '
              'where you live, with the longest day at the top. That’s what gives '
              'it the egg shape.',
        ),
        InfoSection(
          icon: Icons.egg_outlined,
          title: 'Cream rays are eggs',
          body: 'One ray per day, longer when more eggs were laid. Gaps are days '
              'with nothing logged during time away.',
        ),
        InfoSection(
          icon: Icons.insights_outlined,
          title: 'Faint rays are a forecast',
          body: 'For days still ahead: the same day last year if you logged it, '
              'otherwise your last four weeks’ average adjusted for daylight. '
              'Laying doesn’t follow light one-for-one, so the adjustment is '
              'softened.',
          formula: 'expected = recent eggs a day × (daylight ÷ recent daylight)^0.6',
        ),
      ],
    );

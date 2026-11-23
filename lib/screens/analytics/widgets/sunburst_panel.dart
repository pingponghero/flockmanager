import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/theme_provider.dart';
import '../../../providers/year_rings_provider.dart';
import '../../../utils/year_rings.dart';
import '../../../widgets/chart_center_text.dart';
import '../../../widgets/sunburst_chart.dart';
import 'year_info_sheets.dart';

/// The "Days" view of the year screen (#1): the sunburst with a hand you
/// scrub through the year, and a readout for the day under it.
class SunburstPanel extends ConsumerStatefulWidget {
  final int year;
  const SunburstPanel({super.key, required this.year});

  @override
  ConsumerState<SunburstPanel> createState() => _SunburstPanelState();
}

class _SunburstPanelState extends ConsumerState<SunburstPanel> {
  int? _day;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(yearDaysProvider(widget.year));
    // Follows the user's chosen app palette.
    final palette = SunburstPalette.forApp(ref.watch(themeProvider));
    final value = async.value;
    if (value == null) {
      return const AspectRatio(
        aspectRatio: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final days = value.days;
    final now = DateTime.now();
    final todayDoy = now.year == widget.year ? dayOfYear(now) : null;
    final day = (_day ?? todayDoy ?? 172).clamp(1, days.length);
    final point = days[day - 1];
    final fmt = NumberFormat.decimalPattern();
    final total = days
        .where((d) => d.state == RingBlockState.logged)
        .fold<int>(0, (s, d) => s + d.eggs);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: palette.muted,
    );

    final (badge, badgeFill) = switch (point.state) {
      _ when point.dayOfYear == todayDoy => (
        'Today',
        palette.hand,
      ),
      RingBlockState.future => ('Forecast', null),
      RingBlockState.logged => ('Logged', const Color(0xFF3A3027)),
      _ => ('Not logged', null),
    };
    final (eggsText, eggsSub) = switch (point.state) {
      RingBlockState.logged => (
        '${point.eggs}',
        point.hens > 0
            ? '${point.eggs == 1 ? 'egg' : 'eggs'} from ${point.hens} hens'
            : (point.eggs == 1 ? 'egg' : 'eggs'),
      ),
      RingBlockState.future when point.expected != null => (
        '~${point.expected!.toStringAsFixed(1)}',
        'eggs expected',
      ),
      _ when point.dayOfYear == todayDoy => ('–', 'not logged yet'),
      _ => ('–', 'not logged'),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Semantics(
            label:
                'Sunburst of ${widget.year}: one ray per day, longest day at the top. '
                'Gold rays are daylight, cream rays are eggs. ${fmt.format(total)} eggs logged.',
            child: AspectRatio(
              aspectRatio: 1,
              child: SunburstChart(
                days: days,
                selectedDay: day,
                southernHemisphere: value.latitude < 0,
                palette: palette,
                centerValue: formatCenterCount(total),
                centerLabel: todayDoy != null ? 'eggs so far' : 'eggs',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _key(palette.daylightOuter, 'Daylight', muted),
              _key(palette.egg, 'Eggs laid', muted),
              _key(
                palette.egg.withValues(alpha: 0.32),
                'Forecast',
                muted,
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: palette.muted,
                ),
                tooltip: 'Reading the sunburst',
                visualDensity: VisualDensity.compact,
                onPressed: () => showSunburstHelp(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E261E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap, so the badge drops under the date at large text sizes.
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            DateFormat.MMMd().format(point.date),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: palette.text,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeFill,
                              border: badgeFill == null
                                  ? Border.all(color: palette.muted)
                                  : null,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              badge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: badgeFill == palette.hand
                                    ? palette.background
                                    : palette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text('${_hm(point.daylight)} of daylight', style: muted),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Capped so "eggs from 7 hens" wraps rather than squeezing
                // the date out at large text sizes.
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        eggsText,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(eggsSub, style: muted, textAlign: TextAlign.end),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: day.toDouble(),
            min: 1,
            max: days.length.toDouble(),
            divisions: days.length - 1,
            activeColor: palette.hand,
            inactiveColor: palette.muted.withValues(alpha: 0.3),
            semanticFormatterCallback: (v) =>
                DateFormat.MMMd().format(days[v.round() - 1].date),
            label: DateFormat.MMMd().format(point.date),
            onChanged: (v) => setState(() => _day = v.round()),
          ),
        ],
      ),
    );
  }

  static String _hm(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  static Widget _key(Color color, String text, TextStyle? style) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 14, height: 3, color: color),
      const SizedBox(width: 5),
      Text(text, style: style),
    ],
  );
}

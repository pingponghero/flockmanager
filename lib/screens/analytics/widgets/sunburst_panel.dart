import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/year_rings_provider.dart';
import '../../../utils/year_rings.dart';
import '../../../widgets/sunburst_chart.dart';
import '../../../widgets/year_rings_chart.dart';

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
    final muted = theme.textTheme.bodySmall?.copyWith(color: SunburstChart.nightMuted);

    final (badge, badgeFill) = switch (point.state) {
      _ when point.dayOfYear == todayDoy => ('Today', YearRingsChart.todayColor),
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
      _ => ('–', 'no count'),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: SunburstChart.night,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Semantics(
            label: 'Sunburst of ${widget.year}: one ray per day, longest day at the top. '
                'Gold rays are daylight, cream rays are eggs. ${fmt.format(total)} eggs logged.',
            child: AspectRatio(
              aspectRatio: 1,
              child: SunburstChart(
                days: days,
                selectedDay: day,
                southernHemisphere: value.latitude < 0,
                centerValue: fmt.format(total),
                centerLabel: todayDoy != null ? 'eggs so far' : 'eggs',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            alignment: WrapAlignment.center,
            children: [
              _key(SunburstChart.sun.withValues(alpha: 0.6), 'Daylight', muted),
              _key(SunburstChart.egg, 'Eggs laid', muted),
              _key(SunburstChart.egg.withValues(alpha: 0.32), 'Forecast', muted),
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
                      Row(children: [
                        Text(
                          DateFormat.MMMd().format(point.date),
                          style: theme.textTheme.titleMedium?.copyWith(color: SunburstChart.nightText),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeFill,
                            border: badgeFill == null ? Border.all(color: SunburstChart.nightMuted) : null,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            badge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: badgeFill == YearRingsChart.todayColor
                                  ? SunburstChart.night
                                  : SunburstChart.nightMuted,
                            ),
                          ),
                        ),
                      ]),
                      Text('${_hm(point.daylight)} of daylight', style: muted),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      eggsText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: SunburstChart.nightText,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(eggsSub, style: muted),
                  ],
                ),
              ],
            ),
          ),
          Slider(
            value: day.toDouble(),
            min: 1,
            max: days.length.toDouble(),
            divisions: days.length - 1,
            activeColor: YearRingsChart.todayColor,
            inactiveColor: SunburstChart.nightMuted.withValues(alpha: 0.3),
            semanticFormatterCallback: (v) => DateFormat.MMMd().format(days[v.round() - 1].date),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/year_rings_provider.dart';
import '../../utils/edge_insets.dart';
import '../../utils/light_laying_loop.dart';
import '../../utils/year_rings.dart';
import '../../widgets/chart_center_text.dart';
import '../../widgets/choice_chip_row.dart';
import '../../widgets/error_state.dart';
import '../../widgets/info_sheet.dart';
import '../../widgets/year_rings_chart.dart';
import 'widgets/light_laying_loop_card.dart';
import 'widgets/sunburst_panel.dart';
import 'widgets/year_info_sheets.dart';

/// Full-screen year view (#1): rings by year or by hen, or the day-by-day
/// sunburst, with a detail card for the ring you tap and the
/// light-and-laying loop underneath.
class YearViewScreen extends ConsumerStatefulWidget {
  const YearViewScreen({super.key});

  @override
  ConsumerState<YearViewScreen> createState() => _YearViewScreenState();
}

/// What the year screen is showing. Years and hens are ring charts; days is
/// the sunburst.
enum _View { years, hens, days }

class _YearViewScreenState extends ConsumerState<YearViewScreen> {
  /// Null until the user picks: the data chooses a sensible default.
  _View? _view;
  int _year = DateTime.now().year;
  int? _selected;
  bool _selectionTouched = false;

  void _setView(_View view) => setState(() {
    _view = view;
    _selected = null;
    _selectionTouched = false;
  });

  void _setYear(int year) => setState(() {
    _year = year;
    _selected = null;
    _selectionTouched = false;
  });

  RingMode? get _ringMode => switch (_view) {
    null => null,
    _View.hens => RingMode.hens,
    _View.years || _View.days => RingMode.years,
  };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(yearRingsProvider((mode: _ringMode, year: _year)));

    final loaded = async.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your year'),
        actions: [
          if (loaded != null && !loaded.isEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'How this is counted',
              onPressed: () => showHowYearIsCounted(context, loaded),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Couldn\u2019t load your year',
          error: e,
          onRetry: () => ref.invalidate(yearRingsProvider),
        ),
        data: (data) {
          if (data.isEmpty) return const _EmptyYear();
          final view =
              _view ?? (data.mode == RingMode.hens ? _View.hens : _View.years);
          final views = [
            _View.years,
            if (data.canShowHens || data.mode == RingMode.hens) _View.hens,
            _View.days,
          ];
          // Years mode opens on the current year; hens mode on no one.
          final selected = _selectionTouched
              ? _selected
              : (data.mode == RingMode.years ? data.rings.length - 1 : null);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24,
            ).withSystemNavigation(context),
            children: [
              ChoiceChipRow<_View>(
                padding: EdgeInsets.zero,
                values: views,
                selected: view,
                labelOf: (v) => switch (v) {
                  _View.years => 'Years',
                  _View.hens => 'Hens',
                  _View.days => 'Days',
                },
                onSelected: _setView,
              ),
              if (view != _View.years && data.availableYears.length > 1) ...[
                const SizedBox(height: 8),
                ChoiceChipRow<int>(
                  padding: EdgeInsets.zero,
                  values: data.availableYears.reversed.toList(),
                  selected: _year,
                  labelOf: (y) => '$y',
                  onSelected: _setYear,
                ),
              ],
              const SizedBox(height: 12),
              if (view == _View.days) ...[
                SunburstPanel(year: _year),
                ..._loopFor(
                  data,
                  data.rings.indexWhere((r) => r.id == '$_year'),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: YearRingsChart(
                            data: data,
                            selected: selected,
                            centerValue: formatCenterCount(
                              data.rings.fold<int>(0, (s, r) => s + r.eggs),
                            ),
                            centerLabel: data.mode == RingMode.years
                                ? 'since ${data.rings.first.label}'
                                : 'eggs in ${data.year}',
                            onRingTap: (i) => setState(() {
                              _selectionTouched = true;
                              _selected = _selected == i && selected == i
                                  ? null
                                  : i;
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Legend(data: data),
                      ],
                    ),
                  ),
                ),
                for (final n in yearNotices(data))
                  InfoNotice(
                    icon: n.icon,
                    text: n.text,
                    onTap: () => showHowYearIsCounted(context, data),
                  ),
                if (selected != null && selected < data.rings.length) ...[
                  const SizedBox(height: 12),
                  _RingDetail(data: data, ring: data.rings[selected]),
                ],
                if (data.mode == RingMode.years) ..._loopFor(data, selected),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The light-and-laying card for the selected year (or the latest one).
List<Widget> _loopFor(YearRingsData data, int? selected) {
  final i = selected ?? data.rings.length - 1;
  // indexWhere returns -1 when the year has no ring; the range check covers it.
  if (i < 0 || i >= data.rings.length) return const [];
  final ring = data.rings[i];
  final loop = buildLightLayingLoop(ring, data.weeklyDaylight);
  final year = int.tryParse(ring.id);
  // Near the equator day length barely changes, so there's no loop to show.
  if (loop == null || year == null || !loop.hasDaylightSwing) return const [];
  return [
    const SizedBox(height: 12),
    LightLayingLoopCard(
      loop: loop,
      year: year,
      isCurrentYear: year == data.today.year,
    ),
  ];
}

class _Legend extends StatelessWidget {
  final YearRingsData data;
  const _Legend({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final rate = data.colorScale == RingColorScale.layRate;

    Widget swatch(Color c) => Container(width: 10, height: 10, color: c);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rate ? '0% ' : 'Fewer ', style: style),
            for (final t in const [0.0, 0.25, 0.5, 0.75, 1.0])
              swatch(YearRingsChart.blockColor(scheme, t)),
            // Flexible so large text wraps instead of overflowing.
            Flexible(
              child: Text(
                rate
                    ? ' ${(kFullLayRate * 100).round()}% lay rate'
                    : ' more eggs a day',
                style: style,
              ),
            ),
          ],
        ),
        if (data.mode == RingMode.years && data.maxHens > 0)
          Text('Thicker = more hens', style: style),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 10,
              decoration: BoxDecoration(
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: Text(' Ahead', style: style)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 2, color: YearRingsChart.todayColor),
            Flexible(child: Text(' Today', style: style)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 4,
              color: YearRingsChart.daylightColor.withValues(alpha: 0.8),
            ),
            Flexible(child: Text(' Daylight', style: style)),
          ],
        ),
      ],
    );
  }
}

class _RingDetail extends StatelessWidget {
  final YearRingsData data;
  final RingSeries ring;
  const _RingDetail({required this.data, required this.ring});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.decimalPattern();
    final rate = ring.layRate;
    final bird = ring.bird;

    final stats = <(String, String)>[
      ('Eggs', fmt.format(ring.eggs)),
      if (data.colorScale == RingColorScale.layRate && rate != null)
        ('Lay rate', '${(rate * 100).round()}%')
      else
        ('Per day', ring.eggsPerDay.toStringAsFixed(1)),
      if (data.mode == RingMode.years && ring.henDays > 0)
        ('Avg hens', ring.averageHens.toStringAsFixed(1)),
      ('Days counted', fmt.format(ring.knownDays)),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showRingMath(context, data, ring),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ring.label, style: theme.textTheme.titleLarge),
                  ),
                  if (bird != null)
                    Text(
                      bird.status.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calculate_outlined,
                    size: 20,
                    semanticLabel: 'Show the sums',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (label, value) in stats)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            value,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyYear extends StatelessWidget {
  const _EmptyYear();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.egg_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('No eggs logged yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Your year fills in, week by week, as you log.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

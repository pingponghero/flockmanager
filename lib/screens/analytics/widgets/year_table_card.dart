import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/year_rings.dart';
import 'year_info_sheets.dart';

/// The years side by side under the rings (#1): one row per year plus an
/// "All" row. Tapping a row selects that year's ring, as tapping the ring
/// does. When large text leaves no room for four number columns, Avg hens
/// and Days drop out (the sums sheet still has them).
class YearTableCard extends StatelessWidget {
  final YearRingsData data;
  final int? selected;
  final ValueChanged<int> onSelect;

  const YearTableCard({
    super.key,
    required this.data,
    required this.selected,
    required this.onSelect,
  });

  static final _fmt = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rings = data.rings;
    final all = RingSeries.combined('All', rings);
    final byRate = data.colorScale == RingColorScale.layRate;

    String rate(RingSeries r) {
      final v = r.layRate;
      if (byRate) return v == null ? '–' : '${(v * 100).round()}%';
      return r.eggsPerDay.toStringAsFixed(1);
    }

    final columns = <_Column>[
      _Column('Eggs', (r) => _fmt.format(r.eggs)),
      _Column(byRate ? 'Lay rate' : 'Per day', rate),
      if (data.maxHens > 0)
        _Column(
          'Avg hens',
          (r) => r.henDays > 0 ? r.averageHens.toStringAsFixed(1) : '–',
        ),
      _Column('Days', (r) => _fmt.format(r.knownDays)),
    ];

    final valueStyle = theme.textTheme.bodyLarge?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final boldValue = valueStyle?.copyWith(fontWeight: FontWeight.w700);
    final headerStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final note = _partYearNote(byRate ? 'lay rate' : 'eggs per day');
    final sel = selected != null && selected! < rings.length ? selected : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            double measure(String text, TextStyle? style) {
              final p = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: Directionality.of(context),
                textScaler: scaler,
                maxLines: 1,
              )..layout();
              return p.width;
            }

            double widthOf(_Column c) => [
              measure(c.header, headerStyle),
              for (final r in [...rings, all]) measure(c.value(r), boldValue),
            ].reduce((a, b) => a > b ? a : b);

            const gap = 12.0, rowPad = 12.0;
            final yearWidth = [
              for (final r in rings) measure(r.label, boldValue),
              measure(all.label, boldValue),
            ].reduce((a, b) => a > b ? a : b);
            final available = constraints.maxWidth - 2 * rowPad - yearWidth;
            final widths = columns.map(widthOf).toList();
            var shown = columns.length;
            double need(int n) =>
                widths.take(n).fold(0.0, (s, w) => s + w + gap);
            // Eggs and the rate always stay; the rest go if they don't fit.
            while (shown > 2 && need(shown) > available) {
              shown--;
            }
            final cols = columns.take(shown).toList();
            // At the very largest sizes even two columns can be too wide:
            // share out the room and let the numbers shrink to fit.
            if (need(shown) > available) {
              final room = (available - gap * shown).clamp(
                0.0,
                double.infinity,
              );
              final total = widths.take(shown).fold(0.0, (s, w) => s + w);
              for (var i = 0; i < shown; i++) {
                widths[i] = widths[i] * room / total;
              }
            }

            Widget row(RingSeries r, {required bool bold}) {
              final style = bold ? boldValue : valueStyle;
              return Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(r.label, style: style, maxLines: 1),
                    ),
                  ),
                  for (var i = 0; i < cols.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: gap),
                      child: SizedBox(
                        width: widths[i],
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            cols[i].value(r),
                            style: style,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: rowPad, right: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Year by year',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (sel != null)
                        IconButton(
                          icon: const Icon(Icons.calculate_outlined),
                          tooltip: 'Show the sums for ${rings[sel].label}',
                          color: scheme.onSurfaceVariant,
                          onPressed: () =>
                              showRingMath(context, data, rings[sel]),
                        )
                      else
                        const SizedBox(height: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(rowPad, 0, rowPad, 4),
                  child: Row(
                    children: [
                      const Spacer(),
                      for (var i = 0; i < cols.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: gap),
                          child: SizedBox(
                            width: widths[i],
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                cols[i].header,
                                style: headerStyle,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var i = 0; i < rings.length; i++)
                  Semantics(
                    selected: i == sel,
                    button: true,
                    child: Material(
                      color: i == sel
                          ? scheme.primary.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelect(i),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: rowPad,
                              vertical: 8,
                            ),
                            child: row(rings[i], bold: i == sel),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (rings.length > 1) ...[
                  Divider(
                    height: 9,
                    indent: rowPad,
                    endIndent: rowPad,
                    color: scheme.outlineVariant,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: rowPad,
                      vertical: 8,
                    ),
                    child: row(all, bold: true),
                  ),
                ],
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(rowPad, 4, rowPad, 0),
                    child: Text(note, style: headerStyle),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// "Compare lay rate: 2024 started in April and 2026 is still going."
  String? _partYearNote(String measure) {
    final rings = data.rings;
    if (rings.length < 2) return null;
    final parts = <String>[];
    final first = rings.first;
    final firstWeek = first.blocks
        .where((b) => b.state != RingBlockState.empty)
        .map((b) => b.week)
        .fold<int?>(null, (m, w) => m == null || w < m ? w : m);
    final firstYear = int.tryParse(first.id);
    if (firstWeek != null && firstWeek >= 4 && firstYear != null) {
      final start = DateTime(firstYear, 1, 1 + firstWeek * 7);
      parts.add('${first.label} started in ${DateFormat.MMMM().format(start)}');
    }
    if (rings.last.id == '${data.today.year}') {
      parts.add('${rings.last.label} is still going');
    }
    if (parts.isEmpty) return null;
    return 'Compare $measure: ${parts.join(' and ')}.';
  }
}

class _Column {
  final String header;
  final String Function(RingSeries) value;
  const _Column(this.header, this.value);
}

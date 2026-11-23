import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/status_colors.dart';
import '../../../providers/forecast_provider.dart';

/// Month-by-month forecast table in the forecast details sheet.
class MonthlyForecastTable extends StatelessWidget {
  final ForecastResult forecast;
  final List<String> monthNames;
  final int currentMonth;

  const MonthlyForecastTable({
    super.key,
    required this.forecast,
    required this.monthNames,
    required this.currentMonth,
  });

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final header = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.bold,
    );
    final cell = theme.textTheme.bodyMedium?.copyWith(fontFeatures: _tabular);
    final muted = theme.textTheme.bodySmall?.copyWith(fontFeatures: _tabular);
    final divider = BorderSide(color: theme.dividerColor);

    Widget pad(Widget child, {bool first = false}) => Padding(
          padding: EdgeInsets.only(left: first ? 0 : 12, top: 6, bottom: 6),
          child: child,
        );

    Widget right(String text, TextStyle? style) =>
        Text(text, textAlign: TextAlign.right, style: style);

    final forecastStyle = cell?.copyWith(
      fontStyle: FontStyle.italic,
      color: StatusColors.of(context).warning.onContainerMuted,
    );

    // Source (actual / this month / forecast) is shown by how the egg count
    // is styled plus a legend, rather than a fourth text column that pushed
    // the table off narrow screens at large text sizes (#70).
    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(border: Border(bottom: divider)),
        children: [
          pad(Text('Month', style: header), first: true),
          pad(right('Eggs', header)),
          pad(right('Rate', header)),
          pad(right('Light', header)),
        ],
      ),
      for (final m in forecast.monthlyForecasts)
        () {
          final isPast = m.month < currentMonth;
          final isCurrent = m.month == currentMonth;
          final eggs = isPast ? m.actualEggs : m.forecastEggs;
          final eggStyle = isPast
              ? cell
              : isCurrent
                  ? cell?.copyWith(fontWeight: FontWeight.bold)
                  : forecastStyle;
          return TableRow(children: [
            pad(
              Text(
                monthNames[m.month - 1],
                style: isCurrent
                    ? cell?.copyWith(fontWeight: FontWeight.bold)
                    : cell,
              ),
              first: true,
            ),
            pad(right('$eggs', eggStyle)),
            pad(right(
                m.perHenRate > 0 ? m.perHenRate.toStringAsFixed(2) : '-',
                muted)),
            pad(right('${m.daylightHours.toStringAsFixed(1)}h', muted)),
          ]);
        }(),
      TableRow(
        decoration: BoxDecoration(border: Border(top: divider)),
        children: [
          pad(Text('Total', style: header), first: true),
          pad(right(
            NumberFormat('#,###').format(forecast.projectedYear),
            cell?.copyWith(fontWeight: FontWeight.bold),
          )),
          const SizedBox.shrink(),
          const SizedBox.shrink(),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {
            // Month absorbs any squeeze so the numbers never wrap
            0: FlexColumnWidth(),
            1: IntrinsicColumnWidth(),
            2: IntrinsicColumnWidth(),
            3: IntrinsicColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall,
            children: [
              const TextSpan(text: 'Eggs: actual · '),
              TextSpan(
                text: 'this month',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' · '),
              TextSpan(
                text: 'forecast',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: StatusColors.of(context).warning.onContainerMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../providers/year_rings_provider.dart';
import '../../../utils/year_rings.dart';
import '../../../widgets/year_rings_chart.dart';

/// Stats entry point for the year view (#1): a small ring preview that opens
/// the full screen. It follows the flock filter but not the period selector,
/// since the rings always show whole years.
class YearRingsCard extends ConsumerWidget {
  const YearRingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(yearRingsProvider((mode: null, year: null))).value;
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final fmt = NumberFormat.decimalPattern();
    final current = data.mode == RingMode.years ? data.rings.last : null;
    final eggsThisYear = current?.eggs ?? data.rings.fold<int>(0, (s, r) => s + r.eggs);
    final subtitle = data.mode == RingMode.hens
        ? '${data.rings.length} hens, week by week'
        : data.rings.length > 1
            ? 'Every week since ${data.rings.first.label}'
            : 'Every week of ${data.year}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/analytics/year'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 96,
                child: ExcludeSemantics(
                  child: YearRingsChart(
                    data: data,
                    showLabels: false,
                    selected: current == null ? null : data.rings.length - 1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your year', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${data.year} · ${fmt.format(eggsThisYear)} eggs so far',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

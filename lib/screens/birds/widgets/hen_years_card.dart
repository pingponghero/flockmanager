import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/bird.dart';
import '../../../providers/year_rings_provider.dart';
import '../../../widgets/chart_center_text.dart';
import '../../../widgets/year_rings_chart.dart';

/// A hen's own years as rings, at the top of her Eggs tab (#1): one ring
/// per year she was in the flock, one block per week, coloured by her lay
/// rate. Hidden until there's something to draw.
class HenYearsCard extends ConsumerWidget {
  final Bird bird;
  const HenYearsCard({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(henYearRingsProvider(bird.id)).value;
    // Mostly flock totals: her ring would only show the few eggs logged to
    // her by name and make a good layer look idle, so leave it out.
    if (data == null ||
        data.isEmpty ||
        !data.henRingsMeaningful ||
        data.rings.every((r) => r.knownDays == 0)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final fmt = NumberFormat.decimalPattern();
    final latest = data.rings.last;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${bird.name}’s year', style: theme.textTheme.titleMedium),
            Text('One block per week, darker when she laid more', style: muted),
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: YearRingsChart(
                    data: data,
                    selected: data.rings.length > 1 ? data.rings.length - 1 : null,
                    centerValue: formatCenterCount(latest.eggs),
                    centerLabel: 'eggs in ${latest.label}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final ring in data.rings.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 48, child: Text(ring.label, style: theme.textTheme.bodyMedium)),
                    Expanded(
                      child: Text(
                        '${fmt.format(ring.eggs)} eggs'
                        '${ring.layRate != null ? ' · ${(ring.layRate! * 100).round()}% lay rate' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/bird.dart';
import '../../../models/enums.dart';
import '../../../providers/egg_provider.dart';
import '../../../widgets/stat_card.dart';

/// Stats row showing egg counts and age for a bird
class BirdStatsRow extends ConsumerWidget {
  final Bird bird;

  const BirdStatsRow({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalEggCountByBirdProvider(bird.id));
    final logsAsync = ref.watch(eggLogsByBirdProvider(bird.id));

    final now = DateTime.now();
    final isActive = bird.status == BirdStatus.active;

    int thisMonthCount = 0;

    if (logsAsync.hasValue) {
      final logs = logsAsync.value!;

      if (isActive) {
        final monthStart = DateTime(now.year, now.month, 1);
        for (final log in logs) {
          if (log.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
            thisMonthCount += log.count;
          }
        }
      }
    }

    final (ageLabel, ageValue) = birdAgeStat(bird);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatCard(
                label: 'Total Eggs',
                value: totalAsync.when(
                  loading: () => '--',
                  error: (_, _) => '--',
                  data: (count) => '$count',
                ),
                icon: const Icon(Icons.egg),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'This Month',
                  value: logsAsync.when(
                    loading: () => '--',
                    error: (_, _) => '--',
                    data: (_) => '$thisMonthCount',
                  ),
                  icon: const Icon(Icons.calendar_month),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: ageLabel,
                value: ageValue,
                icon: const Icon(Icons.cake_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The third bird-detail stat (#63). It used to read "Since: <year the
/// record was created>", which looked like a hatch year. Prefer the bird's
/// real age, then when it joined the flock, and only then when it was added
/// to the app — and label each honestly.
(String, String) birdAgeStat(Bird bird, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final hatch = bird.hatchDate;
  if (hatch != null) {
    final days = today.difference(hatch).inDays;
    if (days < 7 * 16) return ('Age', '${days ~/ 7} wk');
    final months = (today.year - hatch.year) * 12 +
        today.month -
        hatch.month -
        (today.day < hatch.day ? 1 : 0);
    if (months < 24) return ('Age', '$months mo');
    final years = months ~/ 12;
    final rem = months % 12;
    return ('Age', rem == 0 ? '${years}y' : '${years}y ${rem}m');
  }
  if (bird.acquiredDate != null) {
    return ('With you since', '${bird.acquiredDate!.year}');
  }
  return ('Added', '${bird.createdAt.year}');
}

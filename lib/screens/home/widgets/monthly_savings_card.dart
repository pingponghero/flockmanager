import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/egg_value_provider.dart';

class MonthlySavingsCard extends ConsumerWidget {
  const MonthlySavingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggValueAsync = ref.watch(monthEggValueProvider);

    return eggValueAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.eggCount == 0) return const SizedBox.shrink();

        final netSavings = summary.netSavings;
        final isPositive = netSavings >= 0;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return GestureDetector(
          onTap: () => context.go('/expenses'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.egg,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '\$${netSavings.abs().toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                        ),
                        TextSpan(
                          text: isPositive
                              ? ' saved vs. store this month'
                              : ' more than store this month',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

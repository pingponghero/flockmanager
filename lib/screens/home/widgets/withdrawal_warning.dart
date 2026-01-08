import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/medication_provider.dart';

/// Warning banner when medication withdrawal periods are active
class WithdrawalWarning extends ConsumerWidget {
  const WithdrawalWarning({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(activeWithdrawalsProvider);

    return withdrawalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (withdrawals) {
        if (withdrawals.isEmpty) return const SizedBox(height: 8);

        // Find the soonest withdrawal end
        int? minDays;
        for (final w in withdrawals) {
          final days = w.withdrawalDaysRemaining;
          if (days != null && (minDays == null || days < minDays)) {
            minDays = days;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => context.go('/settings/medications'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Egg Withdrawal Active',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          minDays != null && minDays > 0
                              ? '$minDays days remaining'
                              : 'Ends today',
                          style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.amber.shade700),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

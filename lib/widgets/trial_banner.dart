import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/trial_provider.dart';
import '../services/iap_service.dart';

/// Banner displayed during trial period or when trial expires.
class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trial = ref.watch(trialProvider);

    // Don't show anything while loading or for premium users
    if (trial.isLoading || trial.status == LicenseStatus.premium) {
      return const SizedBox.shrink();
    }

    if (trial.status == LicenseStatus.trialExpired) {
      return _ExpiredBanner(
        onPurchase: () => _purchasePremium(context, ref),
      );
    }

    // Trial active - show days remaining
    return _TrialActiveBanner(
      daysRemaining: trial.daysRemaining,
    );
  }

  Future<void> _purchasePremium(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(trialProvider.notifier).purchasePremium();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase not available')),
      );
    }
  }
}

class _TrialActiveBanner extends StatelessWidget {
  final int daysRemaining;

  const _TrialActiveBanner({required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    // Only show banner when 7 or fewer days remain
    if (daysRemaining > 7) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              daysRemaining == 1
                  ? '1 day left in trial'
                  : '$daysRemaining days left in trial',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiredBanner extends StatelessWidget {
  final VoidCallback onPurchase;

  const _ExpiredBanner({required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    final iapService = IAPService();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trial expired - Read-only mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPurchase,
              icon: const Icon(Icons.lock_open),
              label: Text('Unlock Full Access - ${iapService.priceString}'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'One-time purchase. No subscription.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
          ),
        ],
      ),
    );
  }
}

/// Widget that blocks editing when trial has expired.
/// Wrap around FABs, add buttons, etc.
class TrialGuard extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onBlocked;

  const TrialGuard({
    super.key,
    required this.child,
    this.onBlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(canEditProvider);

    if (canEdit) {
      return child;
    }

    // Return a grayed out version that shows upgrade dialog
    return GestureDetector(
      onTap: () => _showUpgradeDialog(context, ref),
      child: Opacity(
        opacity: 0.5,
        child: AbsorbPointer(child: child),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    final iapService = IAPService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trial Expired'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your 14-day trial has ended. Unlock full access to continue adding and editing data.',
            ),
            const SizedBox(height: 16),
            Text(
              'Your existing data is safe and viewable.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(trialProvider.notifier).purchasePremium();
            },
            child: Text('Unlock - ${iapService.priceString}'),
          ),
        ],
      ),
    );

    onBlocked?.call();
  }
}

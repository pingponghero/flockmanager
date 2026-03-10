import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/trial_provider.dart';
import '../services/iap_service.dart';
import '../utils/snackbar_utils.dart';

/// Banner displayed during trial period or when trial expires.
class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trial = ref.watch(trialProvider);

    // Don't show anything while loading, for premium users, or before trial starts
    if (trial.isLoading ||
        trial.status == LicenseStatus.premium ||
        trial.status == LicenseStatus.firstLaunch) {
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
      showAppSnackBar(context, 'Purchase not available');
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

    return GestureDetector(
      onTap: () => context.go('/settings'),
      child: Container(
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
                    ? '1 day left in free trial'
                    : '$daysRemaining days left in free trial',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiredBanner extends StatelessWidget {
  final VoidCallback onPurchase;

  const _ExpiredBanner({required this.onPurchase});

  // Barn red color used throughout the app
  static const _barnRed = Color(0xFF9B2D30);

  @override
  Widget build(BuildContext context) {
    final iapService = IAPService();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _barnRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _barnRed.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: _barnRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Free trial ended',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _barnRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You can still view your data, but adding or editing '
              'birds, egg logs, expenses, income, medications, and '
              'health notes is locked.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _barnRed.withValues(alpha: 0.9),
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPurchase,
                style: FilledButton.styleFrom(
                  backgroundColor: _barnRed,
                ),
                icon: const Icon(Icons.arrow_forward),
                label: Text('Unlock Forever - ${iapService.priceString}'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'One-time purchase. No subscription.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _barnRed.withValues(alpha: 0.8),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a friendly trial expired dialog.
/// Call this when user tries to perform an action that requires an active trial.
void showTrialExpiredDialog(BuildContext context, WidgetRef ref) {
  final iapService = IAPService();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/cute_hen.png',
                width: 40,
                height: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Unlock Flock Manager',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Body - clearly list what's restricted
          Text(
            'Your 14-day free trial has ended. You can still view all '
            'your data, but adding or editing birds, egg logs, expenses, '
            'income, medications, and health notes requires unlocking.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock forever for ${iapService.priceString} — that\'s less '
            'than a dozen eggs at the farmers market!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(trialProvider.notifier).purchasePremium();
              },
              child: const Text('Unlock Now'),
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            'One-time purchase. No subscription. Ever.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

/// Shows the first-launch trial onboarding dialog.
/// Clearly communicates: duration, what's lost after, and cost to unlock.
void showTrialOnboardingDialog(BuildContext context, WidgetRef ref) {
  final iapService = IAPService();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/cute_hen.png',
                width: 40,
                height: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Flock Manager!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enjoy a free 14-day trial with full access to all features.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'After the trial, you can still view all your data, '
            'but adding or editing birds, egg logs, expenses, income, '
            'medications, and health notes will require a one-time '
            'purchase of ${iapService.priceString}.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'No subscription. No hidden fees.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(trialProvider.notifier).startTrial();
              },
              child: const Text('Start 14-Day Free Trial'),
            ),
          ),
        ],
      ),
    ),
  );
}

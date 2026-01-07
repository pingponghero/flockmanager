import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/test_data.dart';
import '../../database/database_helper.dart';
import '../../providers/notification_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trial_provider.dart';
import '../../services/export_service.dart';
import '../../services/iap_service.dart';
import '../../utils/edge_insets.dart';

const _supportEmail = 'flockmanager.app@gmail.com';
const _appVersion = '1.0.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPalette = ref.watch(themeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final trial = ref.watch(trialProvider);
    final isPremium = trial.status == LicenseStatus.premium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: pagePadding(context),
        children: [
          // Account Section (only show if not premium)
          if (!isPremium) ...[
            const _AccountSection(),
            const SizedBox(height: 24),
          ],

          // Flock Management Section
          Text(
            'Flock Management',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.grid_view),
                  title: const Text('Manage Flocks'),
                  subtitle: const Text('Add, edit, or archive flocks'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/flocks'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Image.asset(
                    'assets/icons/cute_hen.png',
                    width: 24,
                    height: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Manage Birds'),
                  subtitle: const Text('Add, edit, or update bird status'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/birds'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reference Guides Section
          Text(
            'Reference Guides',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Image.asset(
                    'assets/icons/cute_hen.png',
                    width: 24,
                    height: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Breed Guide'),
                  subtitle: const Text('50 chicken breeds with details'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/breeds'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Medication Reference'),
                  subtitle: const Text('Common treatments & withdrawal periods'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/medications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Achievements Section
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Badges'),
              subtitle: const Text('View your achievements'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/achievements'),
            ),
          ),
          const SizedBox(height: 24),

          // Notifications Section
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          const _NotificationSettingsCard(),
          const SizedBox(height: 24),

          // Appearance Section
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _ThemeModeOption(
                    icon: Icons.settings_brightness,
                    label: 'System',
                    isSelected: currentThemeMode == ThemeMode.system,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                  ),
                  _ThemeModeOption(
                    icon: Icons.light_mode,
                    label: 'Light',
                    isSelected: currentThemeMode == ThemeMode.light,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                  ),
                  _ThemeModeOption(
                    icon: Icons.dark_mode,
                    label: 'Dark',
                    isSelected: currentThemeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Color Palette',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  ...AppPalette.values.map((palette) => _PaletteOption(
                        palette: palette,
                        isSelected: palette == currentPalette,
                        onTap: () {
                          ref.read(themeProvider.notifier).setPalette(palette);
                        },
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Data Section
          Text(
            'Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Download all data as CSV files'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportData(context),
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                // Show premium status in About section for premium users
                if (isPremium) ...[
                  ListTile(
                    leading: Icon(
                      Icons.verified,
                      color: Colors.green.shade600,
                    ),
                    title: const Text('Lifetime Access'),
                    subtitle: const Text('Thank you for your support!'),
                  ),
                  const Divider(height: 1),
                ],
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Flock Manager'),
                  subtitle: Text('Version $_appVersion'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.egg),
                  title: Text('Made for backyard chicken keepers'),
                  subtitle: Text('Track your flock with love'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Questions or feedback?'),
                  subtitle: const Text(_supportEmail),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchEmail(context),
                ),
                // TODO: Re-enable when app tour is ready
                // const Divider(height: 1),
                // ListTile(
                //   leading: const Icon(Icons.play_circle_outline),
                //   title: const Text('Show App Tour'),
                //   subtitle: const Text('Review tips and features'),
                //   trailing: const Icon(Icons.chevron_right),
                //   onTap: () => context.push('/onboarding?tourOnly=true'),
                // ),
              ],
            ),
          ),

          // Developer Section (debug mode only)
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            Text(
              'Developer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Load Test Data'),
                    subtitle: const Text('Populate with sample flocks & eggs'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSeedConfirmation(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restart_alt),
                    title: const Text('Reset Onboarding'),
                    subtitle: const Text('Show welcome flow again'),
                    onTap: () {
                      ref.read(onboardingProvider.notifier).resetOnboarding();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Onboarding reset. Restart app to see it.')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Clear All Data'),
                    subtitle: const Text('Delete database and restart fresh'),
                    onTap: () => _showClearDataConfirmation(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting data...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final exportService = ExportService();
      final zipPath = await exportService.exportToZip();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      // Share the zip file
      await Share.shareXFiles(
        [XFile(zipPath)],
        subject: 'Flock Manager Data Export',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Flock Manager v$_appVersion Feedback',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  void _showSeedConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Test Data?'),
        content: const Text(
          'This will DELETE all existing data and replace it with sample data.\n\n'
          '• 3 flocks\n'
          '• 12 birds\n'
          '• 35 days of egg logs\n'
          '• Expenses & income\n'
          '• Medication records\n\n'
          'This cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await TestData.seedDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test data loaded! Restart app to see changes.'),
                  ),
                );
              }
            },
            child: const Text('Load Data'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently DELETE all data:\n\n'
          '• All flocks\n'
          '• All birds\n'
          '• All egg logs\n'
          '• All expenses & income\n'
          '• All medication records\n\n'
          'This cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteDatabase();
              ref.read(onboardingProvider.notifier).resetOnboarding();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared. Restart app.'),
                  ),
                );
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}

class _PaletteOption extends StatelessWidget {
  final AppPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteOption({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = palette.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            // Color swatches
            Row(
              children: [
                _ColorSwatch(color: colors.primary),
                const SizedBox(width: 4),
                _ColorSwatch(color: colors.surface),
                const SizedBox(width: 4),
                _ColorSwatch(color: colors.accent),
                if (colors.secondary != null) ...[
                  const SizedBox(width: 4),
                  _ColorSwatch(color: colors.secondary!),
                ],
              ],
            ),
            const SizedBox(width: 16),
            // Palette name
            Expanded(
              child: Text(
                palette.displayName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;

  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

class _NotificationSettingsCard extends ConsumerWidget {
  const _NotificationSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return Card(
      child: Column(
        children: [
          // Permission status
          if (!settings.permissionGranted)
            ListTile(
              leading: Icon(
                Icons.notifications_off,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Enable Notifications'),
              subtitle: const Text('Get reminders for medications and withdrawals'),
              trailing: FilledButton(
                onPressed: () async {
                  await ref.read(notificationSettingsProvider.notifier).requestPermission();
                },
                child: const Text('Enable'),
              ),
            )
          else ...[
            // Medication reminders toggle
            SwitchListTile(
              secondary: const Icon(Icons.medication),
              title: const Text('Medication Reminders'),
              subtitle: const Text('When treatments end'),
              value: settings.medicationReminders,
              onChanged: (value) {
                ref.read(notificationSettingsProvider.notifier).setMedicationReminders(value);
              },
            ),
            const Divider(height: 1),
            // Withdrawal alerts toggle
            SwitchListTile(
              secondary: const Icon(Icons.egg),
              title: const Text('Withdrawal Alerts'),
              subtitle: const Text('When eggs are safe to eat'),
              value: settings.withdrawalAlerts,
              onChanged: (value) {
                ref.read(notificationSettingsProvider.notifier).setWithdrawalAlerts(value);
              },
            ),
            const Divider(height: 1),
            // Expense reminders toggle
            SwitchListTile(
              secondary: const Icon(Icons.attach_money),
              title: const Text('Expense Reminders'),
              subtitle: const Text('For recurring expenses'),
              value: settings.expenseReminders,
              onChanged: (value) {
                ref.read(notificationSettingsProvider.notifier).setExpenseReminders(value);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trial = ref.watch(trialProvider);
    final iapService = IAPService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              // Status display
              Builder(
                builder: (context) {
                  final subtitle = _getStatusSubtitle(trial);
                  return ListTile(
                    leading: Icon(
                      trial.status == LicenseStatus.premium
                          ? Icons.verified
                          : trial.status == LicenseStatus.trialExpired
                              ? Icons.lock
                              : Icons.timer,
                      color: trial.status == LicenseStatus.premium
                          ? Colors.green
                          : trial.status == LicenseStatus.trialExpired
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(_getStatusTitle(trial)),
                    subtitle: subtitle != null ? Text(subtitle) : null,
                  );
                },
              ),
              // Actions
              if (trial.status != LicenseStatus.premium) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: const Text('Get Lifetime Access'),
                  subtitle: Text('One-time purchase - ${iapService.priceString}'),
                  trailing: FilledButton(
                    onPressed: () => _purchasePremium(context, ref),
                    child: const Text('Buy'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Purchase'),
                  subtitle: const Text('Already purchased on another device?'),
                  onTap: () => _restorePurchases(context, ref),
                ),
              ],
              // Debug options
              if (kDebugMode) ...[
                const Divider(height: 1),
                ExpansionTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Debug: Trial Controls'),
                  children: [
                    ListTile(
                      title: const Text('Reset Trial'),
                      onTap: () {
                        ref.read(trialProvider.notifier).debugResetTrial();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trial reset')),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text('Expire Trial'),
                      onTap: () {
                        ref.read(trialProvider.notifier).debugExpireTrial();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trial expired')),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text('Grant Lifetime Access'),
                      onTap: () {
                        ref.read(trialProvider.notifier).debugGrantPremium();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lifetime access granted')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusTitle(TrialState trial) {
    switch (trial.status) {
      case LicenseStatus.premium:
        return 'Lifetime Access';
      case LicenseStatus.trialExpired:
        return 'Trial Expired';
      case LicenseStatus.trialActive:
        return 'Free Trial';
    }
  }

  String? _getStatusSubtitle(TrialState trial) {
    switch (trial.status) {
      case LicenseStatus.premium:
        return 'Thank you for your support!';
      case LicenseStatus.trialExpired:
        return null; // Details shown in purchase tile below
      case LicenseStatus.trialActive:
        final days = trial.daysRemaining;
        return days == 1 ? '1 day remaining' : '$days days remaining';
    }
  }

  Future<void> _purchasePremium(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(trialProvider.notifier).purchasePremium();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase not available. Try again later.')),
      );
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    await ref.read(trialProvider.notifier).restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checking for previous purchases...')),
      );
    }
  }
}

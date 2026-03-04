import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/test_data.dart';
import '../../database/database_helper.dart';
import '../../providers/bird_provider.dart' show birdsProvider;
import '../../providers/egg_provider.dart' show autoDistributeEggsProvider, eggLogsProvider;
import '../../providers/egg_value_provider.dart';
import '../../providers/expense_provider.dart' show expensesProvider;
import '../../providers/flock_provider.dart' show flocksProvider, selectedFlockIdProvider;
import '../../providers/medication_provider.dart' show medicationsProvider;
import '../../providers/notification_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trial_provider.dart';
import '../../services/export_service.dart';
import '../../services/iap_service.dart';
import '../../services/import_service.dart';
import '../../services/notification_service.dart';
import '../../utils/edge_insets.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/import_confirmation_dialog.dart';

const _supportEmail = 'flockmanager.app@gmail.com';

/// Provider for app version from package info
final appVersionProvider = FutureProvider<String>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
});

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

          // Egg Logging Section
          Text(
            'Egg Logging',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ref.watch(autoDistributeEggsProvider).when(
                  loading: () => const ListTile(
                    leading: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    title: Text('Auto-distribute eggs'),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (autoDistribute) => SwitchListTile(
                    secondary: const Icon(Icons.egg),
                    title: const Text('Auto-distribute eggs'),
                    subtitle: const Text(
                      'When egg count matches bird count, automatically attribute one egg per bird',
                    ),
                    value: autoDistribute,
                    onChanged: (value) {
                      ref
                          .read(autoDistributeEggsProvider.notifier)
                          .setAutoDistribute(value);
                    },
                  ),
                ),
          ),
          const SizedBox(height: 24),

          // Finances Section
          Text(
            'Finances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          const _RetailPriceCard(),
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Save all flock data and photos as a backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportData(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore from a backup file (replaces all data)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importData(context, ref),
                ),
              ],
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
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Flock Manager'),
                  subtitle: ref.watch(appVersionProvider).when(
                        data: (version) => Text('Version $version'),
                        loading: () => const Text('Version ...'),
                        error: (_, __) => const Text('Version unknown'),
                      ),
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
                  onTap: () => _launchEmail(context, ref),
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
                      showAppSnackBar(context, 'Onboarding reset. Restart app to see it.');
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
    final navigator = Navigator.of(context, rootNavigator: true);
    var dialogOpen = false;

    // Show loading indicator
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
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
    ).then((_) => dialogOpen = false));
    dialogOpen = true;

    // Wait for dialog transition to complete
    await Future.delayed(const Duration(milliseconds: 300));

    void closeDialog() {
      if (dialogOpen && context.mounted) {
        try {
          navigator.pop();
          dialogOpen = false;
        } catch (_) {
          // Dialog may have already been closed
        }
      }
    }

    try {
      final exportService = ExportService();
      final zipPath = await exportService.exportToZip();

      closeDialog();

      // Share the zip file
      await Share.shareXFiles(
        [XFile(zipPath)],
        subject: 'Flock Manager Data Export',
      );
    } catch (e) {
      closeDialog();
      if (context.mounted) {
        showAppSnackBar(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    // 1. Show warning dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => const ImportWarningDialog(),
    );

    if (shouldProceed != true || !context.mounted) return;

    // 2. Open file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.isEmpty || !context.mounted) return;

    final filePath = result.files.first.path;
    if (filePath == null) {
      showAppSnackBar(context, 'Could not access the selected file');
      return;
    }

    final zipFile = File(filePath);
    final importService = ImportService();

    // 3. Get preview and show confirmation with counts
    try {
      final preview = await importService.getPreview(zipFile);

      // Check format version
      if (!preview.isSupported) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            'This backup is from a newer version of Flock Manager. Please update the app.',
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Show confirmation dialog with counts
      final confirmImport = await showDialog<bool>(
        context: context,
        builder: (context) => ImportConfirmationDialog(preview: preview),
      );

      if (confirmImport != true || !context.mounted) return;

      // 4. Execute import with progress indicator
      final navigator = Navigator.of(context, rootNavigator: true);
      var dialogOpen = false;
      double progress = 0;

      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return ImportProgressDialog(progress: progress);
          },
        ),
      ).then((_) => dialogOpen = false));
      dialogOpen = true;

      // Wait for dialog transition to complete
      await Future.delayed(const Duration(milliseconds: 300));

      final importResult = await ImportService(
        onProgress: (p) {
          progress = p;
          // Note: We can't easily update the dialog here, but the import is fast
        },
      ).importFromZip(zipFile);

      // Close progress dialog safely
      if (dialogOpen && context.mounted) {
        try {
          navigator.pop();
          dialogOpen = false;
        } catch (_) {
          // Dialog may have already been closed
        }
      }

      // 5. Handle result
      if (importResult.success) {
        // Invalidate all providers
        ref.invalidate(flocksProvider);
        ref.invalidate(birdsProvider);
        ref.invalidate(eggLogsProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(medicationsProvider);
        ref.invalidate(selectedFlockIdProvider);

        // Show result dialog if there are warnings, otherwise just show toast
        if (importResult.hasWarnings) {
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (context) => ImportResultDialog(result: importResult),
            );
          }
        } else {
          if (context.mounted) {
            showAppSnackBar(context, importResult.summaryMessage);
          }
        }

        // Navigate to home
        if (context.mounted) {
          context.go('/');
        }
      } else {
        // Show error
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => ImportResultDialog(result: importResult),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          e is ImportException
              ? e.message
              : "This file isn't a valid backup. Please select a .zip file exported from Flock Manager.",
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context, WidgetRef ref) async {
    final version = await ref.read(appVersionProvider.future).catchError((_) => 'unknown');
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Flock Manager v$version Feedback',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      // Copy email to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: _supportEmail));
      if (context.mounted) {
        showAppSnackBar(context, 'Email copied to clipboard');
      }
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
                showAppSnackBar(context, 'Test data loaded! Restart app to see changes.');
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
                showAppSnackBar(context, 'All data cleared. Restart app.');
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}

class _RetailPriceCard extends ConsumerWidget {
  const _RetailPriceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retailPrice = ref.watch(retailPricePerDozenProvider);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.egg),
        title: const Text('Store Egg Price'),
        subtitle: const Text('Retail price per dozen for comparison'),
        trailing: Text(
          '\$${retailPrice.toStringAsFixed(2)}/doz',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        onTap: () => _showPriceDialog(context, ref, retailPrice),
      ),
    );
  }

  void _showPriceDialog(
      BuildContext context, WidgetRef ref, double currentPrice) {
    final controller = TextEditingController(
      text: currentPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store Egg Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'What does a dozen eggs cost at your local store? Used to calculate the value of your flock\'s production.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                prefixText: '\$ ',
                labelText: 'Price per dozen',
                hintText: '4.50',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                ref.read(retailPricePerDozenProvider.notifier).setPrice(value);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
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
            // Daily egg reminder toggle
            SwitchListTile(
              secondary: const Icon(Icons.access_time),
              title: const Text('Daily Egg Reminder'),
              subtitle: Text(settings.eggReminders && settings.eggReminderTime != null
                  ? 'Remind at ${settings.eggReminderTime!.format(context)}'
                  : 'Remind me to log eggs'),
              value: settings.eggReminders,
              onChanged: (value) async {
                await ref
                    .read(notificationSettingsProvider.notifier)
                    .setEggReminders(value);
              },
            ),
            // Time picker (shown when egg reminders enabled)
            if (settings.eggReminders) ...[
              ListTile(
                leading: const SizedBox(width: 24), // Align with switch
                title: const Text('Reminder Time'),
                trailing: TextButton(
                  onPressed: () => _pickEggReminderTime(context, ref, settings.eggReminderTime),
                  child: Text(
                    settings.eggReminderTime?.format(context) ?? '6:00 PM',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
            const Divider(height: 1),
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

  Future<void> _pickEggReminderTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay? currentTime,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      ref.read(notificationSettingsProvider.notifier).setEggReminderTime(picked);
    }
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
                        showAppSnackBar(context, 'Trial reset');
                      },
                    ),
                    ListTile(
                      title: const Text('Expire Trial'),
                      onTap: () {
                        ref.read(trialProvider.notifier).debugExpireTrial();
                        showAppSnackBar(context, 'Trial expired');
                      },
                    ),
                    ListTile(
                      title: const Text('Grant Lifetime Access'),
                      onTap: () {
                        ref.read(trialProvider.notifier).debugGrantPremium();
                        showAppSnackBar(context, 'Lifetime access granted');
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
      showAppSnackBar(context, 'Purchase not available. Try again later.');
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    await ref.read(trialProvider.notifier).restorePurchases();
    if (context.mounted) {
      showAppSnackBar(context, 'Checking for previous purchases...');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/test_data.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPalette = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  leading: const Icon(Icons.flutter_dash),
                  title: const Text('Breed Guide'),
                  subtitle: const Text('50 chicken breeds with details'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/breeds'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Medication Reference'),
                  subtitle: const Text('Common treatments & withdrawal periods'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/medications'),
                ),
              ],
            ),
          ),
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
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Flock Manager'),
                  subtitle: const Text('Version 1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.egg),
                  title: const Text('Made for backyard chicken keepers'),
                  subtitle: const Text('Track your flock with love'),
                ),
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
            // Palette info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    palette.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    palette.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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

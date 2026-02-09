import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/egg_log.dart';
import '../models/enums.dart';
import '../providers/achievements_provider.dart';
import '../providers/bird_provider.dart';
import '../providers/egg_provider.dart';
import '../providers/flock_provider.dart';
import '../utils/distribution_helper.dart';
import 'achievement_celebration_dialog.dart';
import 'distribute_eggs_dialog.dart';

/// Shows the quick egg log bottom sheet.
/// Returns the created EggLog if logged, null otherwise.
Future<EggLog?> showEggQuickLog(BuildContext context) async {
  final result = await showModalBottomSheet<EggLog?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const EggQuickLogSheet(),
  );
  return result;
}

/// Quick egg logging bottom sheet.
/// Designed for fast, 2-tap logging: open sheet, tap save.
class EggQuickLogSheet extends ConsumerStatefulWidget {
  const EggQuickLogSheet({super.key});

  @override
  ConsumerState<EggQuickLogSheet> createState() => _EggQuickLogSheetState();
}

class _EggQuickLogSheetState extends ConsumerState<EggQuickLogSheet> {
  int _count = 0;
  String? _selectedFlockId;
  DateTime _date = DateTime.now();
  String? _selectedBirdId;
  EggSize? _selectedSize;
  EggQuality? _selectedQuality;
  String? _notes;
  bool _showAdvanced = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Initialize defaults
    if (!_isInitialized) {
      _initializeDefaults();
    }

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Eggs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Scrollable content area
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flock selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _FlockSelector(
                        selectedFlockId: _selectedFlockId,
                        onChanged: (flockId) => setState(() => _selectedFlockId = flockId),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Number picker (hide when keyboard is open to save space)
                    if (!isKeyboardOpen) ...[
                      _NumberPicker(
                        value: _count,
                        onChanged: (value) => setState(() => _count = value),
                        compact: _showAdvanced,
                      ),
                      const SizedBox(height: 16),
                      // Date indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _DateIndicator(
                          date: _date,
                          onTap: _selectDate,
                        ),
                      ),
                    ],
                    // Advanced options toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                        icon: Icon(
                          _showAdvanced ? Icons.expand_less : Icons.expand_more,
                        ),
                        label: Text(_showAdvanced ? 'Less options' : 'More options'),
                      ),
                    ),
                    // Advanced options
                    if (_showAdvanced)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bird selector (optional - attribute to specific bird)
                            _BirdSelector(
                              flockId: _selectedFlockId,
                              selectedBirdId: _selectedBirdId,
                              onChanged: (birdId) => setState(() => _selectedBirdId = birdId),
                            ),
                            const SizedBox(height: 12),
                            // Size chips
                            Text('Size', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: EggSize.values.map((size) {
                                final isSelected = _selectedSize == size;
                                return ChoiceChip(
                                  label: Text(
                                    size.displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: Theme.of(context).colorScheme.primary,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSize = selected ? size : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            // Quality chips
                            Text('Quality', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: EggQuality.values.map((quality) {
                                final isSelected = _selectedQuality == quality;
                                return ChoiceChip(
                                  label: Text(
                                    quality.displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: Theme.of(context).colorScheme.primary,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedQuality = selected ? quality : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            // Notes field
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                hintText: 'Optional notes...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              onChanged: (value) => _notes = value.isEmpty ? null : value,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading || _selectedFlockId == null
                      ? null
                      : _saveEggLog,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _count == 0 ? 'Save (No Eggs)' : 'Save $_count ${_count == 1 ? 'Egg' : 'Eggs'}',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ),
            // Bottom padding for gesture navigation area
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  void _initializeDefaults() {
    _isInitialized = true;

    // Check flocks first - if only one exists, always use it
    final flocksAsync = ref.read(flocksProvider);
    final flocks = flocksAsync.value ?? [];

    if (flocks.length == 1) {
      // Single flock - always auto-select it
      _selectedFlockId = flocks.first.id;
      return;
    }

    // Multiple flocks: try selected flock, then last logged flock
    final selectedFlockId = ref.read(selectedFlockIdProvider);
    if (selectedFlockId != null) {
      _selectedFlockId = selectedFlockId;
    } else {
      // Try to get last logged flock
      ref.read(lastLoggedFlockIdProvider.future).then((flockId) {
        if (mounted && flockId != null && _selectedFlockId == null) {
          setState(() => _selectedFlockId = flockId);
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _saveEggLog() async {
    if (_selectedFlockId == null) return;

    setState(() => _isLoading = true);

    try {
      // Check if distribution should be offered (only if no specific bird selected)
      if (_selectedBirdId == null && _count > 0) {
        final allActiveBirds = await ref.read(
          activeBirdsByFlockProvider(_selectedFlockId!).future,
        );
        final activeBirds = allActiveBirds.where((b) => b.isEggProducer).toList();

        if (shouldOfferDistribution(
          eggCount: _count,
          activeBirds: activeBirds,
          selectedFlockId: _selectedFlockId,
        )) {
          // Check if auto-distribute is enabled
          final autoDistribute = await ref.read(autoDistributeEggsProvider.future);

          Map<String, int>? distribution;

          if (autoDistribute) {
            // Auto-distribute without prompt
            distribution = {for (final bird in activeBirds) bird.id: 1};
          } else {
            // Show distribution dialog
            distribution = await showDialog<Map<String, int>>(
              context: context,
              builder: (context) => DistributeEggsDialog(
                eggCount: _count,
                birds: activeBirds,
              ),
            );
          }

          if (distribution != null) {
            // User chose to distribute
            await ref.read(eggLogsProvider.notifier).addDistributedEggLogs(
              date: DateTime(_date.year, _date.month, _date.day),
              flockId: _selectedFlockId!,
              distribution: distribution,
              size: _selectedSize,
              quality: _selectedQuality,
              notes: _notes,
            );

            // Haptic feedback
            HapticFeedback.mediumImpact();

            if (mounted) {
              // Check for new achievements
              final newAchievements = await checkAndCelebrateAchievements(ref, context);

              if (mounted && newAchievements.isNotEmpty) {
                await AchievementCelebrationDialog.showMultiple(context, newAchievements);
                await markAchievementsAsShown(newAchievements);
              }

              // Show success message with bird names
              if (mounted) {
                final birdNames = activeBirds.map((b) => b.name).join(', ');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Logged $_count eggs (1 each to $birdNames)',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context, null); // Return null since we handled the snackbar
              }
            }
            return;
          }
          // User tapped "Skip" — fall through to normal save
        }
      }

      // Normal save (single egg log)
      final log = EggLog.create(
        date: DateTime(_date.year, _date.month, _date.day),
        flockId: _selectedFlockId!,
        birdId: _selectedBirdId,
        count: _count,
        size: _selectedSize,
        quality: _selectedQuality,
        notes: _notes,
      );

      await ref.read(eggLogsProvider.notifier).addEggLog(log);

      // Haptic feedback
      HapticFeedback.mediumImpact();

      if (mounted) {
        // Check for new achievements BEFORE closing sheet (context becomes invalid after pop)
        final newAchievements = await checkAndCelebrateAchievements(ref, context);

        // Show celebration dialog BEFORE closing sheet (context is still valid)
        if (mounted && newAchievements.isNotEmpty) {
          await AchievementCelebrationDialog.showMultiple(context, newAchievements);
          // Mark as shown AFTER dialog is displayed
          await markAchievementsAsShown(newAchievements);
        }

        // Close sheet and return the created log (caller will show snackbar)
        if (mounted) Navigator.pop(context, log);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Flock selector dropdown for quick log.
/// Auto-selects and hides when only one flock exists.
class _FlockSelector extends ConsumerWidget {
  final String? selectedFlockId;
  final ValueChanged<String?> onChanged;

  const _FlockSelector({
    required this.selectedFlockId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flocksAsync = ref.watch(flocksProvider);

    return flocksAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (flocks) {
        if (flocks.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Create a flock first')),
                ],
              ),
            ),
          );
        }

        // Single flock: auto-select and show as simple label (no dropdown)
        if (flocks.length == 1) {
          final flock = flocks.first;
          // Ensure it's selected
          if (selectedFlockId != flock.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onChanged(flock.id);
            });
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  flock.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // Multiple flocks: show dropdown
        return DropdownButtonFormField<String>(
          value: selectedFlockId,
          decoration: const InputDecoration(
            labelText: 'Flock',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: flocks.map((flock) {
            return DropdownMenuItem(
              value: flock.id,
              child: Text(flock.name),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

/// Large number picker for egg count.
class _NumberPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool compact;

  const _NumberPicker({
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  static const int _min = 0;
  static const int _max = 99;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 48.0 : 80.0;
    final buttonSize = compact ? 48.0 : 64.0;
    final smallButtonSize = compact ? 40.0 : 48.0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          // Count display
          Text(
            '$value',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (!compact)
            Text(
              value == 1 ? 'egg' : 'eggs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          SizedBox(height: compact ? 8 : 16),
          // Increment/decrement buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrement by 5
              _CountButton(
                icon: Icons.remove,
                label: '-5',
                onPressed: value >= 5 ? () => onChanged(value - 5) : null,
                size: smallButtonSize,
              ),
              const SizedBox(width: 8),
              // Decrement by 1
              _CountButton(
                icon: Icons.remove,
                onPressed: value > _min ? () => onChanged(value - 1) : null,
                size: buttonSize,
              ),
              const SizedBox(width: 16),
              // Increment by 1
              _CountButton(
                icon: Icons.add,
                onPressed: value < _max ? () => onChanged(value + 1) : null,
                size: buttonSize,
                isPrimary: true,
              ),
              const SizedBox(width: 8),
              // Increment by 5
              _CountButton(
                icon: Icons.add,
                label: '+5',
                onPressed: value <= _max - 5 ? () => onChanged(value + 5) : null,
                isPrimary: true,
                size: smallButtonSize,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Button for incrementing/decrementing count.
class _CountButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final double size;
  final bool isPrimary;

  const _CountButton({
    required this.icon,
    this.label,
    this.onPressed,
    this.size = 48,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: isPrimary
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onPressed == null
                          ? colorScheme.onSurface.withValues(alpha: 0.38)
                          : isPrimary
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    icon,
                    size: size * 0.4,
                    color: onPressed == null
                        ? colorScheme.onSurface.withValues(alpha: 0.38)
                        : isPrimary
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Shows today's date with optional tap to change.
class _DateIndicator extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;

  const _DateIndicator({
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = 'Today';
    } else if (dateOnly == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat.MMMd().format(date);
    }

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional bird selector for attributing eggs to a specific bird.
class _BirdSelector extends ConsumerWidget {
  final String? flockId;
  final String? selectedBirdId;
  final ValueChanged<String?> onChanged;

  const _BirdSelector({
    required this.flockId,
    required this.selectedBirdId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (flockId == null) {
      return const SizedBox.shrink();
    }

    final birdsAsync = ref.watch(birdsByFlockProvider(flockId!));

    return birdsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (birds) {
        final activeBirds = birds.where((b) => b.isEggProducer).toList();

        if (activeBirds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attribute to bird (optional)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: selectedBirdId,
              decoration: const InputDecoration(
                hintText: 'Any bird',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Any bird'),
                ),
                ...activeBirds.map((bird) => DropdownMenuItem<String?>(
                      value: bird.id,
                      child: Text(bird.name),
                    )),
              ],
              onChanged: onChanged,
            ),
          ],
        );
      },
    );
  }
}

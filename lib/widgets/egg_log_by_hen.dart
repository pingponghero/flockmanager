import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/breeds.dart';
import '../models/bird.dart';
import '../models/enums.dart';
import '../providers/achievements_provider.dart';
import '../providers/bird_provider.dart';
import '../providers/egg_provider.dart';
import '../providers/flock_provider.dart';
import 'achievement_celebration_dialog.dart';

/// Per-hen egg logging UI.
/// Shows a list of active hens with +/− counters to attribute eggs individually.
class EggLogByHenContent extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToQuickLog;

  const EggLogByHenContent({super.key, required this.onSwitchToQuickLog});

  @override
  ConsumerState<EggLogByHenContent> createState() =>
      _EggLogByHenContentState();
}

class _EggLogByHenContentState extends ConsumerState<EggLogByHenContent> {
  DateTime _date = DateTime.now();
  final Map<String, int> _counts = {}; // birdId -> egg count
  bool _isSaving = false;

  int get _totalEggs => _counts.values.fold(0, (a, b) => a + b);
  int get _hensWithEggs => _counts.values.where((c) => c > 0).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFlockId = ref.watch(selectedFlockIdProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Log by Hen', style: theme.textTheme.titleLarge),
              IconButton(
                onPressed: () => Navigator.pop(context, null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        // Switch back link
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onSwitchToQuickLog,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Quick log'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
        // Date picker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _DateChip(date: _date, onTap: _selectDate),
        ),
        // Hen list
        Flexible(
          child: selectedFlockId != null
              ? _SingleFlockHenList(
                  flockId: selectedFlockId,
                  counts: _counts,
                  onCountChanged: _setCount,
                )
              : _AllFlocksHenList(
                  counts: _counts,
                  onCountChanged: _setCount,
                ),
        ),
        // Sticky footer
        _StickyFooter(
          totalEggs: _totalEggs,
          isSaving: _isSaving,
          onSave: _totalEggs > 0 ? _saveAll : null,
        ),
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
      ],
    );
  }

  void _setCount(String birdId, int count) {
    setState(() {
      if (count <= 0) {
        _counts.remove(birdId);
      } else {
        _counts[birdId] = count;
      }
    });
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

  Future<void> _saveAll() async {
    final selectedFlockId = ref.read(selectedFlockIdProvider);

    // Build distribution: birdId -> count (skip zeros)
    final distribution = Map<String, int>.from(_counts)
      ..removeWhere((_, v) => v <= 0);

    if (distribution.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Determine flock ID per bird. If a single flock is selected, use it.
      // If "All Flocks", group by flock and make one call per flock.
      if (selectedFlockId != null) {
        await ref.read(eggLogsProvider.notifier).addDistributedEggLogs(
              date: DateTime(_date.year, _date.month, _date.day),
              flockId: selectedFlockId,
              distribution: distribution,
            );
      } else {
        // Need to look up each bird's flockId and group
        final allHens = await ref.read(allActiveHensProvider.future);
        final birdMap = {for (final b in allHens) b.id: b};
        final byFlock = <String, Map<String, int>>{};

        for (final entry in distribution.entries) {
          final bird = birdMap[entry.key];
          if (bird != null) {
            byFlock.putIfAbsent(bird.flockId, () => {});
            byFlock[bird.flockId]![entry.key] = entry.value;
          }
        }

        for (final flockEntry in byFlock.entries) {
          await ref.read(eggLogsProvider.notifier).addDistributedEggLogs(
                date: DateTime(_date.year, _date.month, _date.day),
                flockId: flockEntry.key,
                distribution: flockEntry.value,
              );
        }
      }

      HapticFeedback.mediumImpact();

      if (mounted) {
        final newAchievements =
            await checkAndCelebrateAchievements(ref, context);

        if (mounted && newAchievements.isNotEmpty) {
          await AchievementCelebrationDialog.showMultiple(
              context, newAchievements);
          await markAchievementsAsShown(newAchievements);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Logged $_totalEggs ${_totalEggs == 1 ? 'egg' : 'eggs'} from $_hensWithEggs ${_hensWithEggs == 1 ? 'hen' : 'hens'}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, null);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}

// ==================== HEN LIST WIDGETS ====================

/// Hen list for a single selected flock.
class _SingleFlockHenList extends ConsumerWidget {
  final String flockId;
  final Map<String, int> counts;
  final void Function(String birdId, int count) onCountChanged;

  const _SingleFlockHenList({
    required this.flockId,
    required this.counts,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birdsAsync = ref.watch(activeBirdsByFlockProvider(flockId));

    return birdsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (birds) {
        final hens = birds.where((b) => b.sex != BirdSex.male).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        if (hens.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No active hens in this flock')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: hens.length,
          itemBuilder: (context, index) {
            final bird = hens[index];
            return _HenRow(
              bird: bird,
              count: counts[bird.id] ?? 0,
              onCountChanged: (c) => onCountChanged(bird.id, c),
            );
          },
        );
      },
    );
  }
}

/// Hen list for "All Flocks" mode — groups hens under flock headers.
class _AllFlocksHenList extends ConsumerWidget {
  final Map<String, int> counts;
  final void Function(String birdId, int count) onCountChanged;

  const _AllFlocksHenList({
    required this.counts,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hensAsync = ref.watch(allActiveHensProvider);
    final flocksAsync = ref.watch(flocksProvider);

    return hensAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (hens) {
        if (hens.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No active hens')),
          );
        }

        final sortedHens = [...hens]
          ..sort((a, b) => a.name.compareTo(b.name));

        // Group by flockId
        final grouped = <String, List<Bird>>{};
        for (final hen in sortedHens) {
          grouped.putIfAbsent(hen.flockId, () => []).add(hen);
        }

        final flocks = flocksAsync.value ?? [];
        final flockNames = {for (final f in flocks) f.id: f.name};

        // Sort flock groups by name
        final sortedFlockIds = grouped.keys.toList()
          ..sort((a, b) =>
              (flockNames[a] ?? '').compareTo(flockNames[b] ?? ''));

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: sortedFlockIds.fold<int>(
            0,
            (sum, id) =>
                sum + 1 + grouped[id]!.length, // 1 header + hens
          ),
          itemBuilder: (context, index) {
            // Walk through flock groups to find the item at this index
            int currentIndex = 0;
            for (final flockId in sortedFlockIds) {
              final flockHens = grouped[flockId]!;
              if (index == currentIndex) {
                // Flock header
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    flockNames[flockId] ?? 'Unknown Flock',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                );
              }
              currentIndex++; // past header

              if (index < currentIndex + flockHens.length) {
                final bird = flockHens[index - currentIndex];
                return _HenRow(
                  bird: bird,
                  count: counts[bird.id] ?? 0,
                  onCountChanged: (c) => onCountChanged(bird.id, c),
                );
              }
              currentIndex += flockHens.length;
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

// ==================== ROW & HELPER WIDGETS ====================

/// A single hen card matching the BirdCard style:
/// 100px tall, photo strip on left (~38%), text + counter on right.
class _HenRow extends StatelessWidget {
  final Bird bird;
  final int count;
  final ValueChanged<int> onCountChanged;

  const _HenRow({
    required this.bird,
    required this.count,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto =
        bird.photoPrimary != null && File(bird.photoPrimary!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            // Photo strip — left ~38% of card
            SizedBox(
              width: 120,
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(bird.photoPrimary!),
                          fit: BoxFit.cover,
                        ),
                        // Tint overlay when count > 0
                        if (count > 0)
                          Container(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                          ),
                      ],
                    )
                  : Container(
                      color: _eggTintColor(bird.eggColor) ??
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Center(
                        child: Text(
                          bird.name.isNotEmpty
                              ? bird.name[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
            // Text content + counter — right ~62%
            Expanded(
              child: Container(
                color: count > 0
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                    : null,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Name and breed
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            bird.name,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (bird.breed != null &&
                              bird.breed!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bird.breed!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Counter: [−] count [+]
                    _CounterControls(
                      count: count,
                      onDecrement:
                          count > 0 ? () => onCountChanged(count - 1) : null,
                      onIncrement: () => onCountChanged(count + 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _eggColorMap = {
    for (final e in EggColor.values) e.name.toLowerCase(): e,
    for (final b in breeds) b.eggColorDisplay.toLowerCase(): b.eggColor,
  };

  static Color? _eggTintColor(String? eggColor) {
    if (eggColor == null || eggColor.isEmpty) return null;
    final parsed = _eggColorMap[eggColor.toLowerCase()];
    if (parsed == null) return null;
    return switch (parsed) {
      EggColor.white => const Color(0xFFF5F0E8).withValues(alpha: 0.5),
      EggColor.cream => const Color(0xFFF5E6C8).withValues(alpha: 0.4),
      EggColor.brown => const Color(0xFFC8A882).withValues(alpha: 0.25),
      EggColor.darkBrown => const Color(0xFFA0764A).withValues(alpha: 0.25),
      EggColor.chocolate => const Color(0xFF7B4B2A).withValues(alpha: 0.25),
      EggColor.blue => const Color(0xFF9BC4E2).withValues(alpha: 0.3),
      EggColor.green => const Color(0xFFA8D5BA).withValues(alpha: 0.3),
      EggColor.olive => const Color(0xFFB5C48C).withValues(alpha: 0.3),
      EggColor.pink => const Color(0xFFF2C6C2).withValues(alpha: 0.3),
      EggColor.tinted => const Color(0xFFE8D5C4).withValues(alpha: 0.3),
    };
  }
}

/// Compact +/− counter controls.
class _CounterControls extends StatelessWidget {
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _CounterControls({
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus button
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton.filled(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: onDecrement != null
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.38),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        // Count
        SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: count > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        // Plus button
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton.filled(
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

/// Date chip (same style as quick log).
class _DateChip extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;

  const _DateChip({required this.date, this.onTap});

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

/// Sticky footer with running total and Save All button.
class _StickyFooter extends StatelessWidget {
  final int totalEggs;
  final bool isSaving;
  final VoidCallback? onSave;

  const _StickyFooter({
    required this.totalEggs,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      totalEggs == 0
                          ? 'Save (No Eggs)'
                          : 'Save $totalEggs ${totalEggs == 1 ? 'Egg' : 'Eggs'}',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

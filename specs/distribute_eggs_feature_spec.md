# Flock Manager — Egg Distribution Feature Spec

## Overview

When a user logs eggs and the count exactly matches the number of active birds in the flock, offer to distribute the eggs evenly (one per bird). This streamlines attribution for small flocks where keepers can reliably assume each bird laid one egg.

---

## User Story

**As a** backyard chicken keeper with a small flock  
**I want to** log my daily eggs and have them automatically attributed to each bird  
**So that** I get accurate per-bird production stats without manual entry for each hen

---

## Design Decisions

### When to Offer Distribution

The distribution prompt appears when ALL conditions are met:

| Condition | Rationale |
|-----------|-----------|
| `eggCount > 0` | No point distributing zero eggs |
| `eggCount == activeBirds.length` | Even distribution only (1 egg per bird) |
| `activeBirds.length >= 2` | Single bird doesn't need "distribution" |
| `activeBirds.length <= 10` | Large flocks make this impractical |
| Flock is selected (not "All Flocks") | Need specific birds to distribute to |

### Data Model

No schema changes required. Distribution creates multiple `egg_log` records with:
- Same `date` (the logging date)
- Same `created_at` timestamp (used to group distributed sets)
- Same `flock_id`
- Different `bird_id` (one per bird)
- `count = 1` for each record

### History Grouping

Distributed egg logs are visually grouped in history views by matching:
- Same `date`
- Same `flock_id`  
- `created_at` timestamps within 2 seconds of each other
- All have non-null `bird_id`

---

## Task 1: Distribution Logic & Repository

### File: `lib/repositories/egg_repository.dart`

Add method to insert distributed eggs:

```dart
/// Insert multiple egg logs as a distributed set.
/// All logs share the same created_at timestamp for grouping.
Future<List<EggLog>> insertDistributedEggLogs({
  required DateTime date,
  required String flockId,
  required Map<String, int> distribution, // birdId -> count
  String? size,
  String? quality,
  String? notes,
}) async {
  final now = DateTime.now();
  final logs = <EggLog>[];
  
  for (final entry in distribution.entries) {
    if (entry.value > 0) {
      final log = EggLog(
        id: const Uuid().v4(),
        date: date,
        flockId: flockId,
        birdId: entry.key,
        count: entry.value,
        size: size,
        quality: quality,
        notes: notes,
        createdAt: now, // Same timestamp for all
      );
      await insertEggLog(log);
      logs.add(log);
    }
  }
  
  return logs;
}
```

### File: `lib/utils/distribution_helper.dart` (new)

```dart
/// Determines if egg distribution should be offered.
bool shouldOfferDistribution({
  required int eggCount,
  required List<Bird> activeBirds,
  required String? selectedFlockId,
}) {
  if (selectedFlockId == null) return false; // "All Flocks" mode
  if (eggCount <= 0) return false;
  if (activeBirds.length < 2) return false;
  if (activeBirds.length > 10) return false;
  if (eggCount != activeBirds.length) return false;
  
  return true;
}

/// Creates an even distribution map (1 egg per bird).
Map<String, int> createEvenDistribution(List<Bird> birds) {
  return { for (final bird in birds) bird.id: 1 };
}
```

### Acceptance Criteria

- [ ] `insertDistributedEggLogs` creates multiple records with identical `created_at`
- [ ] `shouldOfferDistribution` returns correct boolean for all edge cases
- [ ] Unit tests cover: 2 eggs/2 birds ✓, 3 eggs/2 birds ✗, 0 eggs ✗, 11+ birds ✗

---

## Task 2: Distribution Dialog Widget

### File: `lib/widgets/distribute_eggs_dialog.dart` (new)

A modal dialog showing each bird with their allocated egg count.

### UI Mockup

```
┌─────────────────────────────────────┐
│  Distribute to each bird?           │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🐔  Ginger                1 │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🐔  Henrietta             1 │   │
│  └─────────────────────────────┘   │
│                                     │
│  Each bird gets 1 egg               │
│                                     │
│         [Skip]    [Distribute]      │
└─────────────────────────────────────┘
```

### Implementation

```dart
import 'package:flutter/material.dart';
import '../models/bird.dart';

class DistributeEggsDialog extends StatelessWidget {
  final int eggCount;
  final List<Bird> birds;
  
  const DistributeEggsDialog({
    super.key,
    required this.eggCount,
    required this.birds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Distribute to each bird?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...birds.map((bird) => _BirdDistributionRow(
                bird: bird,
                count: 1,
              )),
              const SizedBox(height: 12),
              Text(
                'Each bird gets 1 egg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () {
            final distribution = { for (final bird in birds) bird.id: 1 };
            Navigator.of(context).pop(distribution);
          },
          child: const Text('Distribute'),
        ),
      ],
    );
  }
}

class _BirdDistributionRow extends StatelessWidget {
  final Bird bird;
  final int count;
  
  const _BirdDistributionRow({
    required this.bird,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Bird avatar (photo or placeholder)
            CircleAvatar(
              radius: 16,
              backgroundImage: bird.photoPrimary != null 
                ? FileImage(File(bird.photoPrimary!))
                : null,
              child: bird.photoPrimary == null 
                ? const Icon(Icons.egg, size: 16)
                : null,
            ),
            const SizedBox(width: 12),
            // Bird name
            Expanded(
              child: Text(
                bird.name,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Egg count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Acceptance Criteria

- [ ] Dialog displays all active birds with photos (or placeholder)
- [ ] Shows "1" allocation for each bird
- [ ] "Skip" returns null (caller proceeds with normal save)
- [ ] "Distribute" returns `Map<String, int>` with bird IDs and counts
- [ ] Scrollable if more than ~5 birds
- [ ] Follows app theme

---

## Task 3: Quick Log Integration

### File: `lib/widgets/egg_quick_log.dart`

Modify the save flow to check for distribution eligibility and show the dialog.

### Changes

```dart
// Add import
import 'distribute_eggs_dialog.dart';
import '../utils/distribution_helper.dart';

// In the widget's save method:

Future<void> _saveEggs() async {
  // Get active birds for selected flock
  final activeBirds = await ref.read(
    activeBirdsByFlockProvider(selectedFlockId!).future
  );
  
  // Check if distribution should be offered
  if (shouldOfferDistribution(
    eggCount: _count,
    activeBirds: activeBirds,
    selectedFlockId: selectedFlockId,
  )) {
    // Show distribution dialog
    final distribution = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => DistributeEggsDialog(
        eggCount: _count,
        birds: activeBirds,
      ),
    );
    
    if (distribution != null) {
      // User chose to distribute
      await ref.read(eggRepositoryProvider).insertDistributedEggLogs(
        date: _selectedDate,
        flockId: selectedFlockId!,
        distribution: distribution,
        size: _selectedSize,
        quality: _selectedQuality,
        notes: _notes.isNotEmpty ? _notes : null,
      );
      
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged $_count eggs (1 each to ${activeBirds.map((b) => b.name).join(", ")})',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
      
      // Invalidate providers
      ref.invalidate(todayEggsProvider);
      ref.invalidate(eggHistoryProvider);
      
      return;
    }
    // User tapped "Skip" — fall through to normal save
  }
  
  // Normal save (existing code)
  await _saveFlockLevelEggs();
}
```

### Provider Needed

Ensure this provider exists (or create it):

```dart
// lib/providers/bird_provider.dart

final activeBirdsByFlockProvider = FutureProvider.family<List<Bird>, String>(
  (ref, flockId) async {
    final repository = ref.read(birdRepositoryProvider);
    final birds = await repository.getBirdsByFlock(flockId);
    return birds.where((b) => b.status == BirdStatus.active).toList();
  },
);
```

### Acceptance Criteria

- [ ] Distribution dialog appears when conditions met
- [ ] Dialog does NOT appear when conditions not met
- [ ] "Skip" proceeds with normal flock-level save
- [ ] "Distribute" creates per-bird records
- [ ] Toast message names all birds
- [ ] Providers invalidated after save
- [ ] Haptic feedback on success

---

## Task 4: History Display Grouping

### File: `lib/screens/eggs/egg_history_screen.dart`

Group distributed egg logs visually so they don't appear as separate redundant entries.

### Grouping Logic

```dart
// lib/utils/egg_log_grouper.dart (new)

class EggLogGroup {
  final DateTime date;
  final String flockId;
  final DateTime createdAt;
  final List<EggLog> logs;
  
  EggLogGroup({
    required this.date,
    required this.flockId,
    required this.createdAt,
    required this.logs,
  });
  
  /// True if this group represents a distributed set
  bool get isDistributed => 
    logs.length > 1 && 
    logs.every((log) => log.birdId != null);
  
  /// Total eggs in this group
  int get totalCount => logs.fold(0, (sum, log) => sum + log.count);
  
  /// Display timestamp (from first log)
  DateTime get displayTime => logs.first.createdAt;
}

/// Groups egg logs that were created together (distributed).
/// Logs are considered part of the same group if:
/// - Same date
/// - Same flock_id
/// - created_at within 2 seconds of each other
List<EggLogGroup> groupEggLogs(List<EggLog> logs) {
  if (logs.isEmpty) return [];
  
  // Sort by created_at descending
  final sorted = List<EggLog>.from(logs)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  
  final groups = <EggLogGroup>[];
  var currentGroup = <EggLog>[sorted.first];
  
  for (var i = 1; i < sorted.length; i++) {
    final current = sorted[i];
    final previous = currentGroup.last;
    
    final sameDate = _isSameDay(current.date, previous.date);
    final sameFlock = current.flockId == previous.flockId;
    final closeTimestamp = previous.createdAt.difference(current.createdAt).abs() 
        <= const Duration(seconds: 2);
    
    if (sameDate && sameFlock && closeTimestamp) {
      currentGroup.add(current);
    } else {
      // Finalize previous group
      groups.add(EggLogGroup(
        date: currentGroup.first.date,
        flockId: currentGroup.first.flockId,
        createdAt: currentGroup.first.createdAt,
        logs: List.unmodifiable(currentGroup),
      ));
      currentGroup = [current];
    }
  }
  
  // Don't forget the last group
  groups.add(EggLogGroup(
    date: currentGroup.first.date,
    flockId: currentGroup.first.flockId,
    createdAt: currentGroup.first.createdAt,
    logs: List.unmodifiable(currentGroup),
  ));
  
  return groups;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
```

### Display Widget

```dart
// lib/widgets/egg_log_group_tile.dart (new)

class EggLogGroupTile extends StatelessWidget {
  final EggLogGroup group;
  final VoidCallback? onTap;
  
  const EggLogGroupTile({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (group.isDistributed) {
      return _buildDistributedTile(context, theme);
    } else {
      return _buildNormalTile(context, theme);
    }
  }
  
  Widget _buildDistributedTile(BuildContext context, ThemeData theme) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.egg,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${group.totalCount} eggs distributed',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(group.displayTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show each bird's contribution
              ...group.logs.map((log) => Padding(
                padding: const EdgeInsets.only(left: 32, top: 2),
                child: Row(
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Need to look up bird name - may need async or pass in
                    Text(
                      '${log.birdId} (${log.count})', // Replace with bird name
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNormalTile(BuildContext context, ThemeData theme) {
    final log = group.logs.first;
    return Card(
      child: ListTile(
        leading: Icon(Icons.egg, color: theme.colorScheme.primary),
        title: Text('${log.count} egg${log.count == 1 ? '' : 's'}'),
        subtitle: log.birdId != null 
          ? Text(log.birdId!) // Replace with bird name lookup
          : null,
        trailing: Text(
          _formatTime(log.createdAt),
          style: theme.textTheme.bodySmall,
        ),
        onTap: onTap,
      ),
    );
  }
  
  String _formatTime(DateTime dt) {
    // Format as "2:30 PM"
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
```

### History Screen Integration

```dart
// In egg_history_screen.dart, modify the list builder:

final eggLogs = ref.watch(eggLogsByDateProvider(selectedDate));

return eggLogs.when(
  data: (logs) {
    final groups = groupEggLogs(logs);
    
    if (groups.isEmpty) {
      return const Center(child: Text('No eggs logged'));
    }
    
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return EggLogGroupTile(
          group: groups[index],
          onTap: () => _showGroupDetail(groups[index]),
        );
      },
    );
  },
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Acceptance Criteria

- [ ] Distributed logs grouped into single visual item
- [ ] Group shows total count + "distributed" label
- [ ] Expanded view lists each bird and their count
- [ ] Non-distributed logs display normally (no grouping)
- [ ] Groups ordered by most recent first
- [ ] Tapping group allows edit/delete (future enhancement)

---

## Task 5: User Preference (Optional Enhancement)

Allow users to auto-distribute without the prompt dialog.

### File: `lib/providers/settings_provider.dart`

```dart
final autoDistributeEggsProvider = StateProvider<bool>((ref) {
  // Load from SharedPreferences
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('auto_distribute_eggs') ?? false;
});

// Update method
Future<void> setAutoDistributeEggs(WidgetRef ref, bool value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setBool('auto_distribute_eggs', value);
  ref.invalidate(autoDistributeEggsProvider);
}
```

### Settings Screen Addition

```dart
// In settings_screen.dart, add to Egg Logging section:

SwitchListTile(
  title: const Text('Auto-distribute eggs'),
  subtitle: const Text(
    'When egg count matches bird count, automatically attribute one egg per bird',
  ),
  value: ref.watch(autoDistributeEggsProvider),
  onChanged: (value) => setAutoDistributeEggs(ref, value),
),
```

### Quick Log Modification

```dart
// In _saveEggs(), modify the distribution check:

if (shouldOfferDistribution(...)) {
  final autoDistribute = ref.read(autoDistributeEggsProvider);
  
  Map<String, int>? distribution;
  
  if (autoDistribute) {
    // Auto-distribute without prompt
    distribution = createEvenDistribution(activeBirds);
  } else {
    // Show dialog
    distribution = await showDialog<Map<String, int>>(...);
  }
  
  if (distribution != null) {
    // ... save distributed eggs
  }
}
```

### Acceptance Criteria

- [ ] Setting appears in Settings screen under appropriate section
- [ ] Default is OFF (always show prompt)
- [ ] When ON, distribution happens automatically without dialog
- [ ] Toast still shows attribution summary
- [ ] Preference persists across app restarts

---

## Test Cases

### Unit Tests

| Test | Input | Expected |
|------|-------|----------|
| `shouldOfferDistribution` | 2 eggs, 2 birds, flock selected | `true` |
| `shouldOfferDistribution` | 3 eggs, 2 birds | `false` |
| `shouldOfferDistribution` | 2 eggs, 2 birds, "All Flocks" | `false` |
| `shouldOfferDistribution` | 0 eggs, 2 birds | `false` |
| `shouldOfferDistribution` | 5 eggs, 5 birds | `true` |
| `shouldOfferDistribution` | 11 eggs, 11 birds | `false` |
| `groupEggLogs` | 2 logs same timestamp | 1 group, `isDistributed = true` |
| `groupEggLogs` | 2 logs 1 min apart | 2 groups |
| `groupEggLogs` | 1 log with bird_id | 1 group, `isDistributed = false` |

### Integration Tests

| Scenario | Steps | Expected |
|----------|-------|----------|
| Distribute 2 eggs | Log 2 eggs in 2-bird flock, tap Distribute | 2 egg_log records, same created_at |
| Skip distribution | Log 2 eggs, tap Skip | 1 egg_log record, bird_id = null |
| Auto-distribute ON | Enable setting, log 2 eggs | No dialog, 2 records created |
| History grouping | View history after distribution | Single grouped item shown |

### Manual Testing Checklist

- [ ] Fresh install: log eggs, verify distribution prompt appears
- [ ] 3+ egg colors flock: verify prompt works with various birds
- [ ] Large flock (12 birds): verify prompt does NOT appear
- [ ] Mixed scenario: distribute some days, skip others, verify history correct
- [ ] Delete distributed group: verify all related logs deleted (or handle gracefully)

---

## Future Enhancements (Out of Scope)

1. **Uneven distribution**: Allow manual adjustment (2 eggs to Ginger, 1 to Henrietta)
2. **Egg color matching**: Auto-assign based on egg color → bird's expected color
3. **Undo distribution**: Convert distributed logs back to single flock-level log
4. **Distribution history**: See distribution patterns over time per bird
5. **Smart suggestions**: "Ginger usually lays on Tuesdays" based on patterns

---

## Implementation Order

1. **Task 1**: Distribution logic & repository (foundation)
2. **Task 2**: Distribution dialog widget (UI component)
3. **Task 3**: Quick log integration (wire it together)
4. **Task 4**: History display grouping (polish)
5. **Task 5**: User preference (optional enhancement)

Estimated effort: 4-6 hours for Tasks 1-4, +1 hour for Task 5.

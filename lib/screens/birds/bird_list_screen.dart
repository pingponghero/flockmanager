import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/bird.dart';
import '../../models/enums.dart';
import '../../providers/bird_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/trial_provider.dart';
import '../../utils/edge_insets.dart';
import '../../widgets/bird_card.dart';
import '../../widgets/filter_menu_chip.dart';
import '../../widgets/flock_dropdown.dart';
import '../../widgets/trial_banner.dart' show showTrialExpiredDialog;

/// Sort options for bird list
enum BirdSortOption {
  name,
  age,
  recentlyAdded;

  String get displayName => switch (this) {
        BirdSortOption.name => 'Name',
        BirdSortOption.age => 'Age',
        BirdSortOption.recentlyAdded => 'Recently Added',
      };
}

class BirdListScreen extends ConsumerStatefulWidget {
  const BirdListScreen({super.key});

  @override
  ConsumerState<BirdListScreen> createState() => _BirdListScreenState();
}

class _BirdListScreenState extends ConsumerState<BirdListScreen> {
  BirdSex? _sexFilter = BirdSex.female;
  BirdStatus? _statusFilter = BirdStatus.active;
  BirdSortOption _sortOption = BirdSortOption.name;

  @override
  Widget build(BuildContext context) {
    final selectedFlockId = ref.watch(selectedFlockIdProvider);
    final birdsAsync = ref.watch(birdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birds'),
        actions: [
          // Flock history
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Flock History',
            onPressed: () => context.push('/birds/events'),
          ),
          // Sort menu
          PopupMenuButton<BirdSortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => BirdSortOption.values
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (_sortOption == option)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(option.displayName),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Flock filter dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FlockDropdown(
              selectedFlockId: selectedFlockId,
              onChanged: (value) {
                ref.read(selectedFlockIdProvider.notifier).selectFlock(value);
              },
            ),
          ),
          // Sex / status filter chips + count (#61). The chips show the
          // active filters (default: Female · Active) and clear with ✕.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterMenuChip<BirdSex>(
                          tooltip: 'Sex',
                          value: _sexFilter,
                          anyLabel: 'Any sex',
                          options: [
                            for (final sex in BirdSex.values)
                              FilterMenuOption(
                                value: sex,
                                label: sex == BirdSex.unknown
                                    ? 'Sex unknown'
                                    : sex.displayName,
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _sexFilter = value),
                        ),
                        const SizedBox(width: 8),
                        FilterMenuChip<BirdStatus>(
                          tooltip: 'Status',
                          value: _statusFilter,
                          anyLabel: 'Any status',
                          options: [
                            for (final status in BirdStatus.values)
                              FilterMenuOption(
                                value: status,
                                label: status.displayName,
                                icon: Icon(
                                  status.icon,
                                  size: 18,
                                  color: status.iconColor,
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _statusFilter = value),
                        ),
                      ],
                    ),
                  ),
                ),
                if (birdsAsync.value case final allBirds?) ...[
                  const SizedBox(width: 8),
                  Text(
                    _countLabel(
                      _applyFilters(allBirds, selectedFlockId).length,
                      allBirds.length,
                      selectedFlockId,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          // Bird list
          Expanded(
            child: birdsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ErrorState(
                error: error.toString(),
                onRetry: () => ref.invalidate(birdsProvider),
              ),
              data: (allBirds) {
                final birds = _applyFilters(allBirds, selectedFlockId);

                if (birds.isEmpty) {
                  return _EmptyState(
                    hasFilters:
                        selectedFlockId != null || _statusFilter != null || _sexFilter != null,
                    onClearFilters: () {
                      setState(() {
                        _sexFilter = null;
                        _statusFilter = null;
                      });
                      ref
                          .read(selectedFlockIdProvider.notifier)
                          .clearSelection();
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    return ref.read(birdsProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: pagePadding(context),
                    itemCount: birds.length,
                    itemBuilder: (context, index) {
                      final bird = birds[index];
                      return BirdCard(
                        bird: bird,
                        onTap: () => context.push('/birds/${bird.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final canEdit = ref.watch(canEditProvider);
          return FloatingActionButton(
            onPressed: canEdit
                ? () => context.push('/birds/new')
                : () => showTrialExpiredDialog(context, ref),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  /// Applies the flock, sex and status filters, then the chosen sort.
  List<Bird> _applyFilters(List<Bird> allBirds, String? selectedFlockId) {
    final birds = allBirds
        .where((b) => selectedFlockId == null || b.flockId == selectedFlockId)
        .where((b) => _sexFilter == null || b.sex == _sexFilter)
        .where((b) => _statusFilter == null || b.status == _statusFilter)
        .toList();
    return _sortBirds(birds, _sortOption);
  }

  String _countLabel(int shown, int total, String? selectedFlockId) {
    final hasFilters =
        selectedFlockId != null || _statusFilter != null || _sexFilter != null;
    return hasFilters ? '$shown of $total' : '$total birds';
  }

  List<Bird> _sortBirds(List<Bird> birds, BirdSortOption option) {
    final sorted = List<Bird>.from(birds);
    switch (option) {
      case BirdSortOption.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case BirdSortOption.age:
        sorted.sort((a, b) {
          final ageA = a.ageInDays ?? 0;
          final ageB = b.ageInDays ?? 0;
          return ageB.compareTo(ageA); // Oldest first
        });
      case BirdSortOption.recentlyAdded:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/cute_hen.png',
              width: 80,
              height: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'No Birds Found' : 'No Birds Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters.'
                  : 'Tap + to add your first bird.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onClearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading birds',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

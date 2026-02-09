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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FlockDropdown(
              selectedFlockId: selectedFlockId,
              onChanged: (value) {
                ref.read(selectedFlockIdProvider.notifier).selectFlock(value);
              },
            ),
          ),
          // Gender and status filter dropdowns
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownMenu<BirdSex?>(
                    initialSelection: _sexFilter,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Gender'),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(value: null, label: 'All'),
                      ...BirdSex.values.map((sex) => DropdownMenuEntry(
                            value: sex,
                            label: sex.displayName,
                          )),
                    ],
                    onSelected: (value) =>
                        setState(() => _sexFilter = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownMenu<BirdStatus?>(
                    initialSelection: _statusFilter,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Status'),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(value: null, label: 'All'),
                      ...BirdStatus.values.map((status) => DropdownMenuEntry(
                            value: status,
                            label: status.displayName,
                            leadingIcon: Icon(
                              status.icon,
                              size: 18,
                              color: status.iconColor,
                            ),
                          )),
                    ],
                    onSelected: (value) =>
                        setState(() => _statusFilter = value),
                  ),
                ),
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
                // Apply flock filter
                var birds = selectedFlockId == null
                    ? allBirds
                    : allBirds
                        .where((b) => b.flockId == selectedFlockId)
                        .toList();

                // Apply sex filter
                if (_sexFilter != null) {
                  birds =
                      birds.where((b) => b.sex == _sexFilter).toList();
                }

                // Apply status filter
                if (_statusFilter != null) {
                  birds =
                      birds.where((b) => b.status == _statusFilter).toList();
                }

                // Apply sorting
                birds = _sortBirds(birds, _sortOption);

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

                final hasFilters = selectedFlockId != null || _statusFilter != null || _sexFilter != null;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            hasFilters
                                ? '${birds.length} of ${allBirds.length} birds'
                                : '${birds.length} birds',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.read(birdsProvider.notifier).refresh(),
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
                      ),
                    ),
                  ],
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

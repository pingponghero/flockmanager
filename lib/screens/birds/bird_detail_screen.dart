import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/bird.dart';
import '../../models/egg_log.dart';
import '../../models/enums.dart';
import '../../providers/bird_provider.dart';
import '../../providers/egg_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/trial_provider.dart';
import '../../utils/edge_insets.dart';

class BirdDetailScreen extends ConsumerWidget {
  final String birdId;

  const BirdDetailScreen({super.key, required this.birdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birdAsync = ref.watch(birdByIdProvider(birdId));

    return birdAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading bird: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
      data: (bird) {
        if (bird == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Bird not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return _BirdDetailContent(bird: bird);
      },
    );
  }
}

class _BirdDetailContent extends ConsumerWidget {
  final Bird bird;

  const _BirdDetailContent({required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.push('/birds/${bird.id}/edit'),
                  ),
                  if (bird.status == BirdStatus.active)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'deceased':
                            _showStatusChangeDialog(context, ref, BirdStatus.deceased);
                          case 'sold':
                            _showStatusChangeDialog(context, ref, BirdStatus.sold);
                          case 'givenAway':
                            _showStatusChangeDialog(context, ref, BirdStatus.givenAway);
                          case 'delete':
                            _showDeleteDialog(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'deceased',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Record Death'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'sold',
                          child: Row(
                            children: [
                              Icon(Icons.sell, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Mark as Sold'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'givenAway',
                          child: Row(
                            children: [
                              Icon(Icons.volunteer_activism, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Mark as Given Away'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Bird', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (bird.status != BirdStatus.active)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'reactivate') {
                          _showReactivateDialog(context, ref);
                        } else if (value == 'delete') {
                          _showDeleteDialog(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'reactivate',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Reactivate'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Bird', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _BirdHeader(bird: bird),
                ),
              ),
              SliverToBoxAdapter(
                child: _StatsRow(bird: bird),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Info'),
                      Tab(text: 'Eggs'),
                      Tab(text: 'Health'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _InfoTab(bird: bird),
              _EggsTab(bird: bird),
              _HealthTab(bird: bird),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusChangeDialog(
    BuildContext context,
    WidgetRef ref,
    BirdStatus newStatus,
  ) {
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(newStatus == BirdStatus.deceased
              ? 'Record Death'
              : 'Mark as ${newStatus.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to mark ${bird.name} as ${newStatus.displayName.toLowerCase()}?'),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat.yMMMd().format(selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any notes...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final previousStatus = bird.status;
                final previousStatusNotes = bird.statusNotes;
                try {
                  await ref.read(birdsProvider.notifier).updateBirdStatus(
                        bird.id,
                        newStatus,
                        notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${bird.name} marked as ${newStatus.displayName.toLowerCase()}',
                        ),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            try {
                              await ref.read(birdsProvider.notifier).updateBirdStatus(
                                    bird.id,
                                    previousStatus,
                                    previousStatusNotes,
                                  );
                            } catch (_) {
                              // Silently fail - user can manually fix if needed
                            }
                          },
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactivateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Return ${bird.name} to active flock?'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final previousStatus = bird.status;
                final previousStatusNotes = bird.statusNotes;
                try {
                  await ref.read(birdsProvider.notifier).updateBirdStatus(
                        bird.id,
                        BirdStatus.active,
                        null,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${bird.name} is now active'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            try {
                              await ref.read(birdsProvider.notifier).updateBirdStatus(
                                    bird.id,
                                    previousStatus,
                                    previousStatusNotes,
                                  );
                            } catch (_) {
                              // Silently fail
                            }
                          },
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reactivate'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    // Check for associated records
    final eggRepo = ref.read(eggRepositoryProvider);
    final medRepo = ref.read(medicationRepositoryProvider);

    final eggLogCount = await eggRepo.getEggLogCountByBird(bird.id);
    final medicationLogs = await medRepo.getMedicationsByBird(bird.id);
    final healthNotes = await medRepo.getHealthNotesByBird(bird.id);

    final hasRecords = eggLogCount > 0 || medicationLogs.isNotEmpty || healthNotes.isNotEmpty;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bird'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permanently delete ${bird.name}?'),
            if (hasRecords) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Records will be kept',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${eggLogCount > 0 ? '$eggLogCount egg log${eggLogCount == 1 ? '' : 's'}' : ''}'
                            '${eggLogCount > 0 && (medicationLogs.isNotEmpty || healthNotes.isNotEmpty) ? ', ' : ''}'
                            '${medicationLogs.isNotEmpty ? '${medicationLogs.length} medication${medicationLogs.length == 1 ? '' : 's'}' : ''}'
                            '${medicationLogs.isNotEmpty && healthNotes.isNotEmpty ? ', ' : ''}'
                            '${healthNotes.isNotEmpty ? '${healthNotes.length} health note${healthNotes.length == 1 ? '' : 's'}' : ''}'
                            ' will be preserved but unlinked from this bird.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Reassign records to anonymous
                if (eggLogCount > 0) {
                  await eggRepo.reassignEggLogsToAnonymous(bird.id);
                }
                if (medicationLogs.isNotEmpty) {
                  await medRepo.reassignMedicationLogsToAnonymous(bird.id);
                }
                if (healthNotes.isNotEmpty) {
                  await medRepo.reassignHealthNotesToAnonymous(bird.id);
                }

                // Delete the bird
                await ref.read(birdsProvider.notifier).deleteBird(bird.id);

                if (context.mounted) {
                  context.pop(); // Go back to bird list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${bird.name} deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting bird: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BirdHeader extends StatelessWidget {
  final Bird bird;

  const _BirdHeader({required this.bird});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Photo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: bird.photoPrimary != null && File(bird.photoPrimary!).existsSync()
                  ? Image.file(File(bird.photoPrimary!), fit: BoxFit.cover)
                  : Image.asset(
                      'assets/icons/cute_hen.png',
                      width: 50,
                      height: 50,
                      color: Colors.white70,
                    ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              bird.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            // Breed and age
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (bird.breed != null && bird.breed!.isNotEmpty) ...[
                  Text(
                    bird.breed!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (bird.ageInWeeks != null)
                    const Text(' • ', style: TextStyle(color: Colors.white70)),
                ],
                if (bird.ageInWeeks != null)
                  Text(
                    _formatAge(bird.ageInWeeks!),
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Status badge for non-active
            if (bird.status != BirdStatus.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bird.status.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatAge(int weeks) {
    if (weeks < 52) {
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} old';
    }
    final years = weeks ~/ 52;
    return '$years ${years == 1 ? 'year' : 'years'} old';
  }
}

class _StatsRow extends ConsumerWidget {
  final Bird bird;

  const _StatsRow({required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalEggCountByBirdProvider(bird.id));
    final logsAsync = ref.watch(eggLogsByBirdProvider(bird.id));
    final trial = ref.watch(trialProvider);

    final now = DateTime.now();
    final isActive = bird.status == BirdStatus.active;

    int thisMonthCount = 0;
    String layingRate = '--%';

    if (logsAsync.hasValue) {
      final logs = logsAsync.value!;

      if (isActive) {
        // Active bird: show this month's eggs
        final monthStart = DateTime(now.year, now.month, 1);
        for (final log in logs) {
          if (log.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
            thisMonthCount += log.count;
          }
        }

        // Calculate laying rate (eggs per day over last N days)
        // Use min(30, daysUsingApp) so new users don't see artificially low rates
        if (logs.isNotEmpty) {
          final daysUsingApp = trial.installDate != null
              ? now.difference(trial.installDate!).inDays.clamp(1, 30)
              : 30;
          final periodStart = now.subtract(Duration(days: daysUsingApp));
          int periodEggs = 0;
          for (final log in logs) {
            if (log.date.isAfter(periodStart)) {
              periodEggs += log.count;
            }
          }
          final rate = (periodEggs / daysUsingApp * 100).round();
          layingRate = '$rate%';
        }
      } else {
        // Inactive bird: calculate lifetime average laying rate
        final lastDate = bird.statusDate ?? now;
        final totalDays = lastDate.difference(bird.createdAt).inDays.clamp(1, 9999);
        final totalEggs = logs.fold<int>(0, (sum, log) => sum + log.count);
        final rate = (totalEggs / totalDays * 100).round();
        layingRate = '$rate%';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: 'Total Eggs',
            value: totalAsync.when(
              loading: () => '--',
              error: (_, __) => '--',
              data: (count) => '$count',
            ),
            icon: Icons.egg,
          ),
          if (isActive)
            _StatItem(
              label: 'This Month',
              value: logsAsync.when(
                loading: () => '--',
                error: (_, __) => '--',
                data: (_) => '$thisMonthCount',
              ),
              icon: Icons.calendar_month,
            ),
          _StatItem(
            label: isActive ? 'Laying Rate' : 'Lifetime Rate',
            value: logsAsync.when(
              loading: () => '--%',
              error: (_, __) => '--%',
              data: (_) => layingRate,
            ),
            icon: Icons.trending_up,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _InfoTab extends ConsumerWidget {
  final Bird bird;

  const _InfoTab({required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flockAsync = ref.watch(flockByIdProvider(bird.flockId));
    final dateFormat = DateFormat.yMMMd();

    return ListView(
      padding: pagePadding(context),
      children: [
        _InfoSection(
          title: 'Basic Information',
          items: [
            _InfoItem(label: 'Name', value: bird.name),
            _InfoItem(
              label: 'Flock',
              value: flockAsync.valueOrNull?.name ?? 'Loading...',
            ),
            if (bird.breed != null)
              _InfoItem(label: 'Breed', value: bird.breed!),
            _InfoItem(label: 'Status', value: bird.status.displayName),
          ],
        ),
        const SizedBox(height: 16),
        _InfoSection(
          title: 'Dates',
          items: [
            if (bird.hatchDate != null)
              _InfoItem(
                label: 'Hatch Date',
                value: dateFormat.format(bird.hatchDate!),
              ),
            if (bird.acquiredDate != null)
              _InfoItem(
                label: 'Acquired Date',
                value: dateFormat.format(bird.acquiredDate!),
              ),
            if (bird.statusDate != null && bird.status != BirdStatus.active)
              _InfoItem(
                label: '${bird.status.displayName} Date',
                value: dateFormat.format(bird.statusDate!),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoSection(
          title: 'Details',
          items: [
            if (bird.source != null)
              _InfoItem(label: 'Source', value: bird.source!),
            if (bird.eggColor != null)
              _InfoItem(label: 'Expected Egg Color', value: bird.eggColor!),
            if (bird.notes != null)
              _InfoItem(label: 'Notes', value: bird.notes!),
            if (bird.statusNotes != null && bird.status != BirdStatus.active)
              _InfoItem(
                label: '${bird.status.displayName} Notes',
                value: bird.statusNotes!,
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ),
                      Expanded(
                        child: Text(item.value),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});
}

class _EggsTab extends ConsumerWidget {
  final Bird bird;

  const _EggsTab({required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(eggLogsByBirdProvider(bird.id));

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.egg_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Eggs Logged',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Eggs attributed to ${bird.name} will appear here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        // Sort by date descending
        final sortedLogs = List<EggLog>.from(logs)
          ..sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedLogs.length,
          itemBuilder: (context, index) {
            final log = sortedLogs[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${log.count}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${log.count} egg${log.count == 1 ? '' : 's'}',
                ),
                subtitle: Text(
                  DateFormat.yMMMd().format(log.date),
                ),
                trailing: log.size != null || log.quality != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (log.size != null)
                            Text(
                              log.size!.displayName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (log.quality != null)
                            Text(
                              log.quality!.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _HealthTab extends ConsumerWidget {
  final Bird bird;

  const _HealthTab({required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsByBirdProvider(bird.id));
    final notesAsync = ref.watch(healthNotesByBirdProvider(bird.id));

    return medsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (meds) {
        return notesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (notes) {
            if (meds.isEmpty && notes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Health Records',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medications and health notes for ${bird.name} will appear here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Combine and sort by date descending
            final items = <_HealthItem>[];
            for (final med in meds) {
              items.add(_HealthItem(
                date: med.startDate,
                type: 'medication',
                title: med.medicationName,
                subtitle: med.dosage ?? '',
                notes: med.notes,
              ));
            }
            for (final note in notes) {
              items.add(_HealthItem(
                date: note.date,
                type: 'note',
                title: note.type.displayName,
                subtitle: '',
                notes: note.description,
              ));
            }
            items.sort((a, b) => b.date.compareTo(a.date));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isMed = item.type == 'medication';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMed
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        isMed ? Icons.medication : Icons.note,
                        color: isMed ? Colors.orange.shade700 : Colors.blue.shade700,
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat.yMMMd().format(item.date)),
                        if (item.subtitle.isNotEmpty)
                          Text(
                            item.subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.notes!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: item.notes != null && item.notes!.isNotEmpty,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HealthItem {
  final DateTime date;
  final String type;
  final String title;
  final String subtitle;
  final String? notes;

  _HealthItem({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    this.notes,
  });
}

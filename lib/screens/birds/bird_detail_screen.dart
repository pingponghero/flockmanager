import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/bird.dart';
import '../../models/enums.dart';
import '../../providers/bird_provider.dart';
import '../../providers/egg_provider.dart';
import '../../providers/medication_provider.dart';
import 'widgets/bird_eggs_tab.dart';
import 'widgets/bird_header.dart';
import 'widgets/bird_health_tab.dart';
import 'widgets/bird_info_tab.dart';
import 'widgets/bird_stats_row.dart';

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

class _BirdDetailContent extends ConsumerStatefulWidget {
  final Bird bird;

  const _BirdDetailContent({required this.bird});

  @override
  ConsumerState<_BirdDetailContent> createState() => _BirdDetailContentState();
}

class _BirdDetailContentState extends ConsumerState<_BirdDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Trigger rebuild when tab changes (for FAB visibility)
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Bird get bird => widget.bird;

  @override
  Widget build(BuildContext context) {
    final isHealthTab = _tabController.index == 2;

    return Scaffold(
      body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                foregroundColor: Colors.white,
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
                          case 'inactive':
                            _showStatusChangeDialog(context, ref, BirdStatus.inactive);
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
                          value: 'inactive',
                          child: Row(
                            children: [
                              Icon(Icons.bedtime, color: Colors.amber),
                              SizedBox(width: 8),
                              Text('Mark as Inactive'),
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
                  background: BirdHeader(bird: bird),
                ),
              ),
              SliverToBoxAdapter(
                child: BirdStatsRow(bird: bird),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
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
            controller: _tabController,
            children: [
              BirdInfoTab(bird: bird),
              BirdEggsTab(bird: bird),
              BirdHealthTab(bird: bird),
            ],
          ),
      ),
      floatingActionButton: isHealthTab
          ? FloatingActionButton(
              onPressed: () => context.push('/birds/${bird.id}/health/new'),
              child: const Icon(Icons.add),
            )
          : null,
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
                  final eventId = await ref.read(birdsProvider.notifier).updateBirdStatus(
                        bird.id,
                        newStatus,
                        notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        eventDate: selectedDate,
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
                              if (eventId != null) {
                                await ref.read(birdsProvider.notifier).deleteStatusEvent(eventId);
                              }
                              await ref.read(birdsProvider.notifier).updateBirdStatus(
                                    bird.id,
                                    previousStatus,
                                    previousStatusNotes,
                                    recordEvent: false,
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
                  final eventId = await ref.read(birdsProvider.notifier).updateBirdStatus(
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
                              if (eventId != null) {
                                await ref.read(birdsProvider.notifier).deleteStatusEvent(eventId);
                              }
                              await ref.read(birdsProvider.notifier).updateBirdStatus(
                                    bird.id,
                                    previousStatus,
                                    previousStatusNotes,
                                    recordEvent: false,
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
                    SnackBar(
                      content: Text('${bird.name} deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ref.read(birdsProvider.notifier).addBird(bird);
                        },
                      ),
                    ),
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

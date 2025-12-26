import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/bird.dart';
import '../../models/enums.dart';
import '../../providers/bird_provider.dart';
import '../../providers/flock_provider.dart';

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
                    PopupMenuButton<BirdStatus>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (status) =>
                          _showStatusChangeDialog(context, ref, status),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: BirdStatus.deceased,
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Mark as Deceased'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: BirdStatus.sold,
                          child: Row(
                            children: [
                              Icon(Icons.sell, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Mark as Sold'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: BirdStatus.givenAway,
                          child: Row(
                            children: [
                              Icon(Icons.volunteer_activism, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Mark as Given Away'),
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
          title: Text('Mark as ${newStatus.displayName}'),
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
                  : const Icon(Icons.flutter_dash, size: 50, color: Colors.white70),
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

class _StatsRow extends StatelessWidget {
  final Bird bird;

  const _StatsRow({required this.bird});

  @override
  Widget build(BuildContext context) {
    // Placeholder stats - will be computed from egg logs in Phase 3
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: 'Total Eggs',
            value: '--',
            icon: Icons.egg,
          ),
          _StatItem(
            label: 'This Month',
            value: '--',
            icon: Icons.calendar_month,
          ),
          _StatItem(
            label: 'Laying Rate',
            value: '--%',
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
      padding: const EdgeInsets.all(16),
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

class _EggsTab extends StatelessWidget {
  final Bird bird;

  const _EggsTab({required this.bird});

  @override
  Widget build(BuildContext context) {
    // Placeholder - will show egg logs in Phase 3
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.egg,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Egg History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Egg logs for this bird will appear here.\nComing in Phase 3.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthTab extends StatelessWidget {
  final Bird bird;

  const _HealthTab({required this.bird});

  @override
  Widget build(BuildContext context) {
    // Placeholder - will show health notes and medications
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Health Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Health notes and medications will appear here.\nComing in a future phase.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

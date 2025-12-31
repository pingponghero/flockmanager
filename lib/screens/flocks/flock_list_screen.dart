import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/flock.dart';
import '../../providers/flock_provider.dart';

class FlockListScreen extends ConsumerWidget {
  const FlockListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flocksAsync = ref.watch(flocksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flocks'),
      ),
      body: flocksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading flocks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(flocksProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (flocks) {
          if (flocks.isEmpty) {
            return _EmptyState(
              onAddFlock: () => context.push('/flocks/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(flocksProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: flocks.length,
              itemBuilder: (context, index) {
                final flock = flocks[index];
                return _FlockCard(
                  flock: flock,
                  onTap: () => context.push('/flocks/${flock.id}'),
                  onArchive: () => _showArchiveDialog(context, ref, flock),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/flocks/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showArchiveDialog(BuildContext context, WidgetRef ref, Flock flock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Flock'),
        content: Text('Are you sure you want to archive "${flock.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(flocksProvider.notifier).archiveFlock(flock.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${flock.name} archived'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(flocksProvider.notifier).unarchiveFlock(flock.id);
                    },
                  ),
                ),
              );
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddFlock;

  const _EmptyState({required this.onAddFlock});

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
              'No Flocks Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first flock to start tracking your birds.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddFlock,
              icon: const Icon(Icons.add),
              label: const Text('Add Flock'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlockCard extends StatelessWidget {
  final Flock flock;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const _FlockCard({
    required this.flock,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final flockColor = _parseColor(flock.color);

    return Dismissible(
      key: Key(flock.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onArchive();
        return false; // Don't actually dismiss, let the dialog handle it
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onArchive,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Color indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: flockColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildFlockIcon(flock.icon, flockColor),
                ),
                const SizedBox(width: 16),
                // Flock info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flock.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (flock.description != null &&
                          flock.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          flock.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Bird count
                Consumer(
                  builder: (context, ref, child) {
                    final countAsync = ref.watch(flockBirdCountProvider(flock.id));
                    return countAsync.when(
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (error, stackTrace) => const Text('--'),
                      data: (count) => Column(
                        children: [
                          Text(
                            count.toString(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            count == 1 ? 'bird' : 'birds',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return const Color(0xFF8B4513); // Default barn red
    }
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF8B4513);
    }
  }

  Widget _buildFlockIcon(String? iconName, Color color) {
    // cute_hen uses asset image (scaled down to match icon size)
    if (iconName == 'cute_hen') {
      return Center(
        child: Image.asset(
          'assets/icons/cute_hen.png',
          width: 25,
          height: 25,
          color: color,
        ),
      );
    }

    return Icon(
      _parseIcon(iconName),
      color: color,
      size: 24,
    );
  }

  IconData _parseIcon(String? iconName) {
    const iconMap = {
      'egg': Icons.egg,
      'egg_alt': Icons.egg_alt,
      'home': Icons.home,
      'warehouse': Icons.warehouse,
      'fence': Icons.fence,
      'grass': Icons.grass,
      'park': Icons.park,
      'forest': Icons.forest,
      'terrain': Icons.terrain,
      'wb_sunny': Icons.wb_sunny,
      'wb_twilight': Icons.wb_twilight,
      'eco': Icons.eco,
      'nature_people': Icons.nature_people,
      'local_florist': Icons.local_florist,
      'agriculture': Icons.agriculture,
      'favorite': Icons.favorite,
      'star': Icons.star,
      // Legacy
      'groups': Icons.groups,
      'pets': Icons.pets,
    };
    return iconMap[iconName?.toLowerCase()] ?? Icons.egg;
  }
}

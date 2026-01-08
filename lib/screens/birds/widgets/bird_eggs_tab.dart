import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/bird.dart';
import '../../../models/egg_log.dart';
import '../../../providers/egg_provider.dart';

/// Eggs tab showing egg log history for a bird
class BirdEggsTab extends ConsumerWidget {
  final Bird bird;

  const BirdEggsTab({super.key, required this.bird});

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

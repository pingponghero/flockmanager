import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/bird_status_event.dart';
import '../../providers/bird_provider.dart';
import '../../providers/bird_status_event_provider.dart';
import '../../providers/flock_provider.dart';
import '../../utils/edge_insets.dart';
import '../../widgets/flock_dropdown.dart';

/// Screen displaying history of bird status events (added, status changes, etc.)
class BirdEventsScreen extends ConsumerWidget {
  const BirdEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFlockId = ref.watch(selectedFlockIdProvider);
    final flocksAsync = ref.watch(flocksProvider);

    // Get events - if only 1 flock, ignore the filter and show all
    final flocks = flocksAsync.value;
    final shouldIgnoreFilter = flocks != null && flocks.length == 1;
    final eventsAsync = shouldIgnoreFilter
        ? ref.watch(allBirdStatusEventsProvider)
        : ref.watch(birdStatusEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flock History'),
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
          const SizedBox(height: 8),
          const Divider(height: 1),
          // Events list
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                    ],
                  ),
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Events Yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bird additions and status changes will appear here.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group events by date
                final groupedEvents = _groupEventsByDate(events);

                return RefreshIndicator(
                  onRefresh: () async {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ref.invalidate(birdStatusEventsProvider);
                  },
                  child: ListView.builder(
                    padding: pagePadding(context),
                    itemCount: groupedEvents.length,
                    itemBuilder: (context, index) {
                      final group = groupedEvents[index];
                      return _EventDateGroup(
                        date: group.date,
                        events: group.events,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_DateGroup> _groupEventsByDate(List<BirdStatusEvent> events) {
    final groups = <DateTime, List<BirdStatusEvent>>{};

    for (final event in events) {
      final date = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      groups.putIfAbsent(date, () => []).add(event);
    }

    // Sort by date descending
    final sortedDates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedDates.map((date) => _DateGroup(date: date, events: groups[date]!)).toList();
  }
}

class _DateGroup {
  final DateTime date;
  final List<BirdStatusEvent> events;

  _DateGroup({required this.date, required this.events});
}

class _EventDateGroup extends StatelessWidget {
  final DateTime date;
  final List<BirdStatusEvent> events;

  const _EventDateGroup({
    required this.date,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Text(
            _formatDateHeader(date),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Event cards
        ...events.map((event) => _EventTile(event: event)),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat.MMMEd().format(date); // e.g., "Wed, Jan 15"
    } else {
      return DateFormat.yMMMd().format(date); // e.g., "Jan 15, 2024"
    }
  }
}

class _EventTile extends ConsumerWidget {
  final BirdStatusEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final birdAsync = ref.watch(birdByIdProvider(event.birdId));

    final (icon, color, label) = _getStatusDisplay(event.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: birdAsync.when(
          loading: () => const Text('Loading...'),
          error: (_, __) => Text(
            'Unknown Bird',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          data: (bird) => Text(
            bird?.name ?? 'Deleted Bird',
            style: bird == null
                ? TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  )
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            if (event.notes != null && event.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  event.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Text(
          DateFormat.jm().format(event.eventDate),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  (IconData, Color, String) _getStatusDisplay(String status) {
    return switch (status) {
      'active' => (Icons.add_circle_outline, Colors.green, 'Added to flock'),
      'deceased' => (Icons.favorite_border, Colors.grey, 'Passed away'),
      'sold' => (Icons.attach_money, Colors.blue, 'Sold'),
      'givenAway' => (Icons.card_giftcard, Colors.purple, 'Given away'),
      'deleted' => (Icons.delete_outline, Colors.red, 'Removed from records'),
      _ => (Icons.help_outline, Colors.grey, status),
    };
  }
}

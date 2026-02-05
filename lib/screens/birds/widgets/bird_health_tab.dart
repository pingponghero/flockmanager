import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/bird.dart';
import '../../../providers/medication_provider.dart';

/// Health tab showing medications and health notes for a bird
class BirdHealthTab extends ConsumerWidget {
  final Bird bird;

  const BirdHealthTab({super.key, required this.bird});

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
                        'Tap + to add health observations for ${bird.name}.',
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
                id: med.id,
                date: med.startDate,
                type: _HealthItemType.medication,
                title: med.medicationName,
                subtitle: med.dosage ?? '',
                notes: med.notes,
              ));
            }
            for (final note in notes) {
              items.add(_HealthItem(
                id: note.id,
                date: note.date,
                type: _HealthItemType.note,
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
                final isMed = item.type == _HealthItemType.medication;
                return Card(
                  clipBehavior: Clip.antiAlias,
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
                    trailing: item.type == _HealthItemType.note
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: item.type == _HealthItemType.note
                        ? () => context.push('/birds/${bird.id}/health/${item.id}')
                        : null,
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

enum _HealthItemType { medication, note }

class _HealthItem {
  final String id;
  final DateTime date;
  final _HealthItemType type;
  final String title;
  final String subtitle;
  final String? notes;

  _HealthItem({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    this.notes,
  });
}

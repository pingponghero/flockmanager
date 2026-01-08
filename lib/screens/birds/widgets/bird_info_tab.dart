import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/bird.dart';
import '../../../models/enums.dart';
import '../../../providers/flock_provider.dart';
import '../../../utils/edge_insets.dart';

/// Info tab showing bird basic information, dates, and details
class BirdInfoTab extends ConsumerWidget {
  final Bird bird;

  const BirdInfoTab({super.key, required this.bird});

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

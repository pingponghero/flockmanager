import 'dart:io';

import 'package:flutter/material.dart';

import '../models/bird.dart';

class DistributeEggsDialog extends StatelessWidget {
  final int eggCount;
  final List<Bird> birds;

  const DistributeEggsDialog({
    super.key,
    required this.eggCount,
    required this.birds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Distribute to each bird?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...birds.map(
                (bird) => _BirdDistributionRow(
                  bird: bird,
                  count: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Each bird gets 1 egg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () {
            final distribution = {for (final bird in birds) bird.id: 1};
            Navigator.of(context).pop(distribution);
          },
          child: const Text('Distribute'),
        ),
      ],
    );
  }
}

class _BirdDistributionRow extends StatelessWidget {
  final Bird bird;
  final int count;

  const _BirdDistributionRow({
    required this.bird,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Bird avatar (photo or placeholder)
            CircleAvatar(
              radius: 16,
              backgroundImage: bird.photoPrimary != null
                  ? FileImage(File(bird.photoPrimary!))
                  : null,
              child: bird.photoPrimary == null
                  ? const Icon(Icons.egg, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            // Bird name
            Expanded(
              child: Text(
                bird.name,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Egg count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

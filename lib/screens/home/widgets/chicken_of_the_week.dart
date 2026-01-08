import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/bird_provider.dart';

/// Displays the chicken of the week callout card
class ChickenOfTheWeek extends ConsumerWidget {
  const ChickenOfTheWeek({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chickenAsync = ref.watch(chickenOfTheWeekProvider);

    return chickenAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        final bird = data.bird;
        final title = data.title;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/birds/${bird.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Photo or fallback
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: bird.photoPrimary != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.file(
                                File(bird.photoPrimary!),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Image.asset(
                                    'assets/icons/cute_hen.png',
                                    width: 48,
                                    height: 48,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Image.asset(
                                'assets/icons/cute_hen.png',
                                width: 48,
                                height: 48,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                title,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Colors.amber.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bird.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (bird.breed != null)
                            Text(
                              bird.breed!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          if (bird.notes != null && bird.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bird.notes!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    // Photo strip
                    SizedBox(
                      width: 120,
                      child: bird.photoPrimary != null
                          ? Image.file(
                              File(bird.photoPrimary!),
                              fit: BoxFit.cover,
                              height: double.infinity,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Center(
                                  child: Image.asset(
                                    'assets/icons/cute_hen.png',
                                    width: 48,
                                    height: 48,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: Center(
                                child: Image.asset(
                                  'assets/icons/cute_hen.png',
                                  width: 48,
                                  height: 48,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                    ),
                    // Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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

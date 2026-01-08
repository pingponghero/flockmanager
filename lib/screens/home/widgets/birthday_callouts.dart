import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/bird_provider.dart';

/// Displays upcoming bird birthdays
class BirthdayCallouts extends ConsumerWidget {
  const BirthdayCallouts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthdaysAsync = ref.watch(upcomingBirthdaysProvider);

    return birthdaysAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (birthdays) {
        if (birthdays.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: birthdays.map((b) {
              final isToday = b.daysUntil == 0;
              final message = isToday
                  ? '${b.bird.name} turns ${b.age} today!'
                  : b.daysUntil == 1
                      ? "${b.bird.name}'s birthday is tomorrow!"
                      : "${b.bird.name}'s birthday is in ${b.daysUntil} days";

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => context.go('/birds/${b.bird.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.pink.shade50 : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday ? Colors.pink.shade200 : Colors.purple.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isToday ? Icons.cake : Icons.event,
                          color: isToday ? Colors.pink.shade600 : Colors.purple.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: isToday ? Colors.pink.shade900 : Colors.purple.shade900,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isToday)
                          const Text(
                            '🎂',
                            style: TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

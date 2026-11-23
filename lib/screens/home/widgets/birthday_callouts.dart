import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/bird_provider.dart';
import '../../../app/status_colors.dart';

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
                      color: isToday ? StatusColors.of(context).celebration.container : StatusColors.of(context).special.container,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday ? StatusColors.of(context).celebration.border : StatusColors.of(context).special.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isToday ? Icons.cake : Icons.event,
                          color: isToday ? StatusColors.of(context).celebration.icon : StatusColors.of(context).special.icon,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: isToday ? StatusColors.of(context).celebration.onContainer : StatusColors.of(context).special.onContainer,
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

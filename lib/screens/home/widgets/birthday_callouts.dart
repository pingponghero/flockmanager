import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/bird_provider.dart';
import '../../../app/status_colors.dart';
import '../../../widgets/tappable_tile.dart';

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
                child: TappableTile(
                  onTap: () => context.go('/birds/${b.bird.id}'),
                  padding: const EdgeInsets.all(12),
                  color: isToday ? StatusColors.of(context).celebration.container : StatusColors.of(context).special.container,
                  borderColor: isToday ? StatusColors.of(context).celebration.border : StatusColors.of(context).special.border,
                  radius: 12,
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
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

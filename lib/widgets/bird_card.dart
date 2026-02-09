import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/breeds.dart';
import '../models/bird.dart';
import '../models/enums.dart';

/// Reusable card widget for displaying bird information.
class BirdCard extends StatelessWidget {
  final Bird bird;
  final VoidCallback? onTap;
  final int? eggCount;

  const BirdCard({
    super.key,
    required this.bird,
    this.onTap,
    this.eggCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        bird.photoPrimary != null && File(bird.photoPrimary!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Opacity(
        opacity: bird.status == BirdStatus.active ? 1.0 : 0.6,
        child: SizedBox(
          height: 116,
          child: Row(
            children: [
              // Photo strip — left ~38% of card
              SizedBox(
                width: 120,
                child: hasPhoto
                    ? GestureDetector(
                        onTap: onTap,
                        child: Image.file(
                          File(bird.photoPrimary!),
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                        ),
                      )
                    : GestureDetector(
                        onTap: () => context.push(
                          '/birds/${bird.id}/edit?openPhoto=true',
                        ),
                        child: Container(
                          color: _eggTintColor(bird.eggColor) ??
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                  'assets/icons/cute_hen.png',
                                  width: 64,
                                  height: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_a_photo,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              // Text content — right ~62%
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Name
                        Text(
                          bird.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Breed
                        if (bird.breed != null && bird.breed!.isNotEmpty)
                          Text(
                            bird.breed!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        // Age and egg count row
                        Row(
                          children: [
                            if (bird.ageInWeeks != null) ...[
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatAge(bird.ageInWeeks!),
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (bird.ageInWeeks != null && eggCount != null)
                              const SizedBox(width: 16),
                            if (eggCount != null) ...[
                              Icon(
                                Icons.egg,
                                size: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$eggCount eggs',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                        // Status row
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              bird.status.icon,
                              size: 14,
                              color: bird.status.iconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bird.status.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: bird.status.iconColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _eggColorMap = {
    for (final e in EggColor.values)
      e.name.toLowerCase(): e,
    // Also map display names (e.g. "Dark Brown" -> darkBrown)
    for (final b in breeds)
      b.eggColorDisplay.toLowerCase(): b.eggColor,
  };

  static Color? _eggTintColor(String? eggColor) {
    if (eggColor == null || eggColor.isEmpty) return null;
    final parsed = _eggColorMap[eggColor.toLowerCase()];
    if (parsed == null) return null;
    return switch (parsed) {
      EggColor.white => const Color(0xFFF5F0E8).withValues(alpha: 0.5),
      EggColor.cream => const Color(0xFFF5E6C8).withValues(alpha: 0.4),
      EggColor.brown => const Color(0xFFC8A882).withValues(alpha: 0.25),
      EggColor.darkBrown => const Color(0xFFA0764A).withValues(alpha: 0.25),
      EggColor.chocolate => const Color(0xFF7B4B2A).withValues(alpha: 0.25),
      EggColor.blue => const Color(0xFF9BC4E2).withValues(alpha: 0.3),
      EggColor.green => const Color(0xFFA8D5BA).withValues(alpha: 0.3),
      EggColor.olive => const Color(0xFFB5C48C).withValues(alpha: 0.3),
      EggColor.pink => const Color(0xFFF2C6C2).withValues(alpha: 0.3),
      EggColor.tinted => const Color(0xFFE8D5C4).withValues(alpha: 0.3),
    };
  }

  String _formatAge(int weeks) {
    if (weeks < 52) {
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
    }
    final years = weeks ~/ 52;
    final remainingWeeks = weeks % 52;
    if (remainingWeeks == 0) {
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
    return '$years ${years == 1 ? 'yr' : 'yrs'}, $remainingWeeks wks';
  }
}


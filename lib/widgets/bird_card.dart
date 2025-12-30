import 'dart:io';

import 'package:flutter/material.dart';

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
    final isActive = bird.status == BirdStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isActive ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Photo or placeholder
                _BirdPhoto(photoPath: bird.photoPrimary),
                const SizedBox(width: 12),
                // Bird info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and status indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bird.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isActive)
                            _StatusBadge(status: bird.status),
                        ],
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
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatAge(bird.ageInWeeks!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (bird.ageInWeeks != null && eggCount != null)
                            const SizedBox(width: 16),
                          if (eggCount != null) ...[
                            Icon(
                              Icons.egg,
                              size: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$eggCount eggs',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
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

class _BirdPhoto extends StatelessWidget {
  final String? photoPath;

  const _BirdPhoto({this.photoPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoPath != null && File(photoPath!).existsSync()
          ? Image.file(
              File(photoPath!),
              fit: BoxFit.cover,
            )
          : Image.asset(
              'assets/icons/cute_hen.png',
              width: 32,
              height: 32,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BirdStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      BirdStatus.active => (Colors.green, Icons.check_circle),
      BirdStatus.deceased => (Colors.grey, Icons.block),
      BirdStatus.sold => (Colors.blue, Icons.sell),
      BirdStatus.givenAway => (Colors.orange, Icons.volunteer_activism),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

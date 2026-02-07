import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/bird.dart';
import '../../../models/enums.dart';

/// Header widget displaying bird photo, name, breed, and age
class BirdHeader extends StatelessWidget {
  final Bird bird;

  const BirdHeader({super.key, required this.bird});

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        bird.photoPrimary != null && File(bird.photoPrimary!).existsSync();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo or fallback background
        if (hasPhoto)
          Image.file(
            File(bird.photoPrimary!),
            fit: BoxFit.cover,
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/cute_hen.png',
                width: 80,
                height: 80,
                color: Colors.white70,
              ),
            ),
          ),

        // Gradient overlay for text readability
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 140,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),

        // Text content at bottom
        Positioned(
          left: 20,
          right: 20,
          bottom: 16,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text(
                  bird.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                // Breed and age
                Row(
                  children: [
                    if (bird.breed != null && bird.breed!.isNotEmpty) ...[
                      Text(
                        bird.breed!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (bird.ageInWeeks != null)
                        const Text(' • ',
                            style: TextStyle(color: Colors.white70)),
                    ],
                    if (bird.ageInWeeks != null)
                      Text(
                        _formatAge(bird.ageInWeeks!),
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
                // Status badge for non-active
                if (bird.status != BirdStatus.active) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bird.status.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatAge(int weeks) {
    if (weeks < 52) {
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} old';
    }
    final years = weeks ~/ 52;
    return '$years ${years == 1 ? 'year' : 'years'} old';
  }
}

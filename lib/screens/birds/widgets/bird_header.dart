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
    return Container(
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
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Photo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: bird.photoPrimary != null && File(bird.photoPrimary!).existsSync()
                  ? Image.file(File(bird.photoPrimary!), fit: BoxFit.cover)
                  : Image.asset(
                      'assets/icons/cute_hen.png',
                      width: 50,
                      height: 50,
                      color: Colors.white70,
                    ),
            ),
            const SizedBox(height: 16),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (bird.breed != null && bird.breed!.isNotEmpty) ...[
                  Text(
                    bird.breed!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (bird.ageInWeeks != null)
                    const Text(' • ', style: TextStyle(color: Colors.white70)),
                ],
                if (bird.ageInWeeks != null)
                  Text(
                    _formatAge(bird.ageInWeeks!),
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Status badge for non-active
            if (bird.status != BirdStatus.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        ),
      ),
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

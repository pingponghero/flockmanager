import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/bird.dart';
import '../../../providers/bird_provider.dart';
import '../../../providers/egg_provider.dart';

/// Swipable gallery of all living birds in the flock.
class FlockSpotlight extends ConsumerStatefulWidget {
  const FlockSpotlight({super.key});

  @override
  ConsumerState<FlockSpotlight> createState() => _FlockSpotlightState();
}

class _FlockSpotlightState extends ConsumerState<FlockSpotlight> {
  PageController? _pageController;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// Resolve starting page from saved bird ID or week-of-year fallback.
  int _resolveStartIndex(List<Bird> birds, String? savedBirdId) {
    if (savedBirdId != null) {
      final idx = birds.indexWhere((b) => b.id == savedBirdId);
      if (idx >= 0) return idx;
    }
    // Week-of-year fallback (same rotation logic as the old chicken-of-week)
    final now = DateTime.now();
    final weekOfYear =
        ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor();
    return weekOfYear % birds.length;
  }

  @override
  Widget build(BuildContext context) {
    final birdsAsync = ref.watch(livingBirdsProvider);
    final savedIdAsync = ref.watch(flockSpotlightBirdIdProvider);

    return birdsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (birds) {
        if (birds.isEmpty) return const SizedBox.shrink();

        // Sort by ID for consistent ordering
        final sorted = [...birds]..sort((a, b) => a.id.compareTo(b.id));
        final savedId = savedIdAsync.value;

        // Initialize page controller once
        if (_pageController == null) {
          final startIndex = _resolveStartIndex(sorted, savedId);
          _currentPage = startIndex;
          // Large virtual count for infinite scrolling
          final initialPage = sorted.length > 1
              ? 5000 * sorted.length + startIndex
              : 0;
          _pageController = PageController(initialPage: initialPage);
        }

        final showDots = sorted.length > 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: !showDots
                    ? _BirdCard(bird: sorted.first)
                    : PageView.builder(
                        controller: _pageController,
                        onPageChanged: (page) {
                          final idx = page % sorted.length;
                          setState(() => _currentPage = idx);
                          ref
                              .read(flockSpotlightBirdIdProvider.notifier)
                              .saveBird(sorted[idx].id);
                        },
                        itemBuilder: (context, index) {
                          final bird = sorted[index % sorted.length];
                          return _BirdCard(bird: bird);
                        },
                      ),
              ),
              if (showDots)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _HorizontalDots(
                    count: sorted.length,
                    current: _currentPage,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Single bird card used in the spotlight page view.
class _BirdCard extends ConsumerWidget {
  final Bird bird;

  const _BirdCard({required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggCount =
        ref.watch(totalEggCountByBirdProvider(bird.id)).value ?? 0;
    final detailStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/birds/${bird.id}'),
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
                      errorBuilder: (_, __, ___) => _PlaceholderPhoto(),
                    )
                  : _PlaceholderPhoto(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Flock Spotlight',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bird.name,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (bird.breed != null)
                      Text(bird.breed!, style: detailStyle),
                    if (bird.notes != null && bird.notes!.isNotEmpty)
                      Text(
                        bird.notes!,
                        style: detailStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (eggCount > 0)
                      Text(
                        '$eggCount egg${eggCount == 1 ? '' : 's'}',
                        style: detailStyle,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder bird photo when no image is available.
class _PlaceholderPhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Image.asset(
          'assets/icons/cute_hen.png',
          width: 48,
          height: 48,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Compact horizontal dots below the card.
class _HorizontalDots extends StatelessWidget {
  final int count;
  final int current;

  const _HorizontalDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    const maxVisible = 7;
    final showAll = count <= maxVisible;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        showAll ? count : maxVisible,
        (i) {
          final int dotIndex;
          if (showAll) {
            dotIndex = i;
          } else {
            final half = maxVisible ~/ 2;
            dotIndex = (current - half + i) % count;
          }
          final isActive = dotIndex == current;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: isActive ? 6 : 4,
            height: isActive ? 6 : 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/bird.dart';
import '../../../providers/bird_provider.dart';
import '../../../providers/egg_provider.dart';
import '../../../services/photo_storage.dart';
import '../../../app/status_colors.dart';

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
                height: 184,
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

/// Single bird card used in the spotlight page view: a full-bleed photo with
/// the bird's name over a gradient, like the bird detail header (#68).
class _BirdCard extends ConsumerWidget {
  final Bird bird;

  const _BirdCard({required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggCount =
        ref.watch(totalEggCountByBirdProvider(bird.id)).value ?? 0;
    final theme = Theme.of(context);
    final subtitle = [
      if (bird.breed != null && bird.breed!.isNotEmpty) bird.breed!,
      if (eggCount > 0) '$eggCount egg${eggCount == 1 ? '' : 's'}',
    ].join(' · ');

    final photo = bird.photoFile;
    final hasPhoto = photo != null;
    // Over a photo: white text on a dark scrim. Without one: a soft tint
    // with theme text, since a scrim over a pastel turns muddy.
    final nameColor = hasPhoto ? Colors.white : theme.colorScheme.onSurface;
    final detailColor =
        hasPhoto ? Colors.white70 : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/birds/${bird.id}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto) ...[
                Image.file(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.45, 1],
                      colors: [Colors.transparent, Color(0xB3000000)],
                    ),
                  ),
                ),
              ] else
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/icons/cute_hen.png',
                      width: 96,
                      height: 96,
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPhoto
                        ? Colors.black.withValues(alpha: 0.35)
                        : theme.colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: hasPhoto
                            ? Colors.amber.shade200
                            : StatusColors.of(context).warning.icon,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Flock Spotlight',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: nameColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: hasPhoto ? 16 : 128,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bird.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: nameColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: detailColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
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

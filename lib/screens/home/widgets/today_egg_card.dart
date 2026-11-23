import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/egg_provider.dart';
import '../../../providers/trial_provider.dart';
import '../../../widgets/egg_quick_log.dart';
import '../../../widgets/trial_banner.dart' show showTrialExpiredDialog;
import '../../../utils/motion.dart';

/// Hero card for today's egg count — the visual anchor of Home (#68).
///
/// Filled with the palette's primary colour so it clearly outranks the
/// quieter cards below it. With nothing logged yet it invites a tap to log;
/// otherwise it compares today against the weekly average.
class TodayEggCard extends ConsumerWidget {
  final String? selectedFlockId;

  const TodayEggCard({super.key, this.selectedFlockId});

  /// Foreground for text and icons on [background]: whichever of black or
  /// white reads better, so every palette works in light and dark mode.
  static Color foregroundOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : Colors.black;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayEggCountByFlockProvider);
    final avgAsync = ref.watch(weeklyAverageEggCountProvider);
    final canEdit = ref.watch(canEditProvider);

    final todayCount = todayAsync.value ?? 0;
    final avg = avgAsync.value ?? 0;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fg = foregroundOn(primary);
    final shaded = Color.lerp(primary, Colors.black, 0.18)!;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, shaded],
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (todayCount == 0 && canEdit) {
              await showEggQuickLog(context);
            } else if (todayCount == 0 && !canEdit) {
              showTrialExpiredDialog(context, ref);
            } else {
              final today = DateTime.now();
              context.push('/eggs',
                  extra: DateTime(today.year, today.month, today.day));
            }
          },
          child: Stack(
            children: [
              // Decorative hen watermark, bleeding off the corner
              Positioned(
                right: -20,
                bottom: -28,
                child: Image.asset(
                  'assets/icons/cute_hen.png',
                  width: 150,
                  height: 150,
                  color: fg.withValues(alpha: 0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's eggs",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: fg.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Cross-fade loading → number, then count up (#69)
                    AnimatedSwitcher(
                      duration: motionDuration(
                          context, const Duration(milliseconds: 250)),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: todayAsync.when(
                      loading: () => SizedBox(
                        key: const ValueKey('loading'),
                        height: 64,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircularProgressIndicator(color: fg),
                        ),
                      ),
                      error: (error, stack) => Text(
                        '--',
                        key: const ValueKey('error'),
                        style: theme.textTheme.displayLarge
                            ?.copyWith(color: fg, fontWeight: FontWeight.bold),
                      ),
                      data: (today) => TweenAnimationBuilder<int>(
                        key: const ValueKey('count'),
                        tween: IntTween(begin: 0, end: today),
                        duration: motionDuration(
                            context, const Duration(milliseconds: 600)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          '$value',
                          semanticsLabel: '$today',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.bold,
                            height: 1.05,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 8),
                    if (todayCount == 0)
                      _Pill(
                        fg: fg,
                        icon: Icons.add_circle_outline,
                        label: avg > 0
                            ? 'Tap to log · avg ${avg.toStringAsFixed(1)}'
                            : "Tap to log today's eggs",
                      )
                    else if (avg > 0)
                      _TrendPill(fg: fg, today: todayCount, average: avg),
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

/// Today vs. the weekly average. Only calls out deviations of 25%+ so
/// normal day-to-day wobble doesn't read as good or bad news.
class _TrendPill extends StatelessWidget {
  final Color fg;
  final int today;
  final double average;

  const _TrendPill({
    required this.fg,
    required this.today,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    final percentDiff = (today - average) / average;
    final icon = percentDiff >= 0.25
        ? Icons.arrow_upward
        : percentDiff <= -0.25
            ? Icons.arrow_downward
            : Icons.remove;
    return _Pill(
      fg: fg,
      icon: icon,
      label: 'avg ${average.toStringAsFixed(1)}',
    );
  }
}

class _Pill extends StatelessWidget {
  final Color fg;
  final IconData icon;
  final String label;

  const _Pill({required this.fg, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// How a [StatCard] arranges its icon, value and label.
enum StatCardLayout {
  /// Icon on top, value, then label — for rows of three (Home, bird detail).
  stacked,

  /// Icon on the left, then label, value and optional subtitle — for
  /// two-column grids with more room (Stats).
  inline,
}

/// The app's one stat tile (#63): a quiet tinted surface with a number.
///
/// Replaces three slightly different private `_StatCard`/`_StatItem`
/// widgets on Home, Stats and bird detail. Values use tabular figures so
/// they don't jiggle as they change. Tappable when [onTap] is set.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  /// Usually an [Icon]; any widget works (e.g. the hen image). Sized and
  /// tinted through [IconTheme].
  final Widget icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final StatCardLayout layout;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.onTap,
    this.layout = StatCardLayout.stacked,
  });

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);

    final stacked = layout == StatCardLayout.stacked;
    final tintedIcon = IconTheme(
      data: IconThemeData(
        size: stacked ? 20 : 28,
        color: iconColor ?? scheme.primary,
      ),
      child: icon,
    );

    final content = stacked
        ? Column(
            children: [
              tintedIcon,
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: _tabular,
                ),
              ),
              Text(label, style: muted, textAlign: TextAlign.center),
              if (subtitle != null)
                Text(subtitle!, style: muted, textAlign: TextAlign.center),
            ],
          )
        : Row(
            children: [
              tintedIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: muted),
                    Text(
                      value,
                      // titleLarge, not headlineSmall: headlines use the
                      // serif heading font, numbers stay tabular (#67)
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFeatures: _tabular,
                      ),
                    ),
                    if (subtitle != null) Text(subtitle!, style: muted),
                  ],
                ),
              ),
            ],
          );

    return Material(
      color: scheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: content),
      ),
    );
  }
}

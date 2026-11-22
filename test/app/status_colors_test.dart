import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/app/status_colors.dart';
import 'package:flock_manager/app/theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  /// #55: banners, badges and pills must be readable in both modes, on every
  /// palette's card and scaffold surfaces.
  group('StatusColors contrast', () {
    for (final palette in AppPalette.values) {
      for (final brightness in Brightness.values) {
        test('${palette.name} ${brightness.name}', () {
          final theme = AppTheme.buildTheme(palette, brightness: brightness);
          final status = theme.extension<StatusColors>()!;
          final tones = {
            'warning': status.warning,
            'danger': status.danger,
            'info': status.info,
            'success': status.success,
            'celebration': status.celebration,
            'special': status.special,
            'caution': status.caution,
            'neutral': status.neutral,
          };
          final surfaces = [theme.scaffoldBackgroundColor, theme.cardColor];

          for (final MapEntry(key: name, value: tone) in tones.entries) {
            for (final surface in surfaces) {
              final bg = Color.alphaBlend(tone.container, surface);
              final strongBg = Color.alphaBlend(tone.strongContainer, surface);
              expect(_contrast(tone.onContainer, bg), greaterThanOrEqualTo(4.5),
                  reason: '$name text on container');
              expect(_contrast(tone.onContainerMuted, strongBg),
                  greaterThanOrEqualTo(4.5),
                  reason: '$name muted text on strong container');
              // Icons and large accent text: WCAG non-text / large text 3:1.
              expect(_contrast(tone.icon, bg), greaterThanOrEqualTo(3),
                  reason: '$name icon on container');
            }
          }
        });
      }
    }
  });

  test('dark containers stay dark instead of pastel blocks', () {
    final theme =
        AppTheme.buildTheme(AppPalette.barnRed, brightness: Brightness.dark);
    final warning = theme.extension<StatusColors>()!.warning;
    final bg = Color.alphaBlend(warning.container, theme.scaffoldBackgroundColor);
    expect(bg.computeLuminance(), lessThan(0.1));
  });

  test('light mode keeps the existing Material shades', () {
    final status = StatusColors.forBrightness(Brightness.light);
    expect(status.warning.container, Colors.amber.shade50);
    expect(status.danger.icon, Colors.red.shade700);
    expect(status.danger.onContainer, Colors.red.shade900);
    // Amber's own 900 fails contrast on amber 50, so it is darkened.
    expect(status.warning.onContainer, isNot(Colors.amber.shade900));
  });
}

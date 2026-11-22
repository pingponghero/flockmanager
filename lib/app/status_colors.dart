import 'package:flutter/material.dart';

/// One semantic colour tone (warning, danger, …) resolved for the current
/// brightness.
///
/// In light mode these are the familiar Material swatch steps (50 container,
/// 700 icon, 900 text). In dark mode the containers become translucent tints
/// of the swatch over whatever surface they sit on, and the foregrounds use
/// the light end of the swatch so they stay readable on dark backgrounds.
@immutable
class Tone {
  /// Subtle background for banners and callouts.
  final Color container;

  /// Slightly stronger background for small badges and pills.
  final Color strongContainer;

  /// Outline around [container].
  final Color border;

  /// Icons and accent text, on [container] or on the plain surface.
  final Color icon;

  /// Secondary text on [container].
  final Color onContainerMuted;

  /// Primary text on [container].
  final Color onContainer;

  const Tone({
    required this.container,
    required this.strongContainer,
    required this.border,
    required this.icon,
    required this.onContainerMuted,
    required this.onContainer,
  });

  factory Tone.fromSwatch(MaterialColor swatch, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return Tone(
        container: swatch.shade300.withValues(alpha: 0.12),
        strongContainer: swatch.shade300.withValues(alpha: 0.2),
        border: swatch.shade300.withValues(alpha: 0.35),
        icon: swatch.shade300,
        onContainerMuted: swatch.shade200,
        onContainer: swatch.shade100,
      );
    }
    return Tone(
      container: swatch.shade50,
      strongContainer: swatch.shade100,
      border: swatch.shade200,
      // Yellow-ish swatches (amber, orange) have light 700–900 steps that
      // fail contrast on their own 50/100 tints, so darken just those.
      icon: _darkenToContrast(swatch.shade700, swatch.shade50, 3),
      onContainerMuted:
          _darkenToContrast(swatch.shade800, swatch.shade100, 4.5),
      onContainer: _darkenToContrast(swatch.shade900, swatch.shade50, 4.5),
    );
  }

  /// Darkens [fg] towards black, keeping its hue, until it reaches [ratio]
  /// contrast against [bg]. Returns [fg] unchanged if it already does.
  static Color _darkenToContrast(Color fg, Color bg, double ratio) {
    var c = fg;
    for (var i = 0; i < 20 && contrastRatio(c, bg) < ratio; i++) {
      c = Color.lerp(c, Colors.black, 0.08)!;
    }
    return c;
  }

  /// WCAG 2 contrast ratio between two opaque colours.
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
  }

  static Tone lerp(Tone a, Tone b, double t) => Tone(
    container: Color.lerp(a.container, b.container, t)!,
    strongContainer: Color.lerp(a.strongContainer, b.strongContainer, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    icon: Color.lerp(a.icon, b.icon, t)!,
    onContainerMuted: Color.lerp(a.onContainerMuted, b.onContainerMuted, t)!,
    onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
  );
}

/// Semantic status colours that work in both light and dark mode.
///
/// Use `StatusColors.of(context).warning.container` etc. instead of
/// hard-coding `Colors.amber.shade50`, which renders as a glaring pastel
/// block on dark surfaces (#55).
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  /// Amber — withdrawal periods, highlights, forecasts.
  final Tone warning;

  /// Red — banned drugs, destructive states.
  final Tone danger;

  /// Blue — informational notes.
  final Tone info;

  /// Green — approved, positive trends.
  final Tone success;

  /// Pink — birthdays today.
  final Tone celebration;

  /// Purple — upcoming birthdays, prescription-only.
  final Tone special;

  /// Orange — streaks, unknown withdrawal, medications.
  final Tone caution;

  /// Grey — neutral pills and trends.
  final Tone neutral;

  const StatusColors({
    required this.warning,
    required this.danger,
    required this.info,
    required this.success,
    required this.celebration,
    required this.special,
    required this.caution,
    required this.neutral,
  });

  factory StatusColors.forBrightness(Brightness brightness) => StatusColors(
    warning: Tone.fromSwatch(Colors.amber, brightness),
    danger: Tone.fromSwatch(Colors.red, brightness),
    info: Tone.fromSwatch(Colors.blue, brightness),
    success: Tone.fromSwatch(Colors.green, brightness),
    celebration: Tone.fromSwatch(Colors.pink, brightness),
    special: Tone.fromSwatch(Colors.purple, brightness),
    caution: Tone.fromSwatch(Colors.orange, brightness),
    neutral: Tone.fromSwatch(Colors.grey, brightness),
  );

  /// The app's status colours. Falls back to light-mode colours when the
  /// theme has no [StatusColors] (e.g. bare `MaterialApp` in tests).
  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatusColors>() ??
        StatusColors.forBrightness(theme.brightness);
  }

  @override
  StatusColors copyWith({
    Tone? warning,
    Tone? danger,
    Tone? info,
    Tone? success,
    Tone? celebration,
    Tone? special,
    Tone? caution,
    Tone? neutral,
  }) => StatusColors(
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    info: info ?? this.info,
    success: success ?? this.success,
    celebration: celebration ?? this.celebration,
    special: special ?? this.special,
    caution: caution ?? this.caution,
    neutral: neutral ?? this.neutral,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      warning: Tone.lerp(warning, other.warning, t),
      danger: Tone.lerp(danger, other.danger, t),
      info: Tone.lerp(info, other.info, t),
      success: Tone.lerp(success, other.success, t),
      celebration: Tone.lerp(celebration, other.celebration, t),
      special: Tone.lerp(special, other.special, t),
      caution: Tone.lerp(caution, other.caution, t),
      neutral: Tone.lerp(neutral, other.neutral, t),
    );
  }
}

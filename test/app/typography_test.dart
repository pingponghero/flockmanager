import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/app/theme.dart';

/// #67: Fraunces for headings, the platform font for body text and numbers.
void main() {
  for (final brightness in Brightness.values) {
    test('headings use Fraunces, numbers do not (${brightness.name})', () {
      final theme =
          AppTheme.buildTheme(AppPalette.sage, brightness: brightness);
      final t = theme.textTheme;

      for (final style in [t.headlineLarge, t.headlineMedium, t.headlineSmall]) {
        expect(style?.fontFamily, AppTheme.headingFontFamily);
      }
      expect(theme.appBarTheme.titleTextStyle?.fontFamily,
          AppTheme.headingFontFamily);

      // Number-carrying styles keep the platform font so tabular figures
      // work (Fraunces has proportional digits and no tnum feature).
      for (final style in [
        t.displayLarge,
        t.titleLarge,
        t.titleMedium,
        t.bodyMedium,
        t.labelMedium,
      ]) {
        expect(style?.fontFamily, isNot(AppTheme.headingFontFamily));
      }
    });
  }

  test('font files and licence are bundled', () {
    for (final path in [
      'assets/fonts/Fraunces-SemiBold.ttf',
      'assets/fonts/Fraunces-Bold.ttf',
      'assets/fonts/Fraunces-OFL.txt',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Fraunces'));
    expect(pubspec, contains('assets/fonts/Fraunces-OFL.txt'));
  });
}

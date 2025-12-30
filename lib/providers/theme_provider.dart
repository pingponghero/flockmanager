import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme.dart';

const _paletteKey = 'selected_palette';
const _themeModeKey = 'theme_mode';

/// Provider for the selected app palette
class ThemeNotifier extends Notifier<AppPalette> {
  @override
  AppPalette build() {
    _loadSavedPalette();
    return AppPalette.barnRed; // Default palette
  }

  Future<void> _loadSavedPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_paletteKey);
    if (savedIndex != null && savedIndex < AppPalette.values.length) {
      state = AppPalette.values[savedIndex];
    }
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, palette.index);
  }
}

/// Provider for the current app palette
final themeProvider = NotifierProvider<ThemeNotifier, AppPalette>(() {
  return ThemeNotifier();
});

/// Provider for theme mode (light/dark/system)
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSavedMode();
    return ThemeMode.system; // Default to system
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_themeModeKey);
    if (savedIndex != null && savedIndex < ThemeMode.values.length) {
      state = ThemeMode.values[savedIndex];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }
}

/// Provider for the current theme mode
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

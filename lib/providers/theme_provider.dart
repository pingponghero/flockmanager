import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme.dart';

const _themeKey = 'selected_palette';

/// Provider for the selected app palette
class ThemeNotifier extends Notifier<AppPalette> {
  @override
  AppPalette build() {
    _loadSavedPalette();
    return AppPalette.barnRed; // Default palette
  }

  Future<void> _loadSavedPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_themeKey);
    if (savedIndex != null && savedIndex < AppPalette.values.length) {
      state = AppPalette.values[savedIndex];
    }
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, palette.index);
  }
}

/// Provider for the current app palette
final themeProvider = NotifierProvider<ThemeNotifier, AppPalette>(() {
  return ThemeNotifier();
});

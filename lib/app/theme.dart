import 'package:flutter/material.dart';

/// Available color palettes for the app
enum AppPalette {
  barnRed,
  sage,
  eggInspired,
}

extension AppPaletteExtension on AppPalette {
  String get displayName {
    switch (this) {
      case AppPalette.barnRed:
        return 'Barn Red';
      case AppPalette.sage:
        return 'Sage & Terracotta';
      case AppPalette.eggInspired:
        return 'Egg-Inspired';
    }
  }

  String get description {
    switch (this) {
      case AppPalette.barnRed:
        return 'Traditional farmhouse nostalgia';
      case AppPalette.sage:
        return 'Modern homesteader aesthetic';
      case AppPalette.eggInspired:
        return 'Beautiful egg color spectrum';
    }
  }

  String get iconAsset {
    switch (this) {
      case AppPalette.barnRed:
        return 'assets/icons/app_icon_barn_red_transparent.png';
      case AppPalette.sage:
        return 'assets/icons/app_icon_terracotta_transparent.png';
      case AppPalette.eggInspired:
        return 'assets/icons/app_icon_light_transparent.png';
    }
  }

  ColorPaletteData get colors {
    switch (this) {
      case AppPalette.barnRed:
        return ColorPaletteData(
          primary: const Color(0xFF9B2D30),
          surface: const Color(0xFFFDF6E3),
          accent: const Color(0xFFD4A84B),
          text: const Color(0xFF3D3028),
        );
      case AppPalette.sage:
        return ColorPaletteData(
          primary: const Color(0xFF6B7F5E),
          surface: const Color(0xFFFAF7F2),
          accent: const Color(0xFFC67B5C),
          text: const Color(0xFF2C3E2D),
        );
      case AppPalette.eggInspired:
        return ColorPaletteData(
          primary: const Color(0xFF5B8C85),
          surface: const Color(0xFFF5F0E6),
          accent: const Color(0xFF6B4423),
          secondary: const Color(0xFF7D8B6A),
          text: const Color(0xFF3D3D3D),
        );
    }
  }

  ColorPaletteData get darkColors {
    switch (this) {
      case AppPalette.barnRed:
        return ColorPaletteData(
          primary: const Color(0xFFCF6B6E),
          surface: const Color(0xFF1A1512),
          accent: const Color(0xFFE5C078),
          text: const Color(0xFFE8E0D8),
          cardColor: const Color(0xFF2A2220),
        );
      case AppPalette.sage:
        return ColorPaletteData(
          primary: const Color(0xFF8FA87E),
          surface: const Color(0xFF151A15),
          accent: const Color(0xFFD9967D),
          text: const Color(0xFFE0E5DF),
          cardColor: const Color(0xFF1F261F),
        );
      case AppPalette.eggInspired:
        return ColorPaletteData(
          primary: const Color(0xFF7DB3AC),
          surface: const Color(0xFF161614),
          accent: const Color(0xFF9B7453),
          secondary: const Color(0xFF9DAB8A),
          text: const Color(0xFFE5E3DF),
          cardColor: const Color(0xFF222220),
        );
    }
  }
}

/// Color data for a palette
class ColorPaletteData {
  final Color primary;
  final Color surface;
  final Color accent;
  final Color? secondary;
  final Color text;
  final Color? cardColor;

  const ColorPaletteData({
    required this.primary,
    required this.surface,
    required this.accent,
    this.secondary,
    required this.text,
    this.cardColor,
  });
}

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme(AppPalette palette, {Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? palette.darkColors : palette.colors;
    final textSecondary = colors.text.withValues(alpha: 0.7);
    final textHint = colors.text.withValues(alpha: 0.5);
    final cardColor = colors.cardColor ?? (isDark ? const Color(0xFF2A2A2A) : Colors.white);
    final appBarColor = isDark ? colors.surface : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
        primary: colors.primary,
        secondary: colors.secondary ?? colors.accent,
        surface: colors.surface,
        error: isDark ? const Color(0xFFCF6679) : const Color(0xFFB00020),
      ),

      // Scaffold
      scaffoldBackgroundColor: colors.surface,

      // App bar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: appBarColor,
        foregroundColor: colors.text,
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.text.withValues(alpha: isDark ? 0.15 : 0.1)),
        ),
        color: cardColor,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.text.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.text.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFFCF6679) : const Color(0xFFB00020)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: colors.primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colors.text.withValues(alpha: 0.08),
        selectedColor: colors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        labelStyle: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colors.text.withValues(alpha: isDark ? 0.15 : 0.1),
        thickness: 1,
        space: 1,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors.text,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colors.text,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors.text,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.text,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: textHint,
        ),
      ),
    );
  }
}

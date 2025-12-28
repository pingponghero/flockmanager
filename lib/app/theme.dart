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
}

/// Color data for a palette
class ColorPaletteData {
  final Color primary;
  final Color surface;
  final Color accent;
  final Color? secondary;
  final Color text;

  const ColorPaletteData({
    required this.primary,
    required this.surface,
    required this.accent,
    this.secondary,
    required this.text,
  });
}

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme(AppPalette palette) {
    final colors = palette.colors;
    final textSecondary = colors.text.withValues(alpha: 0.7);
    final textHint = colors.text.withValues(alpha: 0.5);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.light,
        primary: colors.primary,
        secondary: colors.secondary ?? colors.accent,
        surface: colors.surface,
        error: const Color(0xFFB00020),
      ),

      // Scaffold
      scaffoldBackgroundColor: colors.surface,

      // App bar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
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
          side: BorderSide(color: colors.text.withValues(alpha: 0.1)),
        ),
        color: Colors.white,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
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
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: colors.primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colors.text.withValues(alpha: 0.08),
        selectedColor: colors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colors.text.withValues(alpha: 0.1),
        thickness: 1,
        space: 1,
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

import 'package:flutter/material.dart';

class AppTheme {
  static const _sand0 = Color(0xFFEDEDE9);
  static const _sand1 = Color(0xFFD6CCC2);
  static const _sand2 = Color(0xFFF5EBE0);
  static const _sand3 = Color(0xFFE3D5CA);
  static const _sand4 = Color(0xFFD5BDAF);

  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF6B4F3A),
      onPrimary: Colors.white,
      primaryContainer: _sand3,
      onPrimaryContainer: const Color(0xFF2A1B12),
      secondary: const Color(0xFF8A6A55),
      onSecondary: Colors.white,
      secondaryContainer: _sand1,
      onSecondaryContainer: const Color(0xFF2A1B12),
      tertiary: const Color(0xFF6C6F3B),
      onTertiary: Colors.white,
      tertiaryContainer: _sand2,
      onTertiaryContainer: const Color(0xFF1E220E),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: const Color(0xFFF9DEDC),
      onErrorContainer: const Color(0xFF410E0B),
      surface: _sand0,
      onSurface: const Color(0xFF1B1B1B),
      surfaceContainerHighest: Colors.white,
      onSurfaceVariant: const Color(0xFF3D3D3D),
      outline: const Color(0xFFB0A79E),
      outlineVariant: const Color(0xFFD4CCC4),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFF2B2B2B),
      onInverseSurface: _sand0,
      inversePrimary: _sand4,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFFE9E9EA),
      onPrimary: const Color(0xFF111216),
      primaryContainer: const Color(0xFF2B2F3A),
      onPrimaryContainer: const Color(0xFFE9E9EA),
      secondary: const Color(0xFFB7B9C3),
      onSecondary: const Color(0xFF111216),
      secondaryContainer: const Color(0xFF1B1D24),
      onSecondaryContainer: const Color(0xFFE9E9EA),
      tertiary: const Color(0xFFB9C6FF),
      onTertiary: const Color(0xFF0B1020),
      tertiaryContainer: const Color(0xFF222B4A),
      onTertiaryContainer: const Color(0xFFE6EAFF),
      error: const Color(0xFFF2B8B5),
      onError: const Color(0xFF601410),
      errorContainer: const Color(0xFF8C1D18),
      onErrorContainer: const Color(0xFFF9DEDC),
      surface: const Color(0xFF0B0C10),
      onSurface: const Color(0xFFE9E9EA),
      surfaceContainerHighest: const Color(0xFF111216),
      onSurfaceVariant: const Color(0xFFC9CAD2),
      outline: const Color(0xFF3A3C46),
      outlineVariant: const Color(0xFF23242B),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFE9E9EA),
      onInverseSurface: const Color(0xFF111216),
      inversePrimary: const Color(0xFF111216),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.onSurface,
          foregroundColor: scheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}


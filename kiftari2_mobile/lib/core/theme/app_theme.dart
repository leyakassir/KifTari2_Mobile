import 'package:flutter/material.dart';

class AppTheme {
  static const Color _lightPrimary = Color.fromARGB(255, 4, 29, 98);
  static const Color _lightSuccess = Color(0xFF1B9C5D);
  static const Color _lightWarning = Color(0xFFF59E0B);
  static const Color _darkPrimary = Color(0xFF2C5EE8);
  //static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkSuccess = Color(0xFF2DD4BF);
  static const Color _darkWarning = Color(0xFFF59E0B);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF0B4ACB),
      onSecondary: Colors.white,
      tertiary: _lightSuccess,
      onTertiary: Colors.white,
      tertiaryContainer: _lightWarning,
      onTertiaryContainer: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
      error: const Color(0xFFB00020),
      onError: Colors.white,
      outline: const Color(0xFFCBD5E1),
    );

    return ThemeData.light().copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: scheme.surface),
        actionTextColor: scheme.secondary,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF5B8CFF),
      onSecondary: Colors.white,
      tertiary: _darkSuccess,
      onTertiary: const Color(0xFF0F172A),
      tertiaryContainer: _darkWarning,
      onTertiaryContainer: const Color(0xFF0F172A),
      surface: _darkSurface,
      onSurface: Colors.white,
      error: const Color(0xFFFF6B6B),
      onError: const Color(0xFF0F172A),
      outline: const Color(0xFF334155),
    );

    return ThemeData.dark().copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        hintStyle: TextStyle(color: Colors.white70),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: Colors.white70,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        actionTextColor: scheme.primary,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    );
  }
}

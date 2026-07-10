import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightAccent = Color(0xFF72383D);
  static const Color lightAccentSoft = Color(0xFF8D4A50);
  static const Color lightBgMain = Color(0xFFEFE9E1);
  static const Color lightSurface = Color(0xFFF7F1EA);
  static const Color lightTextPrimary = Color(0xFF322D29);
  static const Color lightTextSecondary = Color(0xFF5F554E);
  static const Color lightBorder = Color(0x23322D29); // rgba(50, 45, 41, 0.14)

  // Dark Mode Colors
  static const Color darkAccent = Color(0xFFEA7A0A);
  static const Color darkAccentSoft = Color(0xFFE2C77A);
  static const Color darkBgMain = Color(0xFF0E1A2B);
  static const Color darkSurface = Color(0xFF1A2436);
  static const Color darkTextPrimary = Color(0xFFF7F1E8);
  static const Color darkTextSecondary = Color(0xFFDFDAB5);
  static const Color darkBorder = Color(0x1FE7DDC8); // rgba(231, 221, 200, 0.12)

  // Toast / Status Colors
  static const Color success = Color(0xFF4A8C62);
  static const Color error = Color(0xFF9A3F43);
  static const Color warning = Color(0xFFB88C3C);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.lightAccent,
      scaffoldBackgroundColor: AppColors.lightBgMain,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightAccent,
        secondary: AppColors.lightAccentSoft,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
        bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.darkAccent,
      scaffoldBackgroundColor: AppColors.darkBgMain,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkAccent,
        secondary: AppColors.darkAccentSoft,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
      ),
    );
  }
}

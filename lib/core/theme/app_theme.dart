import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const String _fontFamily = 'Plus Jakarta Sans';

  static ThemeData get lightTheme {
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w400,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDark,
        secondary: AppColors.primaryYellow,
        surface: AppColors.surface,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSecondary: AppColors.primaryDark,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
    );
  }
}

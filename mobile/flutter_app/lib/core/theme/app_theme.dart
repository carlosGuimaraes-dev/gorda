import 'package:flutter/material.dart';

class AppThemeTokens {
  static const Color background = Color(0xFFF2F2F7);
  static const Color cardBackground = Colors.white;
  static const Color primary = Color(0xFF1A73F2);
  static const Color primaryText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color fieldBackground = Color(0xFFF3F4F6);
  static const double cornerRadius = 16;
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppThemeTokens.primary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppThemeTokens.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppThemeTokens.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppThemeTokens.primaryText,
      titleTextStyle: TextStyle(
        color: AppThemeTokens.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppThemeTokens.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.cornerRadius),
      ),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppThemeTokens.fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.cornerRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(color: AppThemeTokens.secondaryText),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppThemeTokens.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.cornerRadius),
        ),
        elevation: 0,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0x1F1A73F2),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

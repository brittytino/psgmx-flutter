import 'package:flutter/material.dart';
import 'layout_tokens.dart';
import 'typography.dart';

class AppTheme {
  // PSG Brand Colors
  static const Color _seedColor = Color(0xFF003366); // PSG Blue
  static const Color _secondaryColor = Color(0xFF0055A4);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      secondary: _secondaryColor,
    );
    
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      secondary: _secondaryColor,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.getTextTheme(colorScheme.brightness == Brightness.dark),
      
      // Component Themes
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), // M3 Surface
        margin: EdgeInsets.zero,
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        isDense: true,
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),

      dividerTheme: DividerThemeData(
        space: AppSpacing.lg,
        thickness: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

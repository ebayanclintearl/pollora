import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Pollora theme factory — single source for all ThemeData.
///
/// Usage:
///   MaterialApp(theme: AppTheme.dark)
///
/// To restyle the app edit the relevant token file:
///   Colors      → app_colors.dart
///   Typography  → app_typography.dart
///   Spacing     → app_spacing.dart     (density / component heights)
///   Shapes      → app_radius.dart      (roundness)
abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: _colorScheme,
    textTheme: GoogleFonts.interTextTheme(_baseTextTheme),

    // ── ElevatedButton ────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, AppSpacing.ctaH),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),

    // ── Switch ────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
          ? Colors.white
          : AppColors.textTertiary),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
          ? AppColors.accentPrimary
          : AppColors.surfaceElevated),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // ── Input decoration ──────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceInput,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPlaceholder),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPad,  // 16
        vertical: AppSpacing.x3,        // 12
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.textDestructive, width: 1.5),
      ),
    ),

    // ── Bottom sheet ──────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      elevation: 0,
    ),

    // ── Divider ───────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDefault,
      thickness: 1,
      space: 0,
    ),

    // ── Refresh indicator ─────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accentPrimary,
    ),

    // ── Chip ─────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.accentPrimaryMuted,
      labelStyle: AppTypography.labelMedium,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),

    // ── Page transitions ──────────────────────────
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );

  // ─────────────────────────────────────────────────
  // Color scheme — full M3 dark palette
  // Edit AppColors to change any individual color.
  // ─────────────────────────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme.dark(
    // Primary — indigo/purple accent
    primary:              AppColors.accentPrimary,     // #5B4FE8
    onPrimary:            Color(0xFFFFFFFF),
    primaryContainer:     Color(0xFF2D2780),
    onPrimaryContainer:   Color(0xFFCCC8FF),
    // Secondary — lighter purple for nav & badges
    secondary:            AppColors.navActive,         // #8F86FF
    onSecondary:          Color(0xFFFFFFFF),
    secondaryContainer:   Color(0xFF26228A),
    onSecondaryContainer: AppColors.textAccent,
    // Tertiary — success green
    tertiary:             AppColors.textSuccess,       // #6FCF97
    onTertiary:           Color(0xFF003919),
    tertiaryContainer:    Color(0xFF005228),
    onTertiaryContainer:  Color(0xFF8DFCB4),
    // Error
    error:                AppColors.textDestructive,   // #FF6B6B
    onError:              Color(0xFFFFFFFF),
    errorContainer:       Color(0xFF8B0000),
    onErrorContainer:     Color(0xFFFFDAD6),
    // Surfaces
    surface:              AppColors.surfaceCard,       // #1C1C1C
    onSurface:            AppColors.textPrimary,       // #FFFFFF
    surfaceVariant:       AppColors.surfaceElevated,   // #222222
    onSurfaceVariant:     AppColors.textSecondary,     // #CCCCCC
    // Borders & overlays
    outline:              AppColors.borderDefault,     // #2E2E2E
    outlineVariant:       AppColors.borderSubtle,      // #1E1E1E
    scrim:                Color(0xFF000000),
    // Inverse (SnackBar, Tooltip)
    inverseSurface:       Color(0xFFF0EFFF),
    onInverseSurface:     Color(0xFF1A1A2E),
    inversePrimary:       Color(0xFF5B4FE8),
    surfaceTint:          AppColors.accentPrimary,
  );

  // ─────────────────────────────────────────────────
  // Base text theme — M3 roles mapped to color tokens.
  // Typeface and sizes are applied via GoogleFonts.interTextTheme().
  // ─────────────────────────────────────────────────
  static const TextTheme _baseTextTheme = TextTheme(
    displayLarge:   TextStyle(color: AppColors.textPrimary),
    displayMedium:  TextStyle(color: AppColors.textPrimary),
    displaySmall:   TextStyle(color: AppColors.textPrimary),
    headlineLarge:  TextStyle(color: AppColors.textPrimary),
    headlineMedium: TextStyle(color: AppColors.textPrimary),
    headlineSmall:  TextStyle(color: AppColors.textPrimary),
    titleLarge:     TextStyle(color: AppColors.textPrimary),
    titleMedium:    TextStyle(color: AppColors.textPrimary),
    titleSmall:     TextStyle(color: AppColors.textPrimary),
    bodyLarge:      TextStyle(color: AppColors.textPrimary),
    bodyMedium:     TextStyle(color: AppColors.textPrimary),
    bodySmall:      TextStyle(color: AppColors.textSecondary),
    labelLarge:     TextStyle(color: AppColors.textPrimary),
    labelMedium:    TextStyle(color: AppColors.textSecondary),
    labelSmall:     TextStyle(color: AppColors.textTertiary),
  );
}

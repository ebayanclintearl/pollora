import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  // ─────────────────────────────────────────────
  // Display / Onboarding — full-screen hero text only
  // ─────────────────────────────────────────────

  static const TextStyle displayOnboarding = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────
  // Screen titles — compact, iOS-native scale
  // ─────────────────────────────────────────────

  /// Primary screen header: Feed, Create Poll, Profile, Settings
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// Sub-section header (unused directly; for in-content groupings)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────
  // Title
  // ─────────────────────────────────────────────

  /// Poll question text — card headline
  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Modal/sheet headers, inline labels
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Settings row labels, option input text
  static const TextStyle titleSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────

  /// Onboarding subtitle
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  /// Comment text, input text
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Username, handle, metadata
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  // ─────────────────────────────────────────────
  // Label
  // ─────────────────────────────────────────────

  /// Button text, action row text
  static const TextStyle labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Nav labels, badges, vote count, metadata chips
  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  /// Small caps section labels ("ACCOUNT", "OPTIONS")
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.textTertiary,
  );

  // ─────────────────────────────────────────────
  // Profile-specific
  // ─────────────────────────────────────────────

  static const TextStyle profileName = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Stat values — accent color, prominent
  static const TextStyle statValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.textAccent,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );
}

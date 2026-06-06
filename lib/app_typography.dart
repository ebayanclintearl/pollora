import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Material Design 3 type scale tokens for Pollora.
///
/// Every TextStyle in the app should reference one of these tokens
/// rather than hardcoding fontSize / fontWeight inline.
///
/// Scale reference: https://m3.material.io/styles/typography/type-scale-tokens
abstract final class AppTypography {
  // ─────────────────────────────────────────────
  // Display / Headline
  // ─────────────────────────────────────────────

  /// Headline Large — 32sp — onboarding page titles
  static const TextStyle displayOnboarding = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────
  // Screen / Section titles
  // ─────────────────────────────────────────────

  /// Headline Small — 24sp — primary screen headers (Polls, Profile, Create Poll)
  static const TextStyle screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Title Large — 22sp — secondary screen headers (Settings)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.27,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────
  // Title
  // ─────────────────────────────────────────────

  /// Title Medium — 18sp w700 — card headlines (poll question)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Title Medium — 16sp w500 — modal/sheet headers, comments title
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  /// Title Small — 14sp w500 — settings row labels, option text
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────

  /// Body Large — 16sp w500 — onboarding subtitles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  /// Body Medium — 14sp w500 — comment text, input text
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  /// Body Small — 13sp w500 — username, timestamp, meta text
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.38,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  // ─────────────────────────────────────────────
  // Label
  // ─────────────────────────────────────────────

  /// Label Large — 14sp w500 — button text, action row text
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  /// Label Medium — 12sp w600 — nav labels, badges, vote count
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Label Small — 11sp w600 uppercase — section headers ("ACCOUNT", "OPTIONS")
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 1.2,
    color: AppColors.textTertiary,
  );

  // ─────────────────────────────────────────────
  // Profile-specific
  // ─────────────────────────────────────────────

  /// Title Large — 22sp w700 — profile username
  static const TextStyle profileName = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Headline Small — 20sp w700 — profile stat values
  static const TextStyle statValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Label Medium — 12sp w500 — profile stat labels
  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );
}

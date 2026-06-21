import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF222222);
  static const Color surfaceCard = Color(0xFF1C1C1C);
  static const Color surfaceModal = Color(0xFF1E1E1E);
  static const Color surfaceInput = Color(0xFF262626);
  static const Color surfaceIconBadge = Color(0xFF2A2566);

  // Accent
  static const Color accentPrimary = Color(0xFF5B4FE8);
  static const Color accentPrimaryMuted = Color(0x405B4FE8);
  static const Color accentPrimaryBorder = Color(0x995B4FE8);

  // Text — cool-neutral ramp (subtle blue undertone harmonises with the
  // indigo accent and reads crisper than pure grey on near-black).
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBFC3CC); // secondary copy, counts
  static const Color textTertiary = Color(0xFF787D88);  // timestamps, metadata, icons
  static const Color textAccent = Color(0xFFB8B3FF);    // accent tinted text / stats
  static const Color textPlaceholder = Color(0xFF5C616B);
  static const Color textDestructive = Color(0xFFFF5566);
  static const Color textSuccess = Color(0xFF4CAF50);

  // Border — very subtle, no harsh lines
  static const Color borderDefault = Color(0xFF2E2E2E);
  static const Color borderSubtle = Color(0xFF1A1A1A);

  // Poll
  static const Color pollBarTrack = Color(0xFF252525);
  static const Color pollBarLeading = Color(0xFF5B4FE8);
  static const Color pollBarOther = Color(0xFF2C2C2C);

  // Navigation
  static const Color navBackground = Color(0xFF0A0A0A);
  static const Color navActive = Color(0xFFB8B3FF);
  static const Color navInactive = Color(0xFF6B707A); // cool-neutral, brighter for legibility
}

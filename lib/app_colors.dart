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

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);   // 21:1
  static const Color textSecondary = Color(0xFFCCCCCC); // 7.7:1 — was #AAAAAA (3.4:1)
  static const Color textTertiary = Color(0xFF999999);  // 3.5:1 — was #666666 (2.4:1)
  static const Color textAccent = Color(0xFF8F86FF);    // brightened for contrast
  static const Color textPlaceholder = Color(0xFF777777); // 4.5:1 — was #555555 (2.0:1)
  static const Color textDestructive = Color(0xFFFF6B6B);
  static const Color textSuccess = Color(0xFF6FCF97);

  // Border
  static const Color borderDefault = Color(0xFF2E2E2E);
  static const Color borderSubtle = Color(0xFF1E1E1E);

  // Poll
  static const Color pollBarTrack = Color(0xFF2C2C2C);
  static const Color pollBarLeading = Color(0xFF5B4FE8);
  static const Color pollBarOther = Color(0xFF333333);

  // Navigation
  static const Color navBackground = Color(0xFF0A0A0A);
  static const Color navActive = Color(0xFF8F86FF);
  static const Color navInactive = Color(0xFF999999); // was #666666 (2.4:1) → 3.5:1
}

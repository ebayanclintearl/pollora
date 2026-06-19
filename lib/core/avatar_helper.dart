import 'package:flutter/material.dart';

/// Single source of truth for avatar colour and initial.
/// All screens must use these methods — never derive independently.
abstract class AvatarHelper {
  static const _palette = [
    Color(0xFF5B4FE8), // violet  (index 0)
    Color(0xFF1A7A4A), // green   (index 1)
    Color(0xFF8B6914), // amber   (index 2)
    Color(0xFF8B2252), // rose    (index 3)
    Color(0xFF1A5C8B), // navy    (index 4)
  ];

  /// Deterministic colour from a user ID string.
  /// Passing the same [userId] always returns the same colour.
  static Color colorFor(String? userId) {
    if (userId == null || userId.isEmpty) return _palette[0];
    return _palette[userId.hashCode.abs() % _palette.length];
  }

  /// First uppercase letter of [displayName], or [email] prefix, or '?'.
  static String initialFor({String? displayName, String? email}) {
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty) return name[0].toUpperCase();
    final prefix = email?.split('@').first.trim() ?? '';
    if (prefix.isNotEmpty) return prefix[0].toUpperCase();
    return '?';
  }

  /// Display name: prefer [displayName], fall back to email prefix.
  static String nameFor({String? displayName, String? email}) {
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return email?.split('@').first ?? 'You';
  }

  /// Handle with @ prefix.
  static String handleFor({String? handle, String? email}) {
    final h = handle?.trim() ?? '';
    if (h.isNotEmpty) return '@$h';
    return '@${email?.split('@').first ?? 'user'}';
  }
}

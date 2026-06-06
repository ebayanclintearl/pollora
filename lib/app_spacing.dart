import 'package:flutter/material.dart';

/// Pollora spacing scale — all values on the 4dp grid.
///
/// Adjust the numeric constants here to retune the entire app's density.
/// Use semantic aliases for layout decisions that should feel consistent
/// across screens; use raw multiples (x1–x14) for one-off local gaps.
///
/// Grid: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 56
abstract final class AppSpacing {
  // ── Raw scale ──────────────────────────────────────
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x14 = 56;

  // ── Semantic aliases ───────────────────────────────

  /// Left/right inset for full-width screen content.
  static const double screenH = x4; // 16

  /// Top offset below the status bar (added to SafeArea top).
  static const double screenTop = x5; // 20

  /// Internal padding for cards, bottom sheets, settings cards.
  static const double cardPad = x4; // 16

  /// Gap between major content groups / section blocks.
  static const double sectionGap = x4; // 16

  /// Gap between vertically stacked items inside a card.
  static const double itemGap = x3; // 12

  /// Gap between adjacent inline elements (avatar + name, icon + label).
  static const double inlineGap = x2; //  8

  /// Tight gap between closely related elements (dot separator spacing).
  static const double tightGap = x1; //  4

  // ── Component heights ──────────────────────────────

  /// M3 minimum touch target.
  static const double touchMin = x12; // 48

  /// Standard icon-button container / minimum touch target.
  static const double iconBtn = touchMin;

  /// Primary rows: option bars, option inputs, settings rows.
  static const double rowH = 52.0;

  /// Primary CTA buttons (onboarding, publish, switch account).
  static const double ctaH = x14; // 56

  // ── EdgeInsets helpers ─────────────────────────────

  /// Horizontal screen padding applied to most scroll children.
  static const EdgeInsets screenPadH =
      EdgeInsets.symmetric(horizontal: screenH);

  /// Standard card internal padding.
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPad);
}

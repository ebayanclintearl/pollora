/// Pollora shape (border-radius) scale — mirrors the M3 shape system.
///
/// Change a semantic alias here and every component using it updates at once.
/// E.g. set [card] = md (12) to make cards less rounded app-wide.
///
/// M3 shape scale: extraSmall 4 · small 8 · medium 12 · large 16 · extraLarge 28 · full
abstract final class AppRadius {
  // ── M3 raw scale ───────────────────────────────────
  static const double none =   0;
  static const double xs   =   4;   // M3 ExtraSmall
  static const double sm   =   8;   // M3 Small
  static const double md   =  12;   // M3 Medium
  static const double lg   =  16;   // M3 Large
  static const double xl   =  28;   // M3 ExtraLarge
  static const double full = 999;   // Circular / pill

  // ── Semantic aliases ───────────────────────────────

  /// Poll option bars.
  static const double pollBar     = sm;    //  8

  /// Buttons (ElevatedButton, outlined), text inputs, search fields.
  static const double button      = md;    // 12
  static const double input       = md;    // 12

  /// Segmented controls, icon-button containers.
  static const double segment     = md;    // 12
  static const double iconButton  = md;    // 12

  /// Cards, settings cards, stat panels, profile cards.
  static const double card        = lg;    // 16

  /// Full-width action buttons (sign out, destructive).
  static const double actionBtn   = lg;    // 16

  /// Bottom sheets and modals (top corners only).
  static const double sheet       = xl;    // 28

  /// Pill-shaped elements: chips, "more options" button, dot indicators,
  /// nav indicator, comment input, drag handles.
  static const double pill        = full;  // 999
}

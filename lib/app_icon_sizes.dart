/// Material-aligned icon size tokens.
///
/// Material system icons are 24dp by default, with compact 20dp icons for
/// dense inline contexts and 48dp icons for empty-state/display moments.
abstract final class AppIconSizes {
  /// Minimum touch target for interactive icons.
  static const double touchTarget = 48;

  /// Standard Material system icon.
  static const double standard = 24;

  /// Bottom navigation and prominent primary action icons.
  static const double nav = standard;

  /// Header buttons, sheet buttons, row actions, and footer actions.
  static const double control = standard;

  /// Inline metadata, compact controls, and status/check icons.
  static const double inline = 20;

  /// Empty-state icons.
  static const double empty = 48;

  /// Large icons inside onboarding illustrations.
  static const double illustration = empty;
}

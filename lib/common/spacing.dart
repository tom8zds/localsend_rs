/// Material Design 3 spacing tokens (4dp base grid).
///
/// Use these instead of scattering raw spacing literals through the UI:
/// component-internal padding 4/8/12/16/24, gaps between components
/// 8/12/16/24, section spacing 24/32/48, layout margins 16 (compact) /
/// 24 (medium+).
abstract final class AppSpacing {
  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x48 = 48;
}

/// M3 window size class breakpoints.
abstract final class AppBreakpoints {
  /// Compact: < 600dp (bottom navigation bar).
  static const double compact = 600;

  /// Medium: 600–839dp (navigation rail).

  /// Expanded: 840–1199dp — two-pane content becomes standard.
  static const double expanded = 840;

  /// Large: 1200–1599dp (navigation drawer).
  static const double large = 1200;
}

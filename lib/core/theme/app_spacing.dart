/// Spacing, Radius, and Border Width tokens for RecallMe
/// Multiples of 4dp, standard touch target 48dp
/// Source: docs/DESIGN.md v1.1
class AppSpacing {
  AppSpacing._();

  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;

  // Page padding
  static const double pageHorizontal = 20.0;
  static const double pageVertical = 20.0;

  // Touch Target
  static const double minTouchTarget = 48.0;
}

class AppRadii {
  AppRadii._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
}

class AppBorders {
  AppBorders._();

  static const double thin = 1.5;
  static const double standard = 2.0;
  static const double bold = 3.0;
}

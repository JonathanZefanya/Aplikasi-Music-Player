import 'package:flutter/widgets.dart';

/// Single source of truth for spacing so every screen breathes the same way.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);

  /// Clears the mini player plus the floating navigation bar and its safe-area
  /// margin. Overshooting only leaves blank space; undershooting hides content.
  static const double bottomInset = 190;
  static const EdgeInsets listBottom = EdgeInsets.only(bottom: bottomInset);
}

class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

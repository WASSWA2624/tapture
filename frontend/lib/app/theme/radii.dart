part of 'dimensions.dart';

/// Corner radii, identical in every mode (FE-THEME-03).
///
/// Surfaces use the smallest non-zero corner, [Space.x0], so controls stay
/// almost square without sharp zero-radius corners (§56.14). [sm], [md] and [lg]
/// share it. Only [pill] is fully round, for decorative marks such as a
/// sheet's drag handle and a skeleton avatar.
abstract final class Radii {
  /// Fields, chips, cards, menus, sheets and buttons.
  static const double sm = Space.x0;

  /// Same corner as [sm].
  static const double md = Space.x0;

  /// Same corner as [sm].
  static const double lg = Space.x0;

  /// Fully round ends, for decorative marks only.
  static const double pill = 999;
}

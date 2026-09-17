part of 'dimensions.dart';

/// Corner radii, identical in every mode (FE-THEME-03).
abstract final class Radii {
  /// Chips, thumbnails, dense controls.
  static const double sm = 8;

  /// Cards, fields, sheets.
  static const double md = 12;

  /// Dialogs and large panels.
  static const double lg = 16;

  /// Pills and fully round ends.
  static const double pill = 999;
}

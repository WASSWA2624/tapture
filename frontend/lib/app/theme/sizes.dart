part of 'dimensions.dart';

/// Control sizes, identical in every mode (FE-THEME-03).
abstract final class Sizes {
  /// Minimum width and height of any interactive target (FE-A11Y-01).
  static const double minTapTarget = 48;

  /// Default height of buttons and text fields.
  static const double controlHeight = 52;

  /// Master-detail list column on expanded windows. Below the readable
  /// column cap so the detail pane keeps most of the width (FE-RESP-04).
  static const double listPane = 280;

  /// Confirmation and alert maximum. Material 3's dialog cap, so a
  /// confirmation stays a readable column on tablets and desktops
  /// (FE-RESP-04).
  static const double dialogMaxWidth = 560;
}

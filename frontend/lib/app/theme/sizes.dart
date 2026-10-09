part of 'dimensions.dart';

/// Control sizes, identical in every mode (FE-THEME-03).
abstract final class Sizes {
  /// Minimum width and height of any interactive target (FE-A11Y-01).
  static const double minTapTarget = 48;

  /// Minimum control height; content can grow for large or wrapped text.
  static const double controlHeight = minTapTarget;

  /// Master-detail list column on expanded windows. Below the readable
  /// column cap so the detail pane keeps most of the width (FE-RESP-04).
  static const double listPane = 280;

  /// Height of a transcript pane placed where nothing bounds its height, so
  /// a long transcript scrolls inside the pane instead of growing the page.
  static const double transcriptPane = 320;

  /// Confirmation and alert maximum. Material 3's dialog cap, so a
  /// confirmation stays a readable column on tablets and desktops
  /// (FE-RESP-04).
  static const double dialogMaxWidth = 560;

  /// Readable context chip body cap, clamped to the owning trail's width.
  static const double contextChipMaxWidth = 280;
}

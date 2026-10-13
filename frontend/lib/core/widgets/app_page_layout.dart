import 'package:tapture/app/theme/dimensions.dart';

/// Shared composition choices for the selected project mobile designs.
enum AppPageLayout {
  /// Plain rows and the existing primary action, with minimal chrome.
  essentials,

  /// Related controls grouped in the catalogue's section surfaces.
  sectioned,

  /// Tighter spacing and label-sized rows, retaining 48dp targets.
  compact,

  /// Labelled secondary controls and a larger primary action below content.
  thumbReach,

  /// Full-width labels and metadata before secondary controls.
  readingFirst;

  /// Space between controls; geometry is identical in every theme.
  double get fieldGap => switch (this) {
    compact => Space.x2,
    readingFirst => Space.x4,
    _ => Space.x3,
  };

  /// Whether row metadata and actions follow the complete title.
  bool get stacksRows => this == readingFirst || this == thumbReach;
}

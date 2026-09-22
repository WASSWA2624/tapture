import 'dart:ui' show Rect;

/// One region of recognised text.
final class OcrBlock {
  /// Creates a block. [bounds] is in source pixels.
  const OcrBlock({
    required this.text,
    required this.bounds,
    required this.confidence,
  });

  /// Text inside [bounds].
  final String text;

  /// Bounding box in source pixels.
  final Rect bounds;

  /// How sure the reader is, from 0 to 1.
  final double confidence;
}

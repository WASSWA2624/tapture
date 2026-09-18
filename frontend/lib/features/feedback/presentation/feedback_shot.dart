import 'dart:typed_data';

/// One screenshot or photo attached to a feedback draft.
final class FeedbackShot {
  /// Creates an attached image.
  const FeedbackShot({
    required this.id,
    required this.bytes,
    required this.label,
  });

  /// Stable id for this attach, used to remove it.
  final String id;

  /// PNG or other decodeable image bytes.
  final Uint8List bytes;

  /// Screen name or "Photo", shown on the thumb and the remove control.
  final String label;
}

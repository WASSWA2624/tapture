/// One independent caption row to persist.
final class CaptionWrite {
  /// Creates a write.
  const CaptionWrite({
    required this.photoId,
    required this.text,
    this.previousText,
  });

  /// Photo that owns this row.
  final String photoId;

  /// New raw caption text.
  final String text;

  /// Previous text kept recoverable on replace.
  final String? previousText;
}

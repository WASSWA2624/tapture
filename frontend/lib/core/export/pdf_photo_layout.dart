/// The two photo layouts every PDF report offers (§52).
abstract final class PdfPhotoLayout {
  /// Several photos to a row.
  static const String thumbnail = 'thumbnail';

  /// One photo to a row, at the full width of the page.
  static const String full = 'full';

  /// Photos per row for [layout]: 1 for full size, 3 for thumbnails.
  static int columns(String layout) => layout == full ? 1 : 3;
}

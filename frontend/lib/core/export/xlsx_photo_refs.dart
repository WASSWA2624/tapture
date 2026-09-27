/// The photo cell for one reference mode (task 018).
///
/// Filename and path come from [PhotoNaming], not the stored path. Embedding
/// still names the file; only the row height changes.
final class XlsxPhotoRefs {
  /// The text written in the photo column.
  static String cell({
    required String mode,
    required String fileName,
    required String relativePath,
  }) {
    return switch (mode) {
      'path' => relativePath,
      'embed' => fileName,
      _ => fileName,
    };
  }

  /// Extra row height, in points, when the photo is embedded.
  static double rowHeight(String mode) {
    return mode == 'embed' ? 72 : 15;
  }
}

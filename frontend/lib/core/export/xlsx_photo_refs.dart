/// The photo cell for one reference mode (task 018).
///
/// Filename and path come from [PhotoNaming], not the stored path. Embedding
/// still names the file; only the row height changes.
final class XlsxPhotoRefs {
  /// The text written in the photo column.
  ///
  /// `path` writes [relativePath] as stored. `relative` points from the
  /// workbook to the photo inside a deliverable package, where every output
  /// sits in [outputsFolder] beside the package's `photos/` folder.
  static String cell({
    required String mode,
    required String fileName,
    required String relativePath,
  }) {
    return switch (mode) {
      'path' => relativePath,
      'relative' => '../$relativePath',
      'embed' => fileName,
      _ => fileName,
    };
  }

  /// The package folder a deliverable's workbooks, reports and tables sit in.
  static const String outputsFolder = 'outputs';

  /// Extra row height, in points, when the photo is embedded.
  static double rowHeight(String mode) {
    return mode == 'embed' ? 72 : 15;
  }
}

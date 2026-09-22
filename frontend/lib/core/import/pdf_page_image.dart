part of 'pdf_pages.dart';

/// One lazily rendered PDF page as image bytes for the tray.
final class PdfPageImage {
  /// Creates a page image. [bytes] are a derived cache file, never the
  /// source PDF.
  const PdfPageImage({
    required this.pageIndex,
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// Zero-based page index.
  final int pageIndex;

  /// Rendered image bytes.
  final Uint8List bytes;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;
}

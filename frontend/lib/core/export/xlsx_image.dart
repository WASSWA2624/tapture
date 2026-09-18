import 'dart:typed_data';

/// A PNG anchored at one cell of an [XlsxSheet], drawn at [width] by
/// [height] pixels.
final class XlsxImage {
  /// Creates an image. [row] and [column] are zero-based and count the
  /// header row, so row 1 is the first data row.
  const XlsxImage({
    required this.row,
    required this.column,
    required this.png,
    required this.width,
    required this.height,
  });

  /// Zero-based row the top-left corner sits in.
  final int row;

  /// Zero-based column the top-left corner sits in.
  final int column;

  /// The encoded PNG, stored in the workbook as it is.
  final Uint8List png;

  /// Drawn width in pixels.
  final int width;

  /// Drawn height in pixels.
  final int height;

  /// The pixel size in a PNG header, or null when [bytes] is not a PNG.
  static ({int width, int height})? pngSize(Uint8List bytes) {
    if (bytes.length < _ihdrEnd || !_hasSignature(bytes)) {
      return null;
    }
    final ByteData header = ByteData.sublistView(bytes);
    final int width = header.getUint32(_widthOffset);
    final int height = header.getUint32(_heightOffset);
    if (width <= 0 || height <= 0) {
      return null;
    }
    return (width: width, height: height);
  }

  /// [pngSize] scaled down, never up, so the longer side fits [maxEdge].
  static ({int width, int height})? fitWithin(Uint8List bytes, int maxEdge) {
    final ({int width, int height})? size = pngSize(bytes);
    if (size == null) {
      return null;
    }
    final int longest = size.width > size.height ? size.width : size.height;
    if (longest <= maxEdge) {
      return size;
    }
    final double scale = maxEdge / longest;
    return (
      width: (size.width * scale).round().clamp(1, maxEdge),
      height: (size.height * scale).round().clamp(1, maxEdge),
    );
  }
}

/// The eight bytes every PNG file starts with.
const List<int> _signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

/// Width and height sit in the IHDR chunk straight after the signature.
const int _widthOffset = 16;
const int _heightOffset = 20;
const int _ihdrEnd = 24;

bool _hasSignature(Uint8List bytes) {
  for (int index = 0; index < _signature.length; index++) {
    if (bytes[index] != _signature[index]) {
      return false;
    }
  }
  return true;
}

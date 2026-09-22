import 'ocr_block.dart';

/// Text read from one image, with the blocks it came from.
final class OcrResult {
  /// Creates a recognition result.
  const OcrResult({required this.text, required this.blocks});

  /// Recognised text.
  final String text;

  /// Blocks in reading order.
  final List<OcrBlock> blocks;
}

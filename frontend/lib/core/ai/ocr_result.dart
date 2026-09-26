import 'package:tapture/core/constants/app_constants.dart';

import 'ocr_block.dart';

/// Text read from one image, with the blocks it came from.
final class OcrResult {
  /// Creates a recognition result.
  const OcrResult({
    required this.text,
    required this.blocks,
    this.engine = AppConstants.ocrEngineUnspecified,
  });

  /// Recognised text.
  final String text;

  /// Blocks in reading order.
  final List<OcrBlock> blocks;

  /// Which on-device reader produced this result.
  final String engine;
}

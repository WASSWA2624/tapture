import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';

/// In-memory [OcrCache] stand-in. Later tests use this instead of a database.
final class FakeOcrCache {
  final Map<String, ({String perceptual, OcrResult result})> _rows =
      <String, ({String perceptual, OcrResult result})>{};

  /// Stores [result] under [contentHash].
  void put({
    required String contentHash,
    required String perceptualHash,
    required OcrResult result,
  }) {
    _rows.putIfAbsent(
      contentHash,
      () => (perceptual: perceptualHash, result: result),
    );
  }

  /// Exact hash, then a perceptual match.
  OcrResult? lookup({
    required String contentHash,
    required String perceptualHash,
  }) {
    final ({String perceptual, OcrResult result})? exact = _rows[contentHash];
    if (exact != null) {
      return exact.result;
    }
    for (final ({String perceptual, OcrResult result}) row in _rows.values) {
      if (PerceptualHash.matches(perceptualHash, row.perceptual)) {
        return row.result;
      }
    }
    return null;
  }
}

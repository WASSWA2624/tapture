import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';
import 'package:tapture/features/processing/data/ocr_cache.dart';

/// In-memory [OcrCache]. Later tests inject this instead of a database.
///
/// It keeps the real cache's rules: the first write of a content hash wins,
/// an exact hash answers first, then the nearest perceptual hash inside the
/// app threshold, and an empty perceptual hash asks for the exact one only.
final class FakeOcrCache implements OcrCache {
  final Map<String, ({String perceptual, OcrResult result})> _rows =
      <String, ({String perceptual, OcrResult result})>{};

  /// Every lookup made, in order, so a test can see what was asked.
  final List<({String contentHash, String perceptualHash})> lookups =
      <({String contentHash, String perceptualHash})>[];

  /// The content hashes stored so far, in write order.
  Iterable<String> get contentHashes => _rows.keys;

  @override
  Future<Result<void>> put({
    required String contentHash,
    required String perceptualHash,
    required OcrResult result,
  }) async {
    _rows.putIfAbsent(
      contentHash,
      () => (perceptual: perceptualHash, result: result),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<OcrResult?>> lookup({
    required String contentHash,
    required String perceptualHash,
  }) async {
    lookups.add((contentHash: contentHash, perceptualHash: perceptualHash));
    final ({String perceptual, OcrResult result})? exact = _rows[contentHash];
    if (exact != null) {
      return Success<OcrResult?>(exact.result);
    }
    if (perceptualHash.isEmpty) {
      return const Success<OcrResult?>(null);
    }
    final String? nearest = PerceptualHash.nearest(
      perceptualHash,
      <String, String>{
        for (final MapEntry<String, ({String perceptual, OcrResult result})> row
            in _rows.entries)
          row.key: row.value.perceptual,
      },
    );
    return Success<OcrResult?>(nearest == null ? null : _rows[nearest]!.result);
  }
}

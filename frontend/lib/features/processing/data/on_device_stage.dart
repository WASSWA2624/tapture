import 'dart:typed_data';

import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';

import 'ocr_cache.dart';
import 'photo_paths.dart';
import 'record_bundle.dart';
import 'stage_support.dart';

/// The on-device stage: reads each prepared photo with no network and
/// caches the result by content and perceptual hash.
final class OnDeviceStage {
  /// Creates the stage over [ocr] and [cache].
  const OnDeviceStage({
    required this._ocr,
    required this._cache,
    required this._paths,
  });

  final OcrService _ocr;
  final OcrCache _cache;
  final PhotoPaths _paths;

  /// Reads every photo in [bundle] the cache does not already hold.
  Future<void> run(RecordBundle bundle, CancellationToken cancel) async {
    // Browser OCR is unavailable; retain captions and fields for the remaining
    // stages instead of failing a record before online or manual review.
    if (_paths.isBrowser) return;
    for (final Photo photo in bundle.photos) {
      if (cancel.isCancelled) throw const CancelledFailure();
      final String path = await _paths.prepared(bundle, photo);
      final String relative =
          '${await _paths.compressedRelative(bundle, photo, cancel: cancel)}.ocr.jpg';
      final Uint8List bytes = StageSupport.unwrap(await _paths.read(relative));
      final String perceptual = StageSupport.unwrap(
        await PerceptualHash.ofBytesOffThread(bytes),
      );
      final OcrResult? cached = StageSupport.unwrap(
        await _cache.lookup(
          contentHash: photo.sha256,
          perceptualHash: perceptual,
        ),
      );
      if (cached != null) {
        continue;
      }
      final OcrResult result = await _ocr.recognise(path, cancel: cancel);
      StageSupport.unwrap(
        await _cache.put(
          contentHash: photo.sha256,
          perceptualHash: perceptual,
          result: result,
        ),
      );
    }
  }

  /// The cached text of every photo in [bundle], one photo per line.
  Future<String> text(RecordBundle bundle) async {
    final List<String> text = <String>[];
    for (final Photo photo in bundle.photos) {
      final OcrResult? result = StageSupport.unwrap(
        await _cache.lookup(contentHash: photo.sha256, perceptualHash: ''),
      );
      if (result != null && result.text.trim().isNotEmpty) {
        text.add(result.text);
      }
    }
    return text.join('\n');
  }
}

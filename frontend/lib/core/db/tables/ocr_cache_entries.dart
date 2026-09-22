import 'package:drift/drift.dart';

import '../columns.dart';

/// Cached on-device recognition, keyed by content hash.
///
/// A perceptual hash sits beside it so a resized or recompressed copy can
/// reuse the stored text without a second read.
@TableIndex(name: 'ocr_cache_by_hash', columns: {#contentHash})
@DataClassName('OcrCacheEntry')
class OcrCacheEntries extends Table with MergeColumns {
  @override
  String get tableName => 'ocr_cache';

  /// SHA-256 of the image bytes this row was read from.
  TextColumn get contentHash => text().unique()();

  /// Difference hash, stored as hex, for near-duplicate lookup.
  TextColumn get perceptualHash => text()();

  /// Recognised text. Stored as data, never executed.
  TextColumn get recognisedText => text()();

  /// Blocks and bounding boxes as a JSON array.
  TextColumn get blocksJson => text()();
}

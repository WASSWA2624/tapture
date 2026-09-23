import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:drift/drift.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/tables/ocr_cache_entries.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// OCR text stored by content hash, and reused by perceptual hash.
final class OcrCache {
  /// Opens against [db].
  OcrCache({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) : _db = db,
       _dao = _OcrDao(db, clock: clock, deviceId: deviceId, ids: ids);

  final AppDatabase _db;
  final _OcrDao _dao;

  /// The stored read for [contentHash], or a perceptual match inside the
  /// app threshold. Null when nothing is close enough.
  Future<Result<OcrResult?>> lookup({
    required String contentHash,
    required String perceptualHash,
  }) async {
    try {
      final OcrCacheEntry? exact =
          await (_db.select(_db.ocrCacheEntries)..where(
                ($OcrCacheEntriesTable tbl) =>
                    tbl.contentHash.equals(contentHash),
              ))
              .getSingleOrNull();
      if (exact != null) {
        return Success<OcrResult?>(_decode(exact));
      }
      final List<OcrCacheEntry> rows = await _db
          .select(_db.ocrCacheEntries)
          .get();
      OcrCacheEntry? nearest;
      var nearestDistance = AppConstants.processing.perceptualHashDistance + 1;
      for (final OcrCacheEntry row in rows) {
        final int distance = PerceptualHash.distance(
          perceptualHash,
          row.perceptualHash,
        );
        if (distance < nearestDistance) {
          nearest = row;
          nearestDistance = distance;
        }
      }
      if (nearest != null) {
        return Success<OcrResult?>(_decode(nearest));
      }
      return const Success<OcrResult?>(null);
    } on Object catch (error) {
      return FailureResult<OcrResult?>(storageFailureFrom(error));
    }
  }

  /// Stores [result] for [contentHash]. A second write of the same hash
  /// keeps the first text.
  Future<Result<void>> put({
    required String contentHash,
    required String perceptualHash,
    required OcrResult result,
  }) async {
    final OcrCacheEntry? existing =
        await (_db.select(_db.ocrCacheEntries)..where(
              ($OcrCacheEntriesTable tbl) =>
                  tbl.contentHash.equals(contentHash),
            ))
            .getSingleOrNull();
    if (existing != null) {
      return const Success<void>(null);
    }
    final Result<OcrCacheEntry> written = await _dao.upsert(
      OcrCacheEntriesCompanion(
        contentHash: Value<String>(contentHash),
        perceptualHash: Value<String>(perceptualHash),
        recognisedText: Value<String>(result.text),
        blocksJson: Value<String>(_encode(result)),
      ),
    );
    return written.map((_) {});
  }
}

final class _OcrDao extends BaseDao<OcrCacheEntries, OcrCacheEntry> {
  _OcrDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.ocrCacheEntries);
}

String _encode(OcrResult result) {
  return jsonEncode(<Object?>[
    for (final OcrBlock block in result.blocks)
      <String, Object?>{
        'text': block.text,
        'left': block.bounds.left,
        'top': block.bounds.top,
        'right': block.bounds.right,
        'bottom': block.bounds.bottom,
        'confidence': block.confidence,
      },
  ]);
}

OcrResult _decode(OcrCacheEntry row) {
  final List<OcrBlock> blocks = <OcrBlock>[];
  try {
    final Object? decoded = jsonDecode(row.blocksJson);
    if (decoded is List) {
      for (final Object? item in decoded) {
        if (item is! Map) {
          continue;
        }
        blocks.add(
          OcrBlock(
            text: item['text'] as String? ?? '',
            bounds: Rect.fromLTRB(
              (item['left'] as num?)?.toDouble() ?? 0,
              (item['top'] as num?)?.toDouble() ?? 0,
              (item['right'] as num?)?.toDouble() ?? 0,
              (item['bottom'] as num?)?.toDouble() ?? 0,
            ),
            confidence: (item['confidence'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }
  } on FormatException {
    return OcrResult(text: row.recognisedText, blocks: const <OcrBlock>[]);
  }
  return OcrResult(text: row.recognisedText, blocks: blocks);
}

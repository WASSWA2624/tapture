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
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// OCR text stored by content hash, and reused by perceptual hash.
///
/// The stages depend on this interface; tests inject a fake in its place.
abstract interface class OcrCache {
  /// The database-backed cache over [db].
  factory OcrCache({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) = _DriftOcrCache;

  /// The stored read for [contentHash], or a perceptual match inside the
  /// app threshold. Null when nothing is close enough. An empty
  /// [perceptualHash] asks for the exact hash only.
  Future<Result<OcrResult?>> lookup({
    required String contentHash,
    required String perceptualHash,
  });

  /// Stores [result] for [contentHash]. A second write of the same hash
  /// keeps the first text.
  Future<Result<void>> put({
    required String contentHash,
    required String perceptualHash,
    required OcrResult result,
  });
}

final class _DriftOcrCache implements OcrCache {
  _DriftOcrCache({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) : _db = db,
       _dao = _OcrDao(db, clock: clock, deviceId: deviceId, ids: ids);

  final AppDatabase _db;
  final _OcrDao _dao;

  @override
  Future<Result<OcrResult?>> lookup({
    required String contentHash,
    required String perceptualHash,
  }) async {
    try {
      final OcrCacheEntry? exact = await _byContentHash(contentHash);
      if (exact != null) {
        return Success<OcrResult?>(_decode(exact));
      }
      if (perceptualHash.isEmpty) {
        return const Success<OcrResult?>(null);
      }
      // Only the id and hash columns are read; the distance scan runs off
      // the UI thread, then the one winning row is loaded.
      final $OcrCacheEntriesTable table = _db.ocrCacheEntries;
      final List<TypedResult> hashes =
          await (_db.selectOnly(table)..addColumns(<Expression<Object>>[
                table.id,
                table.perceptualHash,
              ]))
              .get();
      if (hashes.isEmpty) {
        return const Success<OcrResult?>(null);
      }
      final Result<String?> nearest = await PerceptualHash.nearestOffThread(
        perceptualHash,
        <String, String>{
          for (final TypedResult row in hashes)
            row.read(table.id)!: row.read(table.perceptualHash)!,
        },
      );
      final String? id;
      switch (nearest) {
        case FailureResult<String?>(:final failure):
          return FailureResult<OcrResult?>(failure);
        case Success<String?>(:final value):
          id = value;
      }
      if (id == null) {
        return const Success<OcrResult?>(null);
      }
      final OcrCacheEntry? row =
          await (_db.select(table)
                ..where(($OcrCacheEntriesTable tbl) => tbl.id.equals(id!)))
              .getSingleOrNull();
      return Success<OcrResult?>(row == null ? null : _decode(row));
    } on Object catch (error) {
      return FailureResult<OcrResult?>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> put({
    required String contentHash,
    required String perceptualHash,
    required OcrResult result,
  }) {
    return runInTransaction<void>(_db, () async {
      if (await _byContentHash(contentHash) != null) {
        return;
      }
      final Result<OcrCacheEntry> written = await _dao.upsert(
        OcrCacheEntriesCompanion(
          contentHash: Value<String>(contentHash),
          perceptualHash: Value<String>(perceptualHash),
          recognisedText: Value<String>(result.text),
          blocksJson: Value<String>(_encode(result)),
        ),
      );
      written.fold((Failure failure) => throw Failure.from(failure), (_) {});
    });
  }

  Future<OcrCacheEntry?> _byContentHash(String contentHash) {
    return (_db.select(_db.ocrCacheEntries)..where(
          ($OcrCacheEntriesTable tbl) => tbl.contentHash.equals(contentHash),
        ))
        .getSingleOrNull();
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

/// The JSON keys of a stored read. Rows written before the engine was
/// recorded hold a bare block list instead of this object.
const String _engineKey = 'engine';
const String _blocksKey = 'blocks';

String _encode(OcrResult result) {
  return jsonEncode(<String, Object?>{
    _engineKey: result.engine,
    _blocksKey: <Object?>[
      for (final OcrBlock block in result.blocks)
        <String, Object?>{
          'text': block.text,
          'left': block.bounds.left,
          'top': block.bounds.top,
          'right': block.bounds.right,
          'bottom': block.bounds.bottom,
          'confidence': block.confidence,
        },
    ],
  });
}

OcrResult _decode(OcrCacheEntry row) {
  final Object? decoded;
  try {
    decoded = jsonDecode(row.blocksJson);
  } on FormatException {
    return OcrResult(text: row.recognisedText, blocks: const <OcrBlock>[]);
  }
  final Object? rawEngine = decoded is Map ? decoded[_engineKey] : null;
  final Object? rawBlocks = decoded is Map ? decoded[_blocksKey] : decoded;
  final List<OcrBlock> blocks = <OcrBlock>[];
  if (rawBlocks is List) {
    for (final Object? item in rawBlocks) {
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
  return OcrResult(
    text: row.recognisedText,
    blocks: blocks,
    engine: rawEngine is String && rawEngine.isNotEmpty
        ? rawEngine
        : AppConstants.ocrEngineUnspecified,
  );
}

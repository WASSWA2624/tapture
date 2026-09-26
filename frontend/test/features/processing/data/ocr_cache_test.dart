import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/ocr_cache.dart';

import '../../../support/fakes/fake_ocr_cache.dart';

void main() {
  late AppDatabase db;
  final DateTime t0 = DateTime.utc(2026, 9, 26, 8);

  const OcrResult plate = OcrResult(
    text: 'GRUNDFOS\nSN458923',
    engine: 'test',
    blocks: <OcrBlock>[
      OcrBlock(
        text: 'SN458923',
        bounds: Rect.fromLTRB(10, 40, 200, 70),
        confidence: 0.9,
      ),
    ],
  );

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  OcrCache cache() {
    return OcrCache(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(FixedClock(t0)),
    );
  }

  test('text, blocks and bounding boxes round-trip by content hash', () async {
    final OcrCache store = cache();
    _ok(
      await store.put(
        contentHash: 'sha-a',
        perceptualHash: '0f0f0f0f0f0f0f0f',
        result: plate,
      ),
    );

    final OcrResult? read = _ok(
      await store.lookup(contentHash: 'sha-a', perceptualHash: ''),
    );
    expect(read?.text, plate.text);
    expect(read?.blocks.single.text, 'SN458923');
    expect(read?.blocks.single.bounds, const Rect.fromLTRB(10, 40, 200, 70));
    expect(read?.blocks.single.confidence, 0.9);
  });

  test('a re-encoded copy is a hit by perceptual hash', () async {
    final OcrCache store = cache();
    _ok(
      await store.put(
        contentHash: 'sha-a',
        perceptualHash: '0f0f0f0f0f0f0f0f',
        result: plate,
      ),
    );
    final OcrResult? copy = _ok(
      await store.lookup(
        contentHash: 'sha-recompressed',
        perceptualHash: '0f0f0f0f0f0f0f0e',
      ),
    );
    expect(copy?.text, plate.text);
  });

  test('an unrelated photo, or an exact-only lookup, is a miss', () async {
    final OcrCache store = cache();
    _ok(
      await store.put(
        contentHash: 'sha-a',
        perceptualHash: '0f0f0f0f0f0f0f0f',
        result: plate,
      ),
    );
    expect(
      _ok(
        await store.lookup(
          contentHash: 'sha-b',
          perceptualHash: 'f0f0f0f0f0f0f0f0',
        ),
      ),
      isNull,
    );
    expect(
      _ok(await store.lookup(contentHash: 'sha-b', perceptualHash: '')),
      isNull,
    );
  });

  test('the first read of a content hash is kept', () async {
    final OcrCache store = cache();
    _ok(
      await store.put(contentHash: 'sha-a', perceptualHash: '', result: plate),
    );
    _ok(
      await store.put(
        contentHash: 'sha-a',
        perceptualHash: '',
        result: const OcrResult(text: 'later', blocks: <OcrBlock>[]),
      ),
    );
    expect(
      _ok(await store.lookup(contentHash: 'sha-a', perceptualHash: ''))?.text,
      plate.text,
    );
    expect(await db.select(db.ocrCacheEntries).get(), hasLength(1));
  });

  test('the fake later tests use keeps the same rules', () async {
    final FakeOcrCache fake = FakeOcrCache();
    _ok(
      await fake.put(
        contentHash: 'sha-a',
        perceptualHash: '0f0f0f0f0f0f0f0f',
        result: plate,
      ),
    );
    _ok(
      await fake.put(
        contentHash: 'sha-a',
        perceptualHash: '0f0f0f0f0f0f0f0f',
        result: const OcrResult(text: 'later', blocks: <OcrBlock>[]),
      ),
    );
    expect(
      _ok(
        await fake.lookup(
          contentHash: 'sha-copy',
          perceptualHash: '0f0f0f0f0f0f0f0e',
        ),
      )?.text,
      plate.text,
    );
    expect(
      _ok(await fake.lookup(contentHash: 'sha-copy', perceptualHash: '')),
      isNull,
    );
    expect(fake.lookups, hasLength(2));
    expect(fake.contentHashes, <String>['sha-a']);
  });
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}

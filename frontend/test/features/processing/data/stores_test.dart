import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/ocr_cache.dart';
import 'package:tapture/features/processing/data/response_store.dart';

import '../../../support/fakes/fake_ocr_cache.dart';
import '../../../support/fakes/fake_response_store.dart';

void main() {
  late AppDatabase db;
  final DateTime t0 = DateTime.utc(2026, 9, 23, 8);

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'ocr cache round-trips and the fake matches a perceptual hash',
    () async {
      final OcrCache cache = OcrCache(
        db: db,
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(FixedClock(t0)),
      );
      const OcrResult result = OcrResult(
        text: 'SN458923',
        blocks: <OcrBlock>[
          OcrBlock(
            text: 'SN458923',
            bounds: Rect.fromLTRB(1, 2, 3, 4),
            confidence: 0.9,
          ),
        ],
      );
      _ok(
        await cache.put(
          contentHash: 'abc',
          perceptualHash: 'ffff',
          result: result,
        ),
      );
      final OcrResult? loaded = _ok(
        await cache.lookup(contentHash: 'abc', perceptualHash: '0000'),
      );
      expect(loaded?.text, 'SN458923');
      expect(loaded?.blocks.single.confidence, 0.9);

      final FakeOcrCache fake = FakeOcrCache();
      fake.put(contentHash: 'abc', perceptualHash: 'abcd', result: result);
      expect(
        fake.lookup(contentHash: 'other', perceptualHash: 'abcd')?.text,
        'SN458923',
      );
      expect(PerceptualHash.matches('abcd', 'abcd'), isTrue);
    },
  );

  test('response store keeps the raw body and refuses a secret', () async {
    final ResponseStore store = ResponseStore(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(FixedClock(t0)),
    );
    _ok(
      await store.save(
        jobId: 'job-1',
        requestSummary: '{"images":["a","b"]}',
        rawResponse: '{"fields":{}}',
        parsedOk: true,
      ),
    );
    final List<ProcessingResult> rows = _ok(await store.forJob('job-1'));
    expect(rows.single.rawResponse, '{"fields":{}}');
    final Result<ProcessingResult> secret = await store.save(
      jobId: 'job-1',
      requestSummary: '{"api_key":"sk"}',
      rawResponse: '{}',
      parsedOk: false,
    );
    expect(
      secret.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );

    final FakeResponseStore fake = FakeResponseStore();
    expect(
      fake.save(
        jobId: 'job-1',
        requestSummary: '{"images":1}',
        rawResponse: 'kept',
        parsedOk: false,
      ),
      isA<Success<void>>(),
    );
    expect(fake.rows.single.raw, 'kept');
  });
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) => throw TestFailure(failure.message), (
    T value,
  ) {
    return value;
  });
}

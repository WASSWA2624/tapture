import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/response_store.dart';

import '../../../support/fakes/fake_response_store.dart';

void main() {
  late AppDatabase db;
  final DateTime t0 = DateTime.utc(2026, 9, 26, 8);

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  ResponseStore store() {
    return ResponseStore(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(FixedClock(t0)),
    );
  }

  test('a response is stored as it arrived, before it is parsed', () async {
    final ResponseStore responses = store();
    const String hostile = 'Sure! {"fields": broken';
    final ProcessingResult saved = _ok(
      await responses.save(
        jobId: 'job-1',
        requestSummary: '{"kind":"online","imageCount":2}',
        rawResponse: hostile,
        parsedOk: false,
      ),
    );

    final List<ProcessingResult> rows = _ok(await responses.forJob('job-1'));
    expect(rows.single.id, saved.id);
    expect(rows.single.rawResponse, hostile);
    expect(rows.single.parsedOk, isFalse);
    expect(_ok(await responses.forJob('job-2')), isEmpty);
  });

  test('marking a response parsed leaves its raw body alone', () async {
    final ResponseStore responses = store();
    final ProcessingResult saved = _ok(
      await responses.save(
        jobId: 'job-1',
        requestSummary: '{"kind":"online"}',
        rawResponse: '{"fields":{}}',
        parsedOk: false,
      ),
    );
    _ok(await responses.markParsed(saved.id));
    final ProcessingResult row = _ok(await responses.forJob('job-1')).single;
    expect(row.parsedOk, isTrue);
    expect(row.rawResponse, '{"fields":{}}');
    expect(await responses.markParsed('missing'), isA<FailureResult<void>>());
  });

  test('responses come back oldest first', () async {
    final ResponseStore responses = store();
    for (final String body in <String>['first', 'second', 'third']) {
      _ok(
        await responses.save(
          jobId: 'job-1',
          requestSummary: '{"kind":"online"}',
          rawResponse: body,
          parsedOk: false,
        ),
      );
    }
    expect(
      _ok(
        await responses.forJob('job-1'),
      ).map((ProcessingResult r) => r.rawResponse),
      <String>['first', 'second', 'third'],
    );
  });

  test('a summary that carries a key or token is refused', () async {
    final ResponseStore responses = store();
    for (final String summary in <String>[
      '{"api_key":"sk-123"}',
      '{"apikey":"sk-123"}',
      '{"secret":"x"}',
      '{"token":"x"}',
      '{"header":"Bearer abc"}',
    ]) {
      final Result<ProcessingResult> refused = await responses.save(
        jobId: 'job-1',
        requestSummary: summary,
        rawResponse: '{}',
        parsedOk: false,
      );
      expect(
        refused.fold((Failure failure) => failure, (_) => null),
        isA<StorageFailure>(),
        reason: summary,
      );
    }
    expect(await db.select(db.processingResults).get(), isEmpty);
  });

  test('the fake later tests use keeps the same refusals', () {
    final FakeResponseStore fake = FakeResponseStore();
    expect(
      fake.save(
        jobId: 'job-1',
        requestSummary: '{"kind":"online"}',
        rawResponse: 'kept',
        parsedOk: false,
      ),
      isA<Success<void>>(),
    );
    for (final String summary in <String>[
      '{"api_key":"sk-123"}',
      '{"token":"x"}',
      '{"header":"Bearer abc"}',
    ]) {
      expect(
        fake.save(
          jobId: 'job-1',
          requestSummary: summary,
          rawResponse: '{}',
          parsedOk: false,
        ),
        isA<FailureResult<void>>(),
        reason: summary,
      );
    }
    expect(fake.rows.single.raw, 'kept');
  });
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/job_writes.dart';
import 'package:tapture/features/processing/data/online_budget.dart';
import 'package:tapture/features/processing/data/record_bundle.dart';
import 'package:tapture/features/processing/data/response_store.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  late ProcessingFixture fixture;
  late ProcessingJob job;

  setUp(() async {
    fixture = await ProcessingFixture.open();
    job = await fixture.job();
  });

  OnlineBudget budget({int appCap = 2}) {
    return OnlineBudget(
      db: fixture.db,
      clock: fixture.clock,
      settings: fixture.stageSettings(
        settings: SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.aiDailyRequestCap.name: appCap},
        ),
      ),
      writes: JobWrites(db: fixture.db),
    );
  }

  /// One id sequence for every stored response, so no save replaces another.
  final UuidV7Service responseIds = UuidV7Service.sequence(
    FixedClock(DateTime.utc(2026, 1, 1)),
  );

  Future<void> used(
    int requests, {
    String kind = 'online',
    Duration? ago,
  }) async {
    final Clock at = FixedClock(
      fixture.clock.nowUtc().subtract(ago ?? Duration.zero),
    );
    for (var i = 0; i < requests; i++) {
      final Result<ProcessingResult> saved =
          await ResponseStore(
            db: fixture.db,
            clock: at,
            deviceId: 'device-a',
            ids: responseIds,
          ).save(
            jobId: job.id,
            requestSummary: '{"kind":"$kind","imageCount":1}',
            rawResponse: '{}',
            parsedOk: true,
          );
      expect(saved, isA<Success<ProcessingResult>>());
    }
  }

  Future<ProcessingJobRow> stored() {
    return (fixture.db.select(
      fixture.db.processing,
    )..where(($ProcessingTable t) => t.id.equals(job.id))).getSingle();
  }

  test('below the cap a request is allowed', () async {
    await used(1);
    final RecordBundle bundle = await fixture.bundle();

    await budget().require(job.id, bundle);

    expect((await stored()).lastError, isNull);
  });

  test('at the cap the job is requeued with the cap and reset', () async {
    await used(2);
    final RecordBundle bundle = await fixture.bundle();

    await expectLater(
      budget().require(job.id, bundle),
      throwsA(
        isA<CancelledFailure>().having(
          (CancelledFailure f) => f.message,
          'message',
          "Today's limit of 2 online requests is used. "
              'It resets at 00:00 UTC on 2026-09-27.',
        ),
      ),
    );
    final ProcessingJobRow row = await stored();
    expect(row.status, jobs.ProcessingJobStatus.queued);
    expect(row.lastError, contains('limit of 2'));
  });

  test('above the cap every request stays blocked', () async {
    await used(3);
    final RecordBundle bundle = await fixture.bundle();

    await expectLater(
      budget().require(job.id, bundle),
      throwsA(isA<CancelledFailure>()),
    );
  });

  test("the project's own cap wins over the app's", () async {
    await fixture.setProjectSettings('{"dailyRequestCap":1}');
    await used(1);
    final RecordBundle bundle = await fixture.bundle();

    await expectLater(
      budget(appCap: 50).require(job.id, bundle),
      throwsA(isA<CancelledFailure>()),
    );
  });

  test('only online requests made today count', () async {
    await used(3, kind: 'transcript');
    await used(3, ago: const Duration(days: 1));
    final RecordBundle bundle = await fixture.bundle();

    await budget(appCap: 1).require(job.id, bundle);
  });
}

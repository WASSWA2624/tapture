import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

const String _valid =
    '{"fields":{"serial":{"value":"SN458923","confidence":0.9,'
    '"evidence":["photo-1"]}}}';

void main() {
  /// A record whose required serial the plate does not fill, so the online
  /// stage has work to do.
  Future<({ProcessingFixture fixture, ProcessingJob job})> record({
    int photos = 1,
  }) async {
    final ProcessingFixture fixture = await ProcessingFixture.open(
      plateText: 'GRUNDFOS 240V',
    );
    for (var index = 1; index < photos; index++) {
      await fixture.addPhoto(index, plateText: 'PLATE $index');
    }
    await fixture.addField('serial', required: true);
    final String id =
        (await ProcessingRepositoryImpl(
          db: fixture.db,
          clock: fixture.clock,
          deviceId: 'device-a',
          ids: fixture.ids,
          settings: SettingsStore.fake(),
        ).enqueue(fixture.record.id)).fold(
          (Failure failure) => throw StateError(failure.message),
          (String value) => value,
        );
    return (
      fixture: fixture,
      job: ProcessingJob(id: id, recordId: fixture.record.id),
    );
  }

  Future<void> throughOnline(
    ProcessingStageWorker worker,
    ProcessingJob job,
  ) async {
    for (final JobStage stage in <JobStage>[
      JobStage.prepare,
      JobStage.onDevice,
      JobStage.detect,
      JobStage.online,
    ]) {
      await worker.perform(stage, job);
    }
  }

  Future<ProcessingJobRow> stored(ProcessingFixture fixture, String id) {
    return (fixture.db.select(
      fixture.db.processing,
    )..where(($ProcessingTable table) => table.id.equals(id))).getSingle();
  }

  test('a five-photo record makes exactly one extraction call', () async {
    final seeded = await record(photos: 5);
    final ScriptedExtraction provider = ScriptedExtraction(<String>[_valid]);

    await throughOnline(seeded.fixture.worker(provider: provider), seeded.job);

    expect(provider.requests, hasLength(1));
    expect(provider.requests.single.imagePaths, hasLength(5));
    expect(
      provider.requests.single.rules,
      contains('Use null when a value is not present. Never guess.'),
    );
  });

  test('the raw response is stored before it is parsed, with no key', () async {
    final seeded = await record();
    await throughOnline(
      seeded.fixture.worker(provider: ScriptedExtraction(<String>[_valid])),
      seeded.job,
    );

    final ProcessingResult row = await seeded.fixture.db
        .select(seeded.fixture.db.processingResults)
        .getSingle();
    expect(row.rawResponse, _valid);
    expect(row.parsedOk, isTrue);
    expect(row.requestSummary, contains('"imageCount":1'));
    for (final String secret in <String>[
      'api_key',
      'apikey',
      'authorization',
      'bearer',
      'secret',
    ]) {
      expect(row.requestSummary.toLowerCase(), isNot(contains(secret)));
    }
  });

  test('an unreadable reply is repaired once, then fails for good', () async {
    final seeded = await record();
    final ScriptedExtraction provider = ScriptedExtraction(<String>[
      'Sure! Here you go: serial SN458923',
      '{"fields": still broken',
    ]);

    await expectLater(
      throughOnline(seeded.fixture.worker(provider: provider), seeded.job),
      throwsA(isA<CorruptionFailure>()),
    );

    expect(provider.requests, hasLength(2));
    expect(provider.requests.first.repairError, isNull);
    expect(provider.requests.last.repairError, isNotNull);
    final List<ProcessingResult> rows = await seeded.fixture.db
        .select(seeded.fixture.db.processingResults)
        .get();
    expect(
      rows.map((ProcessingResult r) => r.rawResponse),
      <String>['Sure! Here you go: serial SN458923', '{"fields": still broken'],
      reason: 'a failed job keeps the raw responses for inspection',
    );
    expect(rows.every((ProcessingResult r) => !r.parsedOk), isTrue);
    expect(
      await seeded.fixture.db.select(seeded.fixture.db.recordFields).get(),
      isEmpty,
      reason: 'a hostile reply never reaches the record',
    );
    final RecordRow untouched = await seeded.fixture.storedRecord();
    expect(untouched.status, seeded.fixture.record.status);
    expect(untouched.rev, seeded.fixture.record.rev);
  });

  test('a repair that parses completes the stage', () async {
    final seeded = await record();
    final ScriptedExtraction provider = ScriptedExtraction(<String>[
      'not json',
      _valid,
    ]);

    await throughOnline(seeded.fixture.worker(provider: provider), seeded.job);

    expect(provider.requests, hasLength(2));
    final List<ProcessingResult> rows = await seeded.fixture.db
        .select(seeded.fixture.db.processingResults)
        .get();
    expect(rows.last.parsedOk, isTrue);
  });

  test('a stored parsed response is reused with no new call', () async {
    final seeded = await record();
    await throughOnline(
      seeded.fixture.worker(provider: ScriptedExtraction(<String>[_valid])),
      seeded.job,
    );
    final ScriptedExtraction again = ScriptedExtraction(<String>[_valid]);

    await seeded.fixture
        .worker(provider: again)
        .perform(JobStage.online, seeded.job);

    expect(again.requests, isEmpty);
  });

  test('a plate that fills every required field makes no call', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open(
      plateText: 'SN458923',
    );
    await fixture.addField('serial', required: true, pattern: r'SN\d{6}');
    await fixture.setIdentityFields(<String>['serial']);
    final ProcessingJob job = await fixture.job();
    final ScriptedExtraction provider = ScriptedExtraction(<String>[_valid]);

    await throughOnline(fixture.worker(provider: provider), job);

    expect(provider.requests, isEmpty);
    expect(
      (await stored(fixture, job.id)).skipReason,
      contains('Local extraction'),
    );
    await fixture.worker(provider: provider).perform(JobStage.normalise, job);
    await fixture.worker(provider: provider).perform(JobStage.validate, job);
    final RecordField serial = await fixture.db
        .select(fixture.db.recordFields)
        .getSingle();
    expect(serial.valueRaw, 'SN458923');
    expect(serial.source, 'ocr');
    expect(provider.requests, isEmpty, reason: 'identified with no call');
  });

  test('offline by choice skips online work and says why', () async {
    final seeded = await record();
    final ScriptedExtraction provider = ScriptedExtraction(<String>[_valid]);

    await throughOnline(
      seeded.fixture.worker(
        provider: provider,
        settings: SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.offlineByChoice.name: true},
        ),
      ),
      seeded.job,
    );

    expect(provider.requests, isEmpty);
    expect(
      (await stored(seeded.fixture, seeded.job.id)).skipReason,
      'Offline mode is on.',
    );
  });

  test('a project with AI off skips online work', () async {
    final seeded = await record();
    await seeded.fixture.setProjectSettings('{"aiEnabled":false}');
    final ScriptedExtraction provider = ScriptedExtraction(<String>[_valid]);

    await throughOnline(seeded.fixture.worker(provider: provider), seeded.job);

    expect(provider.requests, isEmpty);
    expect(
      (await stored(seeded.fixture, seeded.job.id)).skipReason,
      contains('off for this project'),
    );
  });

  test('with no provider the local results stand', () async {
    final seeded = await record();

    await throughOnline(seeded.fixture.worker(), seeded.job);

    expect(
      (await stored(seeded.fixture, seeded.job.id)).skipReason,
      contains('No online provider'),
    );
  });

  test(
    'reaching the daily cap leaves the job queued with the reason',
    () async {
      final seeded = await record();
      await seeded.fixture.setProjectSettings('{"dailyRequestCap":0}');
      final ScriptedExtraction provider = ScriptedExtraction(<String>[_valid]);

      await expectLater(
        throughOnline(seeded.fixture.worker(provider: provider), seeded.job),
        throwsA(isA<CancelledFailure>()),
      );

      expect(provider.requests, isEmpty);
      expect(
        (await stored(seeded.fixture, seeded.job.id)).lastError,
        contains('limit of 0 online requests'),
      );
    },
  );
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  Future<({ProcessingFixture fixture, ProcessingJob job})> record(
    String plateText,
  ) async {
    final ProcessingFixture fixture = await ProcessingFixture.open(
      plateText: plateText,
    );
    final String id = _ok(
      await ProcessingRepositoryImpl(
        db: fixture.db,
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
        settings: SettingsStore.fake(),
      ).enqueue(fixture.record.id),
    );
    return (
      fixture: fixture,
      job: ProcessingJob(id: id, recordId: fixture.record.id),
    );
  }

  Future<void> throughNormalise(
    ProcessingStageWorker worker,
    ProcessingJob job,
  ) async {
    for (final JobStage stage in JobStage.values) {
      if (stage == JobStage.validate) {
        return;
      }
      await worker.perform(stage, job);
    }
  }

  Future<AuditLogData> rowAudit(ProcessingFixture fixture) async {
    return (await fixture.db.select(fixture.db.auditLog).get()).lastWhere(
      (AuditLogData row) => row.fieldKey == 'templateRowId',
    );
  }

  test('an exact label is matched and audited with its strategy', () async {
    final seeded = await record('Pump room');
    final TemplateRow row = await seeded.fixture.addRow('Pump room');
    await seeded.fixture.addRow('Boiler house', number: 3);
    final int revBefore = (await seeded.fixture.storedRecord()).rev;

    await throughNormalise(
      seeded.fixture.worker(ocr: CountingOcr('Pump room')),
      seeded.job,
    );

    final RecordRow stored = await seeded.fixture.storedRecord();
    expect(stored.templateRowId, row.id);
    expect(stored.rowMatchStrategy, 'exact');
    expect(stored.rowMatchScore, 1);
    expect(stored.rev, revBefore + 1);
    final AuditLogData audit = await rowAudit(seeded.fixture);
    expect(audit.newValue, row.id);
    expect(jsonDecode(audit.reason!), <String, Object?>{
      'method': 'exact',
      'score': 1.0,
    });
  });

  test('an alias is matched by its alias strategy', () async {
    final seeded = await record('PR-1');
    final TemplateRow row = await seeded.fixture.addRow(
      'Pump room',
      aliases: <String>['PR-1'],
    );

    await throughNormalise(
      seeded.fixture.worker(ocr: CountingOcr('PR-1')),
      seeded.job,
    );

    final RecordRow stored = await seeded.fixture.storedRecord();
    expect(stored.templateRowId, row.id);
    expect(stored.rowMatchStrategy, 'alias');
  });

  test('a label in other case and spacing is a normalised match', () async {
    final seeded = await record('PUMP ROOM');
    final TemplateRow row = await seeded.fixture.addRow('Pump room');

    await throughNormalise(
      seeded.fixture.worker(ocr: CountingOcr('PUMP-ROOM')),
      seeded.job,
    );

    final RecordRow stored = await seeded.fixture.storedRecord();
    expect(stored.templateRowId, row.id);
    expect(stored.rowMatchStrategy, 'normalised');
  });

  test('the threshold comes from the settings store', () async {
    final seeded = await record('PUMP ROM');
    await seeded.fixture.addRow('Pump room');

    await throughNormalise(
      seeded.fixture.worker(
        ocr: CountingOcr('Pump rom'),
        settings: SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.aiRowMatchThreshold.name: 1.0},
        ),
      ),
      seeded.job,
    );

    expect(
      (await seeded.fixture.storedRecord()).templateRowId,
      isNull,
      reason: 'a near miss is not accepted when the bar is 1.0',
    );
  });

  test('a near miss above the default threshold is a fuzzy match', () async {
    final seeded = await record('PUMP ROM');
    final TemplateRow row = await seeded.fixture.addRow('Pump room');

    await throughNormalise(
      seeded.fixture.worker(ocr: CountingOcr('Pump rom')),
      seeded.job,
    );

    final RecordRow stored = await seeded.fixture.storedRecord();
    expect(stored.templateRowId, row.id);
    expect(stored.rowMatchStrategy, 'fuzzy');
    expect(stored.rowMatchScore, lessThan(1));
  });

  test('when local matching falls short the model row is used', () async {
    final seeded = await record('GRUNDFOS 240V');
    await seeded.fixture.addField('serial', required: true);
    await seeded.fixture.addRow('Pump room');
    final TemplateRow boiler = await seeded.fixture.addRow(
      'Boiler house',
      number: 3,
    );
    final ScriptedExtraction provider = ScriptedExtraction(<String>[
      '{"fields":{"serial":{"value":"SN1","confidence":0.9,'
          '"evidence":["SN1"]}},"matched_row":"Boiler house"}',
    ]);

    await throughNormalise(
      seeded.fixture.worker(provider: provider),
      seeded.job,
    );

    expect(provider.requests, hasLength(1), reason: 'no second request');
    final RecordRow stored = await seeded.fixture.storedRecord();
    expect(stored.templateRowId, boiler.id);
    expect(stored.rowMatchStrategy, 'model');
  });

  test('a model row that is not on the template is ignored', () async {
    final seeded = await record('GRUNDFOS 240V');
    await seeded.fixture.addField('serial', required: true);
    await seeded.fixture.addRow('Pump room');

    await throughNormalise(
      seeded.fixture.worker(
        provider: ScriptedExtraction(<String>[
          '{"fields":{},"matched_row":"Roof plant"}',
        ]),
      ),
      seeded.job,
    );

    expect((await seeded.fixture.storedRecord()).templateRowId, isNull);
  });

  test('a record that already has a row is left alone', () async {
    final seeded = await record('PUMP ROOM');
    await seeded.fixture.addRow('Pump room');
    final ProcessingStageWorker worker = seeded.fixture.worker(
      ocr: CountingOcr('Pump room'),
    );
    await throughNormalise(worker, seeded.job);
    final RecordRow first = await seeded.fixture.storedRecord();

    await worker.perform(JobStage.normalise, seeded.job);

    expect((await seeded.fixture.storedRecord()).rev, first.rev);
  });
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}

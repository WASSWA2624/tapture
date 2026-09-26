import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  /// A seeded record with a job, ready for every stage.
  Future<({ProcessingFixture fixture, ProcessingJob job})> record() async {
    final ProcessingFixture fixture = await ProcessingFixture.open(
      plateText: 'GRUNDFOS 240V',
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

  /// Runs every stage with the provider answering [fields].
  Future<void> process(
    ProcessingFixture fixture,
    ProcessingJob job,
    Map<String, Object?> fields, {
    SettingsStore? settings,
  }) async {
    final worker = fixture.worker(
      provider: ScriptedExtraction(<String>[
        jsonEncode(<String, Object?>{'fields': fields}),
      ]),
      settings: settings,
    );
    for (final JobStage stage in JobStage.values) {
      await worker.perform(stage, job);
    }
  }

  Map<String, Object?> value(String text, {double confidence = 0.95}) {
    return <String, Object?>{
      'value': text,
      'confidence': confidence,
      'evidence': <String>['plate line: $text'],
    };
  }

  Future<List<RecordField>> fields(ProcessingFixture fixture) {
    return fixture.db.select(fixture.db.recordFields).get();
  }

  Future<void> seedField(
    ProcessingFixture fixture,
    String key,
    String raw, {
    String source = 'extraction',
    bool verified = false,
  }) async {
    _ok(
      await insertRecordField(
        fixture.db,
        row: RecordFieldsCompanion(
          recordId: Value<String>(fixture.record.id),
          fieldKey: Value<String>(key),
          valueRaw: Value<String>(raw),
          source: Value<String>(source),
          verified: Value<bool>(verified),
        ),
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
      ),
    );
  }

  test('an applied value carries evidence, provenance and an audit', () async {
    final seeded = await record();
    await seeded.fixture.addField('serial', required: true);
    final int revBefore = (await seeded.fixture.storedRecord()).rev;

    await process(seeded.fixture, seeded.job, <String, Object?>{
      'serial': value('SN458923'),
    });

    final RecordField field = (await fields(seeded.fixture)).single;
    expect(field.valueRaw, 'SN458923');
    expect(field.verified, isFalse, reason: 'a proposal is never approved');
    expect(field.confidenceBand, 'high');
    expect(field.source, 'extraction');
    expect(field.method, 'provider');
    expect(field.provider, 'backend');
    expect(field.model, 'default');
    expect(field.promptVersion, 'v1');

    final List<FieldEvidenceRow> evidence = await seeded.fixture.db
        .select(seeded.fixture.db.fieldEvidence)
        .get();
    expect(evidence, hasLength(1));
    expect(evidence.single.recordFieldId, field.id);
    expect(evidence.single.snippet, 'plate line: SN458923');
    final Photo photo = await seeded.fixture.db
        .select(seeded.fixture.db.photos)
        .getSingle();
    expect(
      evidence.single.photoId,
      photo.id,
      reason: 'a value with no region still links its photo',
    );
    expect(evidence.single.region, isNull);

    final AuditLogData audit =
        (await seeded.fixture.db.select(seeded.fixture.db.auditLog).get())
            .lastWhere((AuditLogData row) => row.fieldKey == 'serial');
    expect(jsonDecode(audit.reason!), <String, Object?>{
      'source': 'extraction',
      'method': 'provider',
      'provider': 'backend',
      'model': 'default',
      'promptVersion': 'v1',
    });

    final RecordRow stored = await seeded.fixture.storedRecord();
    expect(stored.status, 'EXTRACTED');
    expect(stored.rev, revBefore + 1);
    expect(stored.updatedByDevice, 'device-a');
  });

  test('a low-confidence value sends the record to review', () async {
    final seeded = await record();
    await seeded.fixture.addField('serial', required: true);

    await process(seeded.fixture, seeded.job, <String, Object?>{
      'serial': value('SN458923', confidence: 0.2),
    });

    expect((await fields(seeded.fixture)).single.confidenceBand, isNot('high'));
    expect((await seeded.fixture.storedRecord()).status, 'NEEDS_REVIEW');
  });

  test('a required field left empty sends the record to review', () async {
    final seeded = await record();
    await seeded.fixture.addField('serial', required: true);
    await seeded.fixture.addField('model', required: true);

    await process(seeded.fixture, seeded.job, <String, Object?>{
      'serial': value('SN458923'),
      'model': null,
    });

    expect(
      (await fields(seeded.fixture)).map((RecordField f) => f.fieldKey),
      <String>['serial'],
    );
    expect((await seeded.fixture.storedRecord()).status, 'NEEDS_REVIEW');
  });

  test(
    'verified and hand-entered values are kept, and the skip recorded',
    () async {
      final seeded = await record();
      await seeded.fixture.addField('serial');
      await seeded.fixture.addField('model');
      // An empty required field is what sends the record online.
      await seeded.fixture.addField('rating', required: true);
      await seedField(seeded.fixture, 'serial', 'SN000001', verified: true);
      await seedField(seeded.fixture, 'model', 'CR-5', source: 'manual');

      await process(seeded.fixture, seeded.job, <String, Object?>{
        'serial': value('SN458923'),
        'model': value('CR-10'),
      });

      final Map<String, String?> stored = <String, String?>{
        for (final RecordField field in await fields(seeded.fixture))
          field.fieldKey: field.valueRaw,
      };
      expect(stored, <String, String?>{'serial': 'SN000001', 'model': 'CR-5'});
      final ProcessingJobRow job =
          await (seeded.fixture.db.select(seeded.fixture.db.processing)..where(
                ($ProcessingTable table) => table.id.equals(seeded.job.id),
              ))
              .getSingle();
      expect(
        (jsonDecode(job.rejections!) as List<Object?>).cast<String>(),
        containsAll(<String>[
          'serial is already verified.',
          'model was entered by hand.',
        ]),
      );
    },
  );

  test('a value in another unit is normalised and its phrasing kept', () async {
    final seeded = await record();
    await seeded.fixture.addField('volume', unit: 'L', required: true);

    await process(seeded.fixture, seeded.job, <String, Object?>{
      'volume': value('500 ml'),
    });

    final RecordField field = (await fields(seeded.fixture)).single;
    expect(field.valueRaw, '500 ml');
    expect(field.valueRefined, '0.5 L');
  });

  test('a date is read with the app language', () async {
    final seeded = await record();
    await seeded.fixture.addField('installed', type: 'date', required: true);

    await process(
      seeded.fixture,
      seeded.job,
      <String, Object?>{'installed': value('05/03/2024')},
      settings: SettingsStore.fake(
        stored: <String, Object?>{SettingKeys.appLanguage.name: 'en_US'},
      ),
    );

    final RecordField field = (await fields(seeded.fixture)).single;
    expect(field.valueRaw, '05/03/2024');
    expect(field.valueRefined, '2024-05-03');
  });
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}

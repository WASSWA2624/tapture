import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_snapshot.dart';
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
  Future<ScriptedExtraction> process(
    ProcessingFixture fixture,
    ProcessingJob job,
    Map<String, Object?> fields, {
    SettingsStore? settings,
  }) async {
    final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
    final ScriptedExtraction provider = ScriptedExtraction(<String>[
      jsonEncode(<String, Object?>{
        'fields': <String, Object?>{
          for (final MapEntry<String, Object?> entry in fields.entries)
            entry.key: switch (entry.value) {
              final Map<String, Object?> proposal => <String, Object?>{
                ...proposal,
                'evidence': <String>['photo:${photo.id}'],
              },
              final Object? value => value,
            },
        },
      }),
    ]);
    final worker = fixture.worker(provider: provider, settings: settings);
    for (final JobStage stage in JobStage.values) {
      await worker.perform(stage, job);
    }
    return provider;
  }

  Map<String, Object?> value(String text, {double confidence = 0.95}) {
    return <String, Object?>{'value': text, 'confidence': confidence};
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

  test('an empty field takes its default, unverified, with source default, '
      'no evidence and its audit', () async {
    final seeded = await record();
    await seeded.fixture.addField(
      'status',
      required: true,
      defaultValue: 'In use',
    );

    await process(seeded.fixture, seeded.job, <String, Object?>{});

    final RecordField field = (await fields(seeded.fixture)).single;
    expect(field.fieldKey, 'status');
    expect(field.valueRaw, 'In use');
    expect(field.verified, isFalse);
    expect(field.source, 'default');
    expect(field.method, 'template-default');
    expect(field.provider, 'template');
    expect(field.confidence, 1.0);
    expect(
      await seeded.fixture.db.select(seeded.fixture.db.fieldEvidence).get(),
      isEmpty,
    );
    // The field here is keyed `status`, like the record's own status audit
    // marker; the field's row is the created one.
    final AuditLogData audit =
        (await seeded.fixture.db.select(seeded.fixture.db.auditLog).get())
            .lastWhere(
              (AuditLogData row) =>
                  row.fieldKey == 'status' && row.action == AuditAction.created,
            );
    expect(jsonDecode(audit.reason!), <String, Object?>{
      'source': 'default',
      'method': 'template-default',
      'provider': 'template',
      'model': '',
      'promptVersion': '',
    });
    // A required field its default fills counts as filled.
    expect(
      (await seeded.fixture.storedRecord()).status,
      RecordStatus.extracted.stored,
    );
  });

  test('extracted, verified and hand-entered values keep their field from '
      'the default', () async {
    final seeded = await record();
    // Required, so the online stage is not skipped and extraction runs.
    await seeded.fixture.addField(
      'serial',
      required: true,
      defaultValue: 'UNKNOWN',
    );
    await seeded.fixture.addField('location', defaultValue: 'Store');
    await seeded.fixture.addField('make', defaultValue: 'Generic');
    await seedField(seeded.fixture, 'location', 'Ward 2', source: 'manual');
    await seedField(seeded.fixture, 'make', 'Grundfos', verified: true);

    await process(seeded.fixture, seeded.job, <String, Object?>{
      'serial': value('SN458923'),
    });

    final Map<String, RecordField> byKey = <String, RecordField>{
      for (final RecordField field in await fields(seeded.fixture))
        field.fieldKey: field,
    };
    expect(byKey['serial']!.valueRaw, 'SN458923');
    expect(byKey['serial']!.source, 'extraction');
    expect(byKey['location']!.valueRaw, 'Ward 2');
    expect(byKey['make']!.valueRaw, 'Grundfos');
    expect(
      (await fields(
        seeded.fixture,
      )).where((RecordField field) => field.source == 'default'),
      isEmpty,
    );
  });

  test('an applied value carries evidence, provenance and an audit', () async {
    final seeded = await record();
    await seeded.fixture.addField('serial', required: true);
    final int revBefore = (await seeded.fixture.storedRecord()).rev;

    final ScriptedExtraction provider = await process(
      seeded.fixture,
      seeded.job,
      <String, Object?>{'serial': value('SN458923')},
    );

    final RecordField field = (await fields(seeded.fixture)).single;
    expect(field.valueRaw, 'SN458923');
    expect(field.verified, isFalse, reason: 'a proposal is never approved');
    expect(field.confidenceBand, 'high');
    expect(field.source, 'extraction');
    expect(field.method, 'provider');
    expect(field.provider, 'backend');
    expect(field.model, 'default');
    expect(field.promptVersion, ProcessingSnapshot.promptVersion);

    final List<FieldEvidenceRow> evidence = await seeded.fixture.db
        .select(seeded.fixture.db.fieldEvidence)
        .get();
    expect(evidence, hasLength(1));
    expect(evidence.single.recordFieldId, field.id);
    final Photo photo = await seeded.fixture.db
        .select(seeded.fixture.db.photos)
        .getSingle();
    expect(evidence.single.snippet, 'photo:${photo.id}');
    expect(
      provider.requests.single.sources.map(
        (Map<String, Object?> source) => source['id'],
      ),
      contains('photo:${photo.id}'),
      reason: 'the cited retained photo was supplied to the provider',
    );
    final List<ProcessingResult> responses = _ok(
      await seeded.fixture.responses.forJob(seeded.job.id),
    );
    final Map<String, Object?> attempt = responses
        .map(
          (ProcessingResult row) =>
              jsonDecode(row.requestSummary) as Map<String, Object?>,
        )
        .singleWhere(
          (Map<String, Object?> summary) => summary['kind'] == 'attempt',
        );
    expect(
      attempt['projectRevision'],
      provider.requests.single.projectRevision,
    );
    expect(attempt['requestGeneration'], seeded.job.requestGeneration);
    expect(attempt['sourceSnapshot'], provider.requests.single.sources);
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
      'promptVersion': ProcessingSnapshot.promptVersion,
    });

    final RecordRow stored = await seeded.fixture.storedRecord();
    expect(stored.status, RecordStatus.extracted.stored);
    expect(stored.rev, revBefore + 1);
    expect(stored.updatedByDevice, 'device-a');

    final AuditLogData moved =
        (await seeded.fixture.db.select(seeded.fixture.db.auditLog).get())
            .singleWhere((AuditLogData row) => row.fieldKey == 'status');
    expect(moved.entityType, 'records');
    expect(moved.entityId, seeded.fixture.record.id);
    expect(moved.previousValue, RecordStatus.captured.stored);
    expect(moved.newValue, RecordStatus.extracted.stored);
    expect(jsonDecode(moved.reason!), <String, Object?>{'stage': 'validate'});
    expect(moved.device, 'device-a');
  });

  test('a low-confidence value sends the record to review', () async {
    final seeded = await record();
    await seeded.fixture.addField('serial', required: true);

    await process(seeded.fixture, seeded.job, <String, Object?>{
      'serial': value('SN458923', confidence: 0.2),
    });

    expect((await fields(seeded.fixture)).single.confidenceBand, isNot('high'));
    expect(
      (await seeded.fixture.storedRecord()).status,
      RecordStatus.needsReview.stored,
    );
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
    expect(
      (await seeded.fixture.storedRecord()).status,
      RecordStatus.needsReview.stored,
    );
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

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/processing/data/job_writes.dart';
import 'package:tapture/features/processing/data/ocr_cache.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_snapshot.dart';
import 'package:tapture/features/processing/data/proposal_collector.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';
import 'package:tapture/features/processing/data/validate_stage.dart';
import 'package:tapture/features/processing/domain/job_runner.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/records/data/record_writes.dart';
import 'package:tapture/features/records/domain/domain.dart'
    show RecordValueEdit;
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
    'hostile automatic and manual-only proposals cannot create empty values',
    () async {
      final seeded = await record();
      await seeded.fixture.addField('serial', required: true);
      await seeded.fixture.addField(
        'captured_date',
        inputMode: 'AUTO',
        required: true,
      );
      await seeded.fixture.addField('operator_name', inputMode: 'MANUAL_ONLY');
      await seeded.fixture.addField('room', contextLevel: 1);
      await seeded.fixture.addField(
        'future_source',
        validation: '{"_tapture":{"autoFill":"FUTURE_SOURCE"}}',
      );
      final ScriptedExtraction provider =
          await process(seeded.fixture, seeded.job, <String, Object?>{
            'serial': value('SN458923'),
            'captured_date': value('2026-10-09'),
            'operator_name': value('Operator'),
            'room': value('Workshop'),
            'future_source': value('Unsupported'),
            'unexpected': value('Injected'),
          });
      expect(provider.requests.single.fieldLabels, <String>['serial']);
      final List<RecordField> stored = await fields(seeded.fixture);
      expect(stored.single.fieldKey, 'serial');
      expect(stored.single.valueRaw, 'SN458923');
      final ProcessingJobRow job = await seeded.fixture.db
          .select(seeded.fixture.db.processing)
          .getSingle();
      for (final String key in <String>[
        'captured_date',
        'operator_name',
        'room',
        'future_source',
        'unexpected',
      ]) {
        expect(job.rejections, contains('$key is protected from extraction'));
      }
      expect(job.rejections, contains('captured_date is missing'));
      expect((await seeded.fixture.storedRecord()).status, 'needsReview');
    },
  );

  test(
    'declared source-protected defaults remain local while unavailable required sources need review',
    () async {
      final seeded = await record();
      await seeded.fixture.addField(
        'operator_note',
        inputMode: 'MANUAL_ONLY',
        required: true,
        defaultValue: 'Local default',
      );
      await seeded.fixture.addField(
        'automatic_default',
        inputMode: 'AUTO',
        required: true,
        defaultValue: 'Configured value',
      );
      await seeded.fixture.addField(
        'unavailable_source',
        inputMode: 'AUTO',
        required: true,
        validation: '{"_tapture":{"autoFill":"FUTURE_SOURCE"}}',
      );
      final provider = await process(
        seeded.fixture,
        seeded.job,
        <String, Object?>{},
      );
      expect(provider.requests, isEmpty);
      final Map<String, RecordField> stored = <String, RecordField>{
        for (final field in await fields(seeded.fixture)) field.fieldKey: field,
      };
      expect(
        stored.keys,
        unorderedEquals(<String>['operator_note', 'automatic_default']),
      );
      expect(stored['operator_note']!.valueRaw, 'Local default');
      expect(stored['automatic_default']!.valueRaw, 'Configured value');
      expect(
        stored.values.map((field) => field.source),
        everyElement('default'),
      );
      expect((await seeded.fixture.storedRecord()).status, 'needsReview');
      expect(
        (await seeded.fixture.db
                .select(seeded.fixture.db.processing)
                .getSingle())
            .rejections,
        contains('unavailable_source is missing'),
      );
    },
  );

  test(
    'raw automatic context and corrected values survive processing and reprocessing',
    () async {
      final seeded = await record();
      await seeded.fixture.addField('serial', required: true);
      await seeded.fixture.addField('captured_date', inputMode: 'AUTO');
      await seeded.fixture.addField('room', stickable: true);
      await seedField(
        seeded.fixture,
        'captured_date',
        '2026-10-08',
        source: 'AUTO',
      );
      await seedField(seeded.fixture, 'room', 'Workshop', source: 'CONTEXT');
      final Result<void> corrected =
          await RecordWrites(
            db: seeded.fixture.db,
            clock: seeded.fixture.clock,
            deviceId: 'device-a',
            ids: seeded.fixture.ids,
            operatorName: () => 'Operator',
          ).editValues(seeded.fixture.record.id, const <RecordValueEdit>[
            (fieldKey: 'captured_date', value: '2026-10-09'),
          ]);
      expect(corrected, isA<Success<void>>());
      final List<AuditLogData> history = await seeded.fixture.db
          .select(seeded.fixture.db.auditLog)
          .get();
      final ScriptedExtraction provider =
          await process(seeded.fixture, seeded.job, <String, Object?>{
            'serial': value('SN458923'),
            'captured_date': value('2000-01-01'),
            'room': value('Other'),
          });
      expect(provider.requests.single.fieldLabels, <String>['serial']);
      final ScriptedExtraction replay = await process(
        seeded.fixture,
        seeded.job,
        <String, Object?>{},
      );
      expect(replay.requests, isEmpty);
      final Map<String, RecordField> stored = <String, RecordField>{
        for (final RecordField field in await fields(seeded.fixture))
          field.fieldKey: field,
      };
      expect(stored['captured_date']!.valueRaw, '2026-10-08');
      expect(stored['captured_date']!.valueRefined, '2026-10-09');
      expect(stored['captured_date']!.source, 'manual');
      expect(stored['captured_date']!.verified, isTrue);
      expect(stored['room']!.valueRaw, 'Workshop');
      expect(stored['room']!.source, 'CONTEXT');
      final List<AuditLogData> after = await seeded.fixture.db
          .select(seeded.fixture.db.auditLog)
          .get();
      expect(
        after.map((entry) => entry.id),
        containsAll(history.map((entry) => entry.id)),
      );
      expect(
        after.where(
          (entry) =>
              entry.fieldKey == 'captured_date' &&
              entry.action == AuditAction.updated,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'a source policy changed before application cancels every queued write',
    () async {
      final seeded = await record();
      final fixture = seeded.fixture;
      await fixture.addField('serial', required: true);
      await seedField(fixture, 'operator_note', 'Keep this', source: 'manual');
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      final String raw = jsonEncode(<String, Object?>{
        'fields': <String, Object?>{
          'serial': <String, Object?>{
            ...value('SN458923'),
            'evidence': <String>['photo:${photo.id}'],
          },
        },
      });
      (await fixture.responses.save(
        jobId: seeded.job.id,
        requestSummary: '{"kind":"online"}',
        rawResponse: raw,
        parsedOk: true,
      )).getOrThrow();
      final bundle = await fixture.bundle();
      final collector = ProposalCollector(
        cache: OcrCache(
          db: fixture.db,
          clock: fixture.clock,
          deviceId: 'device-a',
          ids: fixture.ids,
        ),
        responses: fixture.responses,
      );
      expect(
        (await collector.collect(seeded.job, bundle)).proposals.single.fieldKey,
        'serial',
      );
      await (fixture.db.update(fixture.db.templateFields)..where(
            ($TemplateFieldsTable field) => field.fieldKey.equals('serial'),
          ))
          .write(
            const TemplateFieldsCompanion(inputMode: Value<String>('AUTO')),
          );
      final List<AuditLogData> before = await fixture.db
          .select(fixture.db.auditLog)
          .get();
      final stage = ValidateStage(
        db: fixture.db,
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
        settings: fixture.stageSettings(),
        collector: collector,
        writes: JobWrites(db: fixture.db),
        loader: RecordBundleLoader(db: fixture.db),
      );

      await expectLater(
        stage.run(seeded.job, bundle, CancellationToken()),
        throwsA(isA<CancelledFailure>()),
      );

      expect((await fields(fixture)).single.valueRaw, 'Keep this');
      expect(await fixture.db.select(fixture.db.fieldEvidence).get(), isEmpty);
      expect(
        (await fixture.db.select(fixture.db.auditLog).get()).map(
          (entry) => entry.id,
        ),
        before.map((entry) => entry.id),
      );
      expect(
        (await fixture.storedRecord()).status,
        RecordStatus.captured.stored,
      );
      expect(
        (await fixture.responses.forJob(
          seeded.job.id,
        )).getOrThrow().single.rawResponse,
        raw,
      );
    },
  );

  test(
    'a failed second proposal rolls back the first value evidence provenance and audit',
    () async {
      final seeded = await record();
      final fixture = seeded.fixture;
      await fixture.addField('serial', required: true, order: 0);
      await fixture.addField('model', required: true, order: 1);
      await fixture.addField('captured_date', inputMode: 'AUTO');
      await seedField(fixture, 'captured_date', '2026-10-08', source: 'AUTO');
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      final String raw = jsonEncode(<String, Object?>{
        'fields': <String, Object?>{
          for (final String key in <String>['serial', 'model'])
            key: <String, Object?>{
              ...value(key == 'serial' ? 'SN458923' : 'CR-10'),
              'evidence': <String>['photo:${photo.id}'],
            },
        },
      });
      final worker = fixture.worker(
        provider: ScriptedExtraction(<String>[raw]),
      );
      for (final JobStage stage in JobStage.values.where(
        (stage) => stage != JobStage.validate,
      )) {
        await worker.perform(stage, seeded.job);
      }
      final List<AuditLogData> before = await fixture.db
          .select(fixture.db.auditLog)
          .get();
      // The trigger raises only after the first accepted proposal has been written.
      await fixture.db.customStatement('''
      CREATE TEMP TRIGGER fail_second_proposal BEFORE INSERT ON record_fields
      WHEN NEW.field_key = 'model' AND EXISTS (
        SELECT 1 FROM record_fields WHERE record_id = NEW.record_id AND field_key = 'serial'
      )
      BEGIN SELECT RAISE(ABORT, 'fixture second proposal failure'); END
    ''');

      await expectLater(
        worker.perform(JobStage.validate, seeded.job),
        throwsA(isA<StorageFailure>()),
      );

      final RecordField kept = (await fields(fixture)).single;
      expect(kept.fieldKey, 'captured_date');
      expect(kept.valueRaw, '2026-10-08');
      expect(kept.source, 'AUTO');
      expect(await fixture.db.select(fixture.db.fieldEvidence).get(), isEmpty);
      expect(
        (await fixture.db.select(fixture.db.auditLog).get()).map(
          (entry) => entry.id,
        ),
        before.map((entry) => entry.id),
      );
      expect(
        (await fixture.storedRecord()).status,
        RecordStatus.captured.stored,
      );
      expect(
        (await fixture.responses.forJob(
          seeded.job.id,
        )).getOrThrow().where((response) => response.rawResponse == raw),
        hasLength(1),
      );
    },
  );

  test(
    'the real queue completes and resumes after validate writes change the snapshot',
    () async {
      final seeded = await record();
      await seeded.fixture.addField(
        'serial',
        required: true,
        pattern: r'SN\d{6}',
      );
      await seeded.fixture.setIdentityFields(<String>['serial']);
      await seeded.fixture.writePlate(
        'photos/${seeded.fixture.record.id}/img-0.jpg',
        'SN458923',
      );
      final repository = ProcessingRepositoryImpl(
        db: seeded.fixture.db,
        clock: seeded.fixture.clock,
        deviceId: 'device-a',
        ids: seeded.fixture.ids,
        settings: SettingsStore.fake(),
      );
      final worker = seeded.fixture.worker();
      final JobRunner runner = JobRunner(
        perform: (stage, job, token) async {
          await worker.perform(stage, job, token);
        },
        persist: (job, stage) async =>
            (await repository.markStage(job.id, stage)).getOrThrow(),
        release: (job) async {
          (await repository.release(job.id)).getOrThrow();
          return job;
        },
      );
      final outcome = await runner.run(seeded.job, token: CancellationToken());
      expect(outcome.cancelled, isFalse);
      expect(outcome.job.completedStages, containsAll(JobStage.values));
      (await repository.complete(outcome.job.id)).getOrThrow();
      final again = await runner.run(outcome.job, token: CancellationToken());
      expect(again.cancelled, isFalse);
      expect((await fields(seeded.fixture)).single.valueRaw, 'SN458923');
      expect(
        (await seeded.fixture.db
                .select(seeded.fixture.db.processing)
                .getSingle())
            .status
            .name,
        'completed',
      );
    },
  );

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

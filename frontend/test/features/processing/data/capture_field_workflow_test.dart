import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart' hide CaptureSession;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/capture/data/capture_record_writer.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';
import 'package:tapture/features/processing/domain/job_runner.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/records/data/record_repository_impl.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  for (final bool offline in <bool>[false, true]) {
    test('durable capture, audited correction and reprocessing '
        'preserve source evidence with offline=$offline', () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      await fixture.addField(
        'captured_date',
        type: 'date',
        inputMode: 'AUTO',
        validation: '{"_tapture":{"group":"record_admin"}}',
      );
      await fixture.addField(
        'captured_time',
        type: 'time',
        inputMode: 'AUTO',
        validation: '{"_tapture":{"group":"record_admin"}}',
      );
      await fixture.addField(
        'device_id',
        inputMode: 'AUTO',
        validation: '{"_tapture":{"group":"record_admin"}}',
      );
      await fixture.addField(
        'business_owner',
        inputMode: 'AUTO',
        autoFill: true,
        validation: '{"_tapture":{"autoFill":"OPERATOR"}}',
      );
      await fixture.addField('facility', contextLevel: 1);
      await fixture.addField(
        'local_address',
        inputMode: 'AUTO',
        autoFill: true,
        validation: '{"_tapture":{"autoFill":"LOCAL_ADDRESS"}}',
      );
      for (final String key in <String>['opaque_empty', 'opaque_context']) {
        await fixture.addField(
          key,
          validation: '{"_tapture":{"autoFill":{"future":true}}}',
        );
      }
      await fixture.addField('typed_value');
      await fixture.addField('description', required: true);
      await fixture.addField(
        'manual_required',
        inputMode: 'MANUAL_ONLY',
        required: true,
      );

      final CaptureSession session = CaptureSession(
        id: 'field-workflow-${offline ? "offline" : "online"}',
        projectId: fixture.project.id,
        templateId: fixture.template.id,
        templateVersion: fixture.template.version,
        captions: const <String, String>{'': 'An observed equipment item'},
        contextSnapshot: const <String, String>{
          'facility': 'Field location',
          'captured_time': '05:30:00',
          'typed_value': 'Context proposal',
          'opaque_context': 'Retained source context',
        },
        values: const <String, Object?>{'typed_value': 'Operator entry'},
      );
      String sampledAddress = '192.0.2.24';
      int snapshotCalls = 0;
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: fixture.db,
        clock: fixture.clock,
        deviceId: 'capture-device',
        ids: fixture.ids,
        operatorName: () => 'Capture operator',
        localAddress: (CaptureSession current) {
          expect(current.id, session.id);
          expect(current.templateId, session.templateId);
          expect(current.templateVersion, session.templateVersion);
          snapshotCalls++;
          return sampledAddress;
        },
      );
      final Future<Result<String>> saving = writer.persist(session);
      expect(snapshotCalls, 1, reason: 'Snapshot precedes the first await.');
      final String id = (await saving).getOrThrow();
      final RecordRow initialRecord = await _record(fixture, id);
      final Map<String, RecordField> initial = await _fields(fixture, id);
      expect(initial['business_owner']!.valueRaw, 'Capture operator');
      expect(initial['business_owner']!.source, 'AUTO');
      expect(initial['captured_date']!.source, 'AUTO');
      expect(initial['device_id']!.valueRaw, 'capture-device');
      expect(initial['device_id']!.source, 'AUTO');
      expect(initial['captured_time']!.valueRaw, '05:30:00');
      expect(initial['captured_time']!.source, 'CONTEXT');
      expect(initial['facility']!.source, 'CONTEXT');
      expect(initial['typed_value']!.valueRaw, 'Operator entry');
      expect(initial['typed_value']!.source, 'TYPED');
      expect(initial['local_address']!.valueRaw, '192.0.2.24');
      expect(initial['local_address']!.source, 'AUTO');
      expect(initial.containsKey('opaque_empty'), isFalse);
      expect(initial['opaque_context']!.valueRaw, 'Retained source context');
      expect(initial['opaque_context']!.source, 'CONTEXT');

      final SettingsStore settings = SettingsStore.fake(
        stored: <String, Object?>{SettingKeys.offlineByChoice.name: offline},
      );
      final RecordBundleLoader loader = RecordBundleLoader(db: fixture.db);
      final bundle = await loader.load(id);
      final String evidence = 'caption:${bundle.captions.single.id}';
      final String hostile = jsonEncode(<String, Object?>{
        'fields': <String, Object?>{
          for (final String key in <String>[
            'description',
            'business_owner',
            'captured_date',
            'device_id',
            'facility',
            'typed_value',
            'manual_required',
            'local_address',
            'opaque_empty',
            'opaque_context',
          ])
            key: <String, Object?>{
              'value': key == 'description'
                  ? 'equipment item'
                  : 'Hostile replacement',
              'confidence': 0.99,
              'evidence': <String>[evidence],
            },
        },
      });
      final ScriptedExtraction provider = ScriptedExtraction(<String>[hostile]);
      await _process(
        fixture,
        id,
        provider,
        settings,
        expectOfflineQueue: offline,
      );
      final Map<String, RecordField> processed = await _fields(fixture, id);
      for (final String key in initial.keys) {
        expect(processed[key]!.valueRaw, initial[key]!.valueRaw, reason: key);
        expect(processed[key]!.source, initial[key]!.source, reason: key);
      }
      expect(processed.containsKey('manual_required'), isFalse);
      expect(processed.containsKey('opaque_empty'), isFalse);
      if (offline) {
        expect(provider.requests, isEmpty);
      } else {
        expect(
          (await _record(fixture, id)).status,
          RecordStatus.needsReview.stored,
        );
        expect(provider.requests, isNotEmpty);
        for (final request in provider.requests) {
          expect(request.fieldSchema.map((field) => field['key']), <String>[
            'description',
          ]);
          expect(request.context, isEmpty);
        }
        expect(processed['description']!.valueRaw, 'equipment item');
        final results = await fixture.db
            .select(fixture.db.processingResults)
            .get();
        expect(results.any((row) => row.rawResponse == hostile), isTrue);
        final jobs = await (fixture.db.select(
          fixture.db.processing,
        )..where((row) => row.recordId.equals(id))).get();
        expect(
          jobs.any((row) => row.rejections?.contains('device_id') ?? false),
          isTrue,
        );
      }

      final RecordRepositoryImpl records = RecordRepositoryImpl(
        db: fixture.db,
        clock: fixture.clock,
        deviceId: 'review-device',
        ids: fixture.ids,
        operatorName: () => 'Review operator',
      );
      const List<RecordValueEdit> corrections = <RecordValueEdit>[
        (fieldKey: 'business_owner', value: 'Corrected business owner'),
        (fieldKey: 'captured_date', value: '2026-09-25'),
        (fieldKey: 'description', value: 'Confirmed equipment description'),
        (fieldKey: 'local_address', value: '192.0.2.25'),
      ];
      expect(await records.editValues(id, corrections), isA<Success<void>>());
      final Map<String, RecordField> corrected = await _fields(fixture, id);
      for (final RecordValueEdit edit in corrections) {
        final RecordField field = corrected[edit.fieldKey]!;
        expect(field.valueFinal, isNull);
        expect(field.source, 'manual');
        expect(field.verified, isTrue);
        if (processed[edit.fieldKey] case final RecordField previous) {
          expect(field.valueRaw, previous.valueRaw);
          expect(field.valueRefined, edit.value);
        } else {
          expect(field.valueRaw, edit.value);
          expect(field.valueRefined, isNull);
        }
      }
      final List<AuditLogData> auditsBefore = await fixture.db
          .select(fixture.db.auditLog)
          .get();
      expect(await records.editValues(id, corrections), isA<Success<void>>());
      expect(await fixture.db.select(fixture.db.auditLog).get(), auditsBefore);

      final ScriptedExtraction reprocessProvider = ScriptedExtraction(<String>[
        hostile,
      ]);
      await _process(fixture, id, reprocessProvider, settings);
      expect(reprocessProvider.requests, isEmpty);
      final Map<String, RecordField> reprocessed = await _fields(fixture, id);
      for (final String key in corrected.keys) {
        expect(
          reprocessed[key]!.valueRaw,
          corrected[key]!.valueRaw,
          reason: key,
        );
        expect(
          reprocessed[key]!.valueRefined,
          corrected[key]!.valueRefined,
          reason: key,
        );
        expect(reprocessed[key]!.source, corrected[key]!.source, reason: key);
      }
      final RecordRow finalRecord = await _record(fixture, id);
      expect(finalRecord.status, RecordStatus.needsReview.stored);
      expect(finalRecord.capturedAt, initialRecord.capturedAt);
      expect(finalRecord.capturedBy, initialRecord.capturedBy);
      expect(finalRecord.recordNumber, initialRecord.recordNumber);
      expect(finalRecord.contextJson, initialRecord.contextJson);
      expect(finalRecord.templateVersion, initialRecord.templateVersion);
      sampledAddress = '198.51.100.7';
      expect((await writer.persist(session)).getOrThrow(), id);
      expect(await _fields(fixture, id), reprocessed);
      expect(reprocessed['local_address']!.valueRaw, '192.0.2.24');
      expect(reprocessed['local_address']!.valueRefined, '192.0.2.25');
      expect(reprocessed['local_address']!.source, 'manual');
    });
  }
}

Future<RecordRow> _record(ProcessingFixture fixture, String id) =>
    (fixture.db.select(
      fixture.db.records,
    )..where((row) => row.id.equals(id))).getSingle();

Future<Map<String, RecordField>> _fields(
  ProcessingFixture fixture,
  String id,
) async => <String, RecordField>{
  for (final RecordField field in await (fixture.db.select(
    fixture.db.recordFields,
  )..where((row) => row.recordId.equals(id))).get())
    field.fieldKey: field,
};

Future<void> _process(
  ProcessingFixture fixture,
  String recordId,
  ScriptedExtraction provider,
  SettingsStore settings, {
  bool expectOfflineQueue = false,
}) async {
  final ProcessingRepositoryImpl repository = ProcessingRepositoryImpl(
    db: fixture.db,
    clock: fixture.clock,
    deviceId: 'processing-device',
    ids: fixture.ids,
    settings: settings,
  );
  final String id = (await repository.enqueue(recordId)).getOrThrow();
  final ProcessingJob job = (await repository.byId(id)).getOrThrow()!;
  final worker = fixture.worker(provider: provider, settings: settings);
  final JobRunner runner = JobRunner(
    perform: worker.perform,
    persist: (ProcessingJob current, JobStage stage) async =>
        (await repository.markStage(current.id, stage)).getOrThrow(),
    release: (ProcessingJob current) async {
      (await repository.release(current.id)).getOrThrow();
      return current;
    },
  );
  if (expectOfflineQueue) {
    await expectLater(
      runner.run(job, token: CancellationToken()),
      throwsA(isA<CancelledFailure>()),
    );
    (await repository.release(id)).getOrThrow();
    final ProcessingJob queued = (await repository.byId(id)).getOrThrow()!;
    expect(
      queued.completedStages,
      containsAll(<JobStage>[
        JobStage.prepare,
        JobStage.onDevice,
        JobStage.detect,
      ]),
    );
    expect(queued.completedStages, isNot(contains(JobStage.online)));
    return;
  }
  final JobRun result = await runner.run(job, token: CancellationToken());
  expect(result.cancelled, isFalse);
  expect(result.paused, isFalse);
  expect(result.job.completedStages, containsAll(JobStage.values));
  (await repository.complete(result.job.id)).getOrThrow();
}

import 'dart:io';
import 'dart:ui' show Rect;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/db/tables/template_rows.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/compressed_copy.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_record_writer.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/capture_session.dart'
    as capture;
import 'package:tapture/features/processing/data/ocr_cache.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/data/response_store.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'prepare and on-device stages preserve the original and cache OCR',
    () async {
      final AppDatabase db = await seededDatabase(records: 1);
      addTearDown(db.close);
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture_processing_local_',
      );
      addTearDown(() {
        if (documents.existsSync()) {
          documents.deleteSync(recursive: true);
        }
      });
      final RecordRow record = await db.select(db.records).getSingle();
      final File original = File(
        '${documents.path}/Tapture/projects/seeded-project/'
        'photos/${record.id}/img-0.jpg',
      );
      await original.parent.create(recursive: true);
      final List<int> originalBytes = OcrService.paintPlate('SN458923');
      await original.writeAsBytes(originalBytes);
      final DateTime now = DateTime.utc(2026, 9, 23, 8);
      final FixedClock clock = FixedClock(now);
      final StorageRoot storageRoot = StorageRoot.fake(
        documentsDirectory: documents,
      );
      final ProcessingStageWorker worker = ProcessingStageWorker(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
        storageRoot: storageRoot,
        ocr: OcrService(),
        providers: ProviderRegistry.keyless(),
        settings: SettingsStore.fake(),
      );
      final ProcessingJob job = ProcessingJob(
        id: 'job-local',
        recordId: record.id,
      );

      await worker.perform(JobStage.prepare, job);
      await worker.perform(JobStage.onDevice, job);

      expect(await original.readAsBytes(), originalBytes);
      final written = _ok(
        await CompressedCopy(storageRoot: storageRoot).reduce(original.path),
      );
      final Directory root = _ok(await storageRoot.resolve());
      final String reducedPath = '${root.path}/${written.relativePath}';
      expect((await OcrService().recognise(reducedPath)).text, 'SN458923');
      expect(
        (await OcrService().recognise('$reducedPath.ocr.jpg')).text,
        'SN458923',
      );
      final OcrCacheEntry cached = await db
          .select(db.ocrCacheEntries)
          .getSingle();
      expect(cached.contentHash, 'sha-0');
      expect(cached.recognisedText, 'SN458923');
    },
  );

  test(
    'text-only extraction stores raw output then writes an evidenced proposal',
    () async {
      final AppDatabase db = await seededDatabase(records: 1);
      addTearDown(db.close);
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture_processing_worker_',
      );
      addTearDown(() {
        if (documents.existsSync()) {
          documents.deleteSync(recursive: true);
        }
      });
      final DateTime now = DateTime.utc(2026, 9, 23, 8);
      final FixedClock clock = FixedClock(now);
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      final RecordRow record = await db.select(db.records).getSingle();
      await (db.update(
        db.projects,
      )..where(($ProjectsTable table) => table.id.equals(project.id))).write(
        const ProjectsCompanion(
          settings: Value<String>('{"doNotSendImages":true}'),
        ),
      );
      _ok(
        await upsertTemplateField(
          db,
          row: TemplateFieldsCompanion(
            templateId: Value<String>(template.id),
            fieldKey: const Value<String>('serial'),
            label: const Value<String>('Serial number'),
            type: const Value<String>('text'),
            isRequired: const Value<bool>(true),
            sortOrder: const Value<int>(0),
          ),
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await insertCaption(
          db,
          row: CaptionsCompanion(
            ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.record),
            ownerId: Value<String>(record.id),
            textRaw: const Value<String>('Serial ABC123 is visible.'),
            inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
          ),
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final SettingsStore settings = SettingsStore.fake();
      final _ExtractionService service = _ExtractionService();
      final ProcessingRepositoryImpl repository = ProcessingRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        settings: settings,
      );
      final String jobId = _ok(await repository.enqueue(record.id));
      final ProcessingJob job = _ok(
        await repository.claim(const Duration(minutes: 5)),
      )!;
      expect(job.id, jobId);
      final ProcessingStageWorker worker = ProcessingStageWorker(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        storageRoot: StorageRoot.fake(documentsDirectory: documents),
        ocr: OcrService(),
        providers: ProviderRegistry.keyless(proxy: service),
        settings: settings,
      );

      final ({int imageCount, int payloadBytes}) egress = await worker
          .egressSummary(job);
      expect(egress.imageCount, 0);
      expect(egress.payloadBytes, greaterThan(0));
      await worker.perform(JobStage.online, job);
      await worker.perform(JobStage.validate, job);

      expect(service.calls, 2);
      expect(service.lastRequest?.imagePaths, isEmpty);
      expect(
        service.lastRequest?.captions,
        contains('Serial ABC123 is visible.'),
      );
      expect(service.lastRequest?.repairError, isNotEmpty);
      final List<ProcessingResult> raw = await db
          .select(db.processingResults)
          .get();
      expect(raw, hasLength(2));
      expect(raw.first.parsedOk, isFalse);
      expect(raw.last.rawResponse, contains('ABC123'));
      expect(raw.last.parsedOk, isTrue);
      final RecordField proposal = await db.select(db.recordFields).getSingle();
      expect(proposal.valueRaw, 'ABC123');
      expect(proposal.valueFinal, isNull);
      expect(proposal.confidenceBand, 'high');
      expect(proposal.provider, ProviderRegistry.backendId);
      expect(proposal.model, 'default');
      expect(proposal.promptVersion, 'test-prompt-v1');
      final FieldEvidenceRow evidence = await db
          .select(db.fieldEvidence)
          .getSingle();
      expect(evidence.snippet, contains('ABC123'));
      expect(await db.select(db.auditLog).get(), isNotEmpty);
    },
  );

  test('normalise persists the row match strategy and score', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final DateTime now = DateTime.utc(2026, 9, 23, 8);
    final FixedClock clock = FixedClock(now);
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final Template template = await db.select(db.templates).getSingle();
    final RecordRow record = await db.select(db.records).getSingle();
    final TemplateRow row = _ok(
      await upsertTemplateRow(
        db,
        row: TemplateRowsCompanion(
          templateId: Value<String>(template.id),
          outputRowNumber: const Value<int>(2),
          identifier: const Value<String>('blood-pressure-machine'),
          label: const Value<String>('Blood Pressure Machine'),
          aliases: const Value<String>('["Sphygmomanometer"]'),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await OcrCache(db: db, clock: clock, deviceId: 'device-a', ids: ids).put(
        contentHash: 'sha-0',
        perceptualHash: '',
        result: const OcrResult(text: 'Sphygmomanometer', blocks: <Never>[]),
      ),
    );
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture_processing_match_',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final ProcessingStageWorker worker = ProcessingStageWorker(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      storageRoot: StorageRoot.fake(documentsDirectory: documents),
      ocr: OcrService(),
      providers: ProviderRegistry.keyless(),
      settings: SettingsStore.fake(),
    );

    await worker.perform(
      JobStage.normalise,
      ProcessingJob(id: 'job-match', recordId: record.id),
    );

    final RecordRow matched = await db.select(db.records).getSingle();
    expect(matched.templateRowId, row.id);
    expect(matched.rowMatchStrategy, 'alias');
    expect(matched.rowMatchScore, 0.98);
    final AuditLogData audit = await db.select(db.auditLog).getSingle();
    expect(audit.reason, contains('"method":"alias"'));
    expect(audit.reason, contains('"score":0.98'));
  });

  test(
    'record audio is transcribed once and reused as extraction evidence',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture_processing_audio_',
      );
      addTearDown(() {
        if (documents.existsSync()) {
          documents.deleteSync(recursive: true);
        }
      });
      final DateTime now = DateTime.utc(2026, 9, 23, 8);
      final FixedClock clock = FixedClock(now);
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      _ok(
        await upsertTemplateField(
          db,
          row: TemplateFieldsCompanion(
            templateId: Value<String>(template.id),
            fieldKey: const Value<String>('serial'),
            label: const Value<String>('Serial number'),
            type: const Value<String>('text'),
            isRequired: const Value<bool>(true),
            sortOrder: const Value<int>(0),
          ),
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      );
      final String recordId = _ok(
        await writer.persist(
          capture.CaptureSession(
            id: 'audio-session',
            projectId: project.id,
            templateId: template.id,
            contextSnapshot: const <String, String>{},
            audio: <AudioDraft>[
              AudioDraft(
                id: 'audio-1',
                projectId: project.id,
                relativePath: 'audio/clip.wav',
                mimeType: 'audio/wav',
                fileSize: 4,
                sha256: 'audio-sha',
                durationMs: 1000,
              ),
            ],
          ),
        ),
      );
      final File original = File(
        '${documents.path}/Tapture/projects/seeded-project/audio/clip.wav',
      );
      await original.parent.create(recursive: true);
      const List<int> originalBytes = <int>[1, 2, 3, 4];
      await original.writeAsBytes(originalBytes);

      final SettingsStore settings = SettingsStore.fake();
      final _AudioExtractionService service = _AudioExtractionService();
      final ProcessingRepositoryImpl repository = ProcessingRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        settings: settings,
      );
      final String jobId = _ok(await repository.enqueue(recordId));
      final ProcessingJob job = ProcessingJob(id: jobId, recordId: recordId);
      final ProcessingStageWorker worker = ProcessingStageWorker(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        storageRoot: StorageRoot.fake(documentsDirectory: documents),
        ocr: OcrService(),
        providers: ProviderRegistry.keyless(proxy: service),
        settings: settings,
      );

      await worker.perform(JobStage.online, job);
      await worker.perform(JobStage.online, job);

      expect(service.transcribeCalls, 1);
      expect(service.extractCalls, 1);
      expect(service.lastExtraction?.transcripts, <String>[
        'spoken serial SN-1',
      ]);
      expect(await original.readAsBytes(), originalBytes);
      final List<ProcessingResult> evidence = await db
          .select(db.processingResults)
          .get();
      expect(evidence, hasLength(2));
      expect(
        evidence.any((row) => row.rawResponse == 'spoken serial SN-1'),
        isTrue,
      );
    },
  );

  test('high-confidence local identity skips the provider call', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final DateTime now = DateTime.utc(2026, 9, 23, 8);
    final FixedClock clock = FixedClock(now);
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final Template template = await db.select(db.templates).getSingle();
    final RecordRow record = await db.select(db.records).getSingle();
    await (db.update(db.templates)
          ..where(($TemplatesTable table) => table.id.equals(template.id)))
        .write(const TemplatesCompanion(identityFields: Value('["serial"]')));
    _ok(
      await upsertTemplateField(
        db,
        row: TemplateFieldsCompanion(
          templateId: Value<String>(template.id),
          fieldKey: const Value<String>('serial'),
          label: const Value<String>('Serial number'),
          type: const Value<String>('text'),
          isRequired: const Value<bool>(true),
          validation: const Value<String>('{"pattern":"SN[0-9]{6}"}'),
          sortOrder: const Value<int>(0),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await OcrCache(db: db, clock: clock, deviceId: 'device-a', ids: ids).put(
        contentHash: 'sha-0',
        perceptualHash: '0123456789abcdef',
        result: const OcrResult(
          text: 'SN458923',
          blocks: <OcrBlock>[
            OcrBlock(
              text: 'SN458923',
              bounds: Rect.fromLTRB(1, 1, 40, 12),
              confidence: 0.98,
            ),
          ],
        ),
      ),
    );
    final SettingsStore settings = SettingsStore.fake();
    final ProcessingRepositoryImpl repository = ProcessingRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      settings: settings,
    );
    final String jobId = _ok(await repository.enqueue(record.id));
    final _ExtractionService service = _ExtractionService();
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture_processing_skip_',
    );
    addTearDown(() => documents.deleteSync(recursive: true));
    final ProcessingStageWorker worker = ProcessingStageWorker(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      storageRoot: StorageRoot.fake(documentsDirectory: documents),
      ocr: OcrService(),
      providers: ProviderRegistry.keyless(proxy: service),
      settings: settings,
    );

    await worker.perform(
      JobStage.online,
      ProcessingJob(id: jobId, recordId: record.id),
    );

    expect(service.calls, 0);
    final ProcessingJob stored = _ok(await repository.byId(jobId))!;
    expect(stored.skipReason, contains('Local extraction'));
  });

  test('a valid crash-saved response is reused without another call', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final DateTime now = DateTime.utc(2026, 9, 23, 8);
    final FixedClock clock = FixedClock(now);
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final Project project = await db.select(db.projects).getSingle();
    final Template template = await db.select(db.templates).getSingle();
    final RecordRow record = await db.select(db.records).getSingle();
    await (db.update(
      db.projects,
    )..where(($ProjectsTable table) => table.id.equals(project.id))).write(
      const ProjectsCompanion(
        settings: Value<String>('{"doNotSendImages":true}'),
      ),
    );
    _ok(
      await upsertTemplateField(
        db,
        row: TemplateFieldsCompanion(
          templateId: Value<String>(template.id),
          fieldKey: const Value<String>('serial'),
          label: const Value<String>('Serial number'),
          type: const Value<String>('text'),
          isRequired: const Value<bool>(true),
          sortOrder: const Value<int>(0),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final SettingsStore settings = SettingsStore.fake();
    final ProcessingRepositoryImpl repository = ProcessingRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      settings: settings,
    );
    final String jobId = _ok(await repository.enqueue(record.id));
    final ResponseStore responses = ResponseStore(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
    );
    _ok(
      await responses.save(
        jobId: jobId,
        requestSummary:
            '{"kind":"online","batchKey":"0:","repair":false,'
            '"provider":"saved-provider","model":"saved-model"}',
        rawResponse:
            '{"fields":{"serial":{"value":"ABC123",'
            '"confidence":0.95,"evidence":["ABC123"]}}}',
        parsedOk: false,
      ),
    );
    final _ExtractionService service = _ExtractionService();
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture_processing_reuse_',
    );
    addTearDown(() => documents.deleteSync(recursive: true));
    final ProcessingStageWorker worker = ProcessingStageWorker(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      storageRoot: StorageRoot.fake(documentsDirectory: documents),
      ocr: OcrService(),
      providers: ProviderRegistry.keyless(proxy: service),
      settings: settings,
    );

    await worker.perform(
      JobStage.online,
      ProcessingJob(id: jobId, recordId: record.id),
    );

    expect(service.calls, 0);
    expect(
      (await db.select(db.processingResults).getSingle()).parsedOk,
      isTrue,
    );
    final ProcessingJob stored = _ok(await repository.byId(jobId))!;
    expect(stored.provider, 'saved-provider');
    expect(stored.model, 'saved-model');
  });
}

final class _ExtractionService implements AiService {
  var calls = 0;
  ExtractFieldsRequest? lastRequest;

  @override
  bool get isAvailable => true;

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
    calls++;
    lastRequest = request;
    if (calls == 1) {
      return const Success<ExtractFieldsResult>(
        ExtractFieldsResult(
          fields: <String, String?>{},
          rawResponse: '{"fields":',
          provider: 'test-provider',
          model: 'test-model',
          promptVersion: 'test-prompt-v1',
        ),
      );
    }
    return const Success<ExtractFieldsResult>(
      ExtractFieldsResult(
        fields: <String, String?>{'serial': 'ABC123'},
        rawResponse:
            '{"fields":{"serial":{"value":"ABC123","confidence":0.95,"evidence":["ABC123"]}}}',
        provider: 'test-provider',
        model: 'test-model',
        promptVersion: 'test-prompt-v1',
      ),
    );
  }

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) async {
    return const FailureResult<ReadTextResult>(ProviderFailure());
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) async {
    return const FailureResult<RefineTextResult>(ProviderFailure());
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) async {
    return const FailureResult<TranscribeResult>(ProviderFailure());
  }
}

final class _AudioExtractionService implements AiService {
  int transcribeCalls = 0;
  int extractCalls = 0;
  ExtractFieldsRequest? lastExtraction;

  @override
  bool get isAvailable => true;

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) async {
    return const Success<ReadTextResult>(ReadTextResult(text: ''));
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
    extractCalls += 1;
    lastExtraction = request;
    return const Success<ExtractFieldsResult>(
      ExtractFieldsResult(
        fields: <String, String?>{'serial': 'SN-1'},
        rawResponse:
            '{"fields":{"serial":{"value":"SN-1","confidence":0.9,'
            '"evidence":["spoken serial SN-1"]}}}',
        provider: ProviderRegistry.backendId,
        model: 'default',
        promptVersion: 'test-v1',
      ),
    );
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) async {
    return Success<RefineTextResult>(RefineTextResult(text: request.raw));
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) async {
    transcribeCalls += 1;
    return const Success<TranscribeResult>(
      TranscribeResult(text: 'spoken serial SN-1'),
    );
  }
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}

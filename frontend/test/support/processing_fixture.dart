import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/db/tables/template_rows.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/data/record_bundle.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';
import 'package:tapture/features/processing/data/response_store.dart';
import 'package:tapture/features/processing/data/stage_settings.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import 'factories.dart';

/// One seeded record on an in-memory database, with real plate photos under
/// a temporary storage root, for the processing stage tests.
///
/// The record's first photo is the seeded one; [open] adds more. Every photo
/// file is a plate painted in the reader's face, so on-device reading works
/// with the network off.
final class ProcessingFixture {
  ProcessingFixture._({
    required this.db,
    required this.documents,
    required this.storageRoot,
    required this.clock,
    required this.ids,
    required this.project,
    required this.template,
    required this.record,
  });

  /// The database.
  final AppDatabase db;

  /// The temporary documents folder.
  final Directory documents;

  /// The storage root over [documents].
  final StorageRoot storageRoot;

  /// The fixed clock every write uses.
  final FixedClock clock;

  /// The id sequence every write uses.
  final UuidV7Service ids;

  /// The seeded project.
  final Project project;

  /// The seeded template.
  final Template template;

  /// The seeded record.
  final RecordRow record;

  /// Seeds the record with [photos] plates reading [plateText]. Torn down
  /// with the test.
  static Future<ProcessingFixture> open({
    String plateText = 'SN458923',
    int photos = 1,
  }) async {
    final AppDatabase db = await seededDatabase(records: 1);
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture_processing_fixture_',
    );
    addTearDown(() async {
      await db.close();
      if (documents.existsSync()) {
        try {
          documents.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows can still hold a file a reader just closed.
        }
      }
    });
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 26, 8));
    final ProcessingFixture fixture = ProcessingFixture._(
      db: db,
      documents: documents,
      storageRoot: StorageRoot.fake(documentsDirectory: documents),
      clock: clock,
      ids: UuidV7Service.sequence(clock),
      project: await db.select(db.projects).getSingle(),
      template: await db.select(db.templates).getSingle(),
      record: await db.select(db.records).getSingle(),
    );
    final Photo first = await db.select(db.photos).getSingle();
    await fixture.writePlate(first.relativePath, plateText);
    for (var index = 1; index < photos; index++) {
      await fixture.addPhoto(index, plateText: plateText);
    }
    return fixture;
  }

  /// The project folder every photo path is relative to.
  String get projectFolder =>
      '${documents.path}/Tapture/projects/seeded-project';

  /// Paints [text] as a plate at [relativePath] inside the project folder.
  Future<void> writePlate(String relativePath, String text) async {
    final File file = File('$projectFolder/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(paintOcrPlate(text));
  }

  /// Adds photo [index] to the record, in capture order after the others.
  Future<Photo> addPhoto(int index, {String plateText = 'SN458923'}) async {
    final String path = 'photos/${record.id}/img-$index.jpg';
    await writePlate(path, plateText);
    return _ok(
      await upsertPhoto(
        db,
        row: PhotosCompanion(
          projectId: Value<String>(project.id),
          recordId: Value<String?>(record.id),
          captureSessionId: const Value<String>('session-seed'),
          originalFilename: Value<String>('IMG_$index.jpg'),
          storedFilename: Value<String>('img-$index.jpg'),
          relativePath: Value<String>(path),
          photoType: const Value<String>('front'),
          sortOrder: Value<int>(index),
          width: const Value<int>(1600),
          height: const Value<int>(1200),
          fileSize: const Value<int>(2048),
          mimeType: const Value<String>('image/jpeg'),
          sha256: Value<String>('sha-extra-$index'),
          capturedAt: Value<DateTime>(
            clock.nowUtc().add(Duration(minutes: index)),
          ),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      ),
    );
  }

  /// Adds a voice note of [bytes] bytes to the record, linked as the
  /// capture flow links one.
  Future<Attachment> addAudio(int index, {int bytes = 4096}) async {
    final String path = 'audio/${record.id}/note-$index.m4a';
    final File file = File('$projectFolder/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List<int>.filled(bytes, 7));
    final Attachment audio = _ok(
      await upsertAttachment(
        db,
        row: AttachmentsCompanion(
          projectId: Value<String>(project.id),
          relativePath: Value<String>(path),
          mimeType: const Value<String>('audio/mp4'),
          fileSize: Value<int>(bytes),
          sha256: Value<String>('audio-$index'),
          kind: const Value<AttachmentKind>(AttachmentKind.audio),
          durationMs: const Value<int?>(3000),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final DateTime now = clock.nowUtc();
    await db
        .into(db.attachmentOwners)
        .insert(
          AttachmentOwnersCompanion(
            id: Value<String>(ids.newId()),
            attachmentId: Value<String>(audio.id),
            ownerType: const Value<AttachmentOwnerType>(
              AttachmentOwnerType.record,
            ),
            ownerId: Value<String>(record.id),
            sortOrder: Value<int>(index),
            createdAt: Value<DateTime>(now),
            updatedAt: Value<DateTime>(now),
            updatedByDevice: const Value<String>('device-a'),
            rev: const Value<int>(1),
          ),
        );
    return audio;
  }

  /// Marks [keys] as the seeded template's identity fields.
  Future<void> setIdentityFields(List<String> keys) async {
    await (db.update(
      db.templates,
    )..where(($TemplatesTable table) => table.id.equals(template.id))).write(
      TemplatesCompanion(
        identityFields: Value<String>(
          '[${keys.map((String k) => '"${_json(k)}"').join(',')}]',
        ),
      ),
    );
  }

  /// Adds a field to [templateId], the seeded template by default.
  Future<TemplateField> addField(
    String key, {
    String? templateId,
    String type = 'text',
    bool required = false,
    String? pattern,
    String options = '[]',
    String? unit,
    int order = 0,
    String? defaultValue,
  }) async {
    return _ok(
      await upsertTemplateField(
        db,
        row: TemplateFieldsCompanion(
          templateId: Value<String>(templateId ?? template.id),
          fieldKey: Value<String>(key),
          label: Value<String>(key),
          type: Value<String>(type),
          isRequired: Value<bool>(required),
          options: Value<String>(options),
          unit: Value<String?>(unit),
          defaultValue: Value<String?>(defaultValue),
          validation: Value<String>(
            pattern == null ? '{}' : '{"pattern":"${_json(pattern)}"}',
          ),
          sortOrder: Value<int>(order),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      ),
    );
  }

  /// Adds a predefined row to the seeded template.
  Future<TemplateRow> addRow(
    String label, {
    List<String> aliases = const <String>[],
    int number = 2,
  }) async {
    return _ok(
      await upsertTemplateRow(
        db,
        row: TemplateRowsCompanion(
          templateId: Value<String>(template.id),
          outputRowNumber: Value<int>(number),
          identifier: Value<String>(label.toLowerCase().replaceAll(' ', '-')),
          label: Value<String>(label),
          aliases: Value<String>(
            '[${aliases.map((String a) => '"${_json(a)}"').join(',')}]',
          ),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      ),
    );
  }

  /// Adds another template to the project with a detection profile.
  Future<Template> addTemplate(String name, {String detection = '{}'}) async {
    return _ok(
      await upsertTemplate(
        db,
        row: TemplatesCompanion(
          projectId: Value<String?>(project.id),
          name: Value<String>(name),
          kind: const Value<String>('equipment'),
          source: const Value<String>('built'),
          detection: Value<String>(detection),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
      ),
    );
  }

  /// Replaces the seeded template's detection profile.
  Future<void> setDetection(String templateId, String detection) async {
    await (db.update(db.templates)
          ..where(($TemplatesTable table) => table.id.equals(templateId)))
        .write(TemplatesCompanion(detection: Value<String>(detection)));
  }

  /// Replaces the project's settings JSON.
  Future<void> setProjectSettings(String json) async {
    await (db.update(db.projects)
          ..where(($ProjectsTable table) => table.id.equals(project.id)))
        .write(ProjectsCompanion(settings: Value<String>(json)));
  }

  /// Replaces the record's context JSON.
  Future<void> setContext(String json) async {
    await (db.update(db.records)
          ..where(($RecordsTable table) => table.id.equals(record.id)))
        .write(RecordsCompanion(contextJson: Value<String>(json)));
  }

  /// The record as stored now.
  Future<RecordRow> storedRecord() {
    return (db.select(
      db.records,
    )..where(($RecordsTable table) => table.id.equals(record.id))).getSingle();
  }

  /// The record's bundle as a stage would load it.
  Future<RecordBundle> bundle() => RecordBundleLoader(db: db).load(record.id);

  /// Queues the record and returns its job.
  Future<ProcessingJob> job() async {
    final String id = _ok(
      await ProcessingRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        settings: SettingsStore.fake(),
      ).enqueue(record.id),
    );
    return ProcessingJob(id: id, recordId: record.id);
  }

  /// The stored responses, as the stages read and write them.
  ResponseStore get responses =>
      ResponseStore(db: db, clock: clock, deviceId: 'device-a', ids: ids);

  /// Stage settings over [settings] with [provider] as the keyless backend.
  StageSettings stageSettings({SettingsStore? settings, AiService? provider}) {
    return StageSettings(
      settings: settings ?? SettingsStore.fake(),
      providers: ProviderRegistry.keyless(proxy: provider),
    );
  }

  /// A worker over the fixture, with the given reader, provider and store.
  ProcessingStageWorker worker({
    OcrService? ocr,
    AiService? provider,
    SettingsStore? settings,
  }) {
    return ProcessingStageWorker(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      storageRoot: storageRoot,
      ocr: ocr ?? OcrService(),
      providers: ProviderRegistry.keyless(proxy: provider),
      settings: settings ?? SettingsStore.fake(),
    );
  }
}

/// An extraction provider that answers from [responses] in turn, the last one
/// repeating, and records each request it was sent. With [transcript] set it
/// also transcribes every clip to that text.
final class ScriptedExtraction implements AiService {
  /// Creates the provider.
  ScriptedExtraction(this.responses, {this.failure, this.transcript});

  /// Raw response bodies, in the order calls receive them.
  final List<String> responses;

  /// When set, every call fails with this instead.
  final Failure? failure;

  /// What every transcription returns, or null when it is not scripted.
  final String? transcript;

  /// Every extraction request made.
  final List<ExtractFieldsRequest> requests = <ExtractFieldsRequest>[];

  /// Every transcription request made.
  final List<TranscribeRequest> transcriptions = <TranscribeRequest>[];

  @override
  bool get isAvailable => true;

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
    requests.add(request);
    final Failure? failing = failure;
    if (failing != null) {
      return FailureResult<ExtractFieldsResult>(failing);
    }
    final String raw =
        responses[requests.length - 1 < responses.length
            ? requests.length - 1
            : responses.length - 1];
    return Success<ExtractFieldsResult>(
      ExtractFieldsResult(
        fields: const <String, String?>{},
        rawResponse: raw,
        provider: 'backend',
        model: 'default',
        promptVersion: 'v1',
      ),
    );
  }

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) async {
    return const FailureResult<ReadTextResult>(
      ProviderFailure(message: 'Not scripted.'),
    );
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) async {
    return const FailureResult<RefineTextResult>(
      ProviderFailure(message: 'Not scripted.'),
    );
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) async {
    transcriptions.add(request);
    final String? text = transcript;
    if (text == null) {
      return const FailureResult<TranscribeResult>(
        ProviderFailure(message: 'Not scripted.'),
      );
    }
    return Success<TranscribeResult>(TranscribeResult(text: text));
  }
}

/// An on-device reader that counts its reads and never touches a photo.
final class CountingOcr implements OcrService {
  /// Creates the reader answering [text].
  CountingOcr(this.text);

  /// What every read returns.
  final String text;

  /// How many reads were made.
  int reads = 0;

  @override
  Future<OcrResult> recognise(String imagePath, {CancellationToken? cancel}) {
    reads++;
    return Future<OcrResult>.value(
      OcrResult(text: text, blocks: const <OcrBlock>[], engine: 'counting'),
    );
  }
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

String _json(String text) =>
    text.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

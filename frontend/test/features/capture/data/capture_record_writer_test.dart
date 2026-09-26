import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_record_writer.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/capture_session.dart'
    as capture;
import 'package:tapture/features/capture/domain/photo_draft.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'one transaction freezes raw capture evidence and is idempotent',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final DateTime now = DateTime.utc(2026, 9, 23, 16, 35);
      final FixedClock clock = FixedClock(now);
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      final capture.CaptureSession session = _session(
        projectId: project.id,
        templateId: template.id,
        now: now,
      );

      expect(_ok(await writer.persist(session)), session.id);
      // A retry after a committed record but failed recovery checkpoint is a
      // no-op, not a second set of immutable captions or fields.
      expect(_ok(await writer.persist(session)), session.id);

      final RecordRow record = await db.select(db.records).getSingle();
      expect(record.id, session.id);
      expect(record.status, 'CAPTURED');
      expect(record.contextJson, '{"country":"Uganda"}');

      final Photo photo = await db.select(db.photos).getSingle();
      expect(photo.recordId, record.id);
      expect(photo.relativePath, 'photos/photo-1.jpg');
      expect(photo.sha256, 'photo-sha');

      final captions = await db.select(db.captions).get();
      expect(captions, hasLength(2));
      expect(
        captions.map((row) => row.textRaw),
        containsAll(<String>['Record note', 'Photo note']),
      );

      final fields = await db.select(db.recordFields).get();
      expect(fields, hasLength(2));
      expect(
        fields.singleWhere((row) => row.fieldKey == 'country').source,
        'CONTEXT',
      );
      expect(
        fields.singleWhere((row) => row.fieldKey == 'serial').valueRaw,
        'SN-42',
      );

      final Attachment attachment = await db.select(db.attachments).getSingle();
      expect(attachment.durationMs, 1250);
      expect(await db.select(db.attachmentOwners).get(), hasLength(2));
    },
  );

  test(
    'a photo write failure rolls the previously inserted record back',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final DateTime now = DateTime.utc(2026, 9, 23, 16, 35);
      final FixedClock clock = FixedClock(now);
      final CaptureRecordWriter writer = CaptureRecordWriter(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final Project project = await db.select(db.projects).getSingle();
      final Template template = await db.select(db.templates).getSingle();
      final capture.CaptureSession invalid = _session(
        projectId: project.id,
        templateId: template.id,
        now: now,
        photoPath: '/outside/photo.jpg',
      );

      expect(await writer.persist(invalid), isA<FailureResult<String>>());
      expect(await db.select(db.records).get(), isEmpty);
      expect(await db.select(db.photos).get(), isEmpty);
      expect(await db.select(db.captions).get(), isEmpty);
      expect(await db.select(db.recordFields).get(), isEmpty);
    },
  );

  test('load returns the saved record as an edit session', () async {
    final _Saved saved = await _saved();

    final capture.CaptureSession edit = _ok(
      await saved.writer.load(saved.recordId),
    );

    expect(edit.editing, isTrue);
    expect(edit.id, saved.recordId);
    expect(edit.recordId, saved.recordId);
    expect(edit.storageKey, 'edit:${saved.recordId}');
    expect(edit.projectId, saved.projectId);
    expect(edit.templateId, saved.templateId);
    expect(edit.contextSnapshot, const <String, String>{'country': 'Uganda'});
    expect(edit.photos.map((PhotoDraft p) => p.id), <String>['photo-1']);
    expect(edit.photos.single.recordId, saved.recordId);
    expect(edit.photos.single.hasCaption, isTrue);
    expect(edit.captions, const <String, String>{
      '': 'Record note',
      'photo-1': 'Photo note',
    });
    expect(edit.audio.single.id, 'audio-1');
    expect(edit.audio.single.photoIds, const <String>['photo-1']);
    expect(edit.values, isEmpty);

    expect(
      await saved.writer.load('missing'),
      isA<FailureResult<capture.CaptureSession>>(),
    );
  });

  test('update files, tombstones and refines only what changed', () async {
    final _Saved saved = await _saved();
    final AppDatabase db = saved.db;
    final capture.CaptureSession edit = _ok(
      await saved.writer.load(saved.recordId),
    );
    final RecordRow before = await db.select(db.records).getSingle();
    final List<RecordField> fieldsBefore = await db
        .select(db.recordFields)
        .get();
    // A photo added during the edit is a draft row off the record.
    final PhotoDraft added = await _draft(saved, 'photo-2');

    _ok(
      await saved.writer.update(
        edit.copyWith(
          photos: <PhotoDraft>[added.copyWith(sortOrder: 1)],
          captions: const <String, String>{
            '': 'Record note, boiler room',
            'photo-2': 'Gauge',
          },
          isDirty: true,
        ),
      ),
    );

    final Photo filed = await (db.select(
      db.photos,
    )..where((row) => row.id.equals('photo-2'))).getSingle();
    expect(filed.recordId, saved.recordId);
    expect(filed.sortOrder, 1);
    final List<Tombstone> tombstones = await db.select(db.tombstones).get();
    expect(tombstones.single.entityId, 'photo-1');
    // The removed photo's row stays, so its file is kept for the purge job.
    expect(
      await (db.select(
        db.photos,
      )..where((row) => row.id.equals('photo-1'))).getSingleOrNull(),
      isNotNull,
    );

    final Caption record =
        await (db.select(db.captions)..where(
              (row) => row.ownerType.equalsValue(CaptionOwnerType.record),
            ))
            .getSingle();
    expect(record.textRaw, 'Record note');
    expect(record.textRefined, 'Record note, boiler room');
    final Caption gauge = await (db.select(
      db.captions,
    )..where((row) => row.ownerId.equals('photo-2'))).getSingle();
    expect(gauge.textRaw, 'Gauge');
    expect(gauge.textRefined, isNull);

    final List<RecordField> fieldsAfter = await db
        .select(db.recordFields)
        .get();
    expect(
      fieldsAfter.map((RecordField f) => '${f.fieldKey}=${f.valueRaw}'),
      fieldsBefore.map((RecordField f) => '${f.fieldKey}=${f.valueRaw}'),
    );
    final RecordRow after = await db.select(db.records).getSingle();
    expect(after.rev, before.rev + 1);
    expect(after.status, before.status);
    expect(after.templateId, before.templateId);
    expect(after.contextJson, before.contextJson);

    final capture.CaptureSession reloaded = _ok(
      await saved.writer.load(saved.recordId),
    );
    expect(reloaded.photos.map((PhotoDraft p) => p.id), <String>['photo-2']);
    expect(reloaded.captions[''], 'Record note, boiler room');
    expect(reloaded.captions['photo-2'], 'Gauge');
  });

  test('a failing update rolls every change back', () async {
    final _Saved saved = await _saved();
    final AppDatabase db = saved.db;
    final capture.CaptureSession edit = _ok(
      await saved.writer.load(saved.recordId),
    );
    final RecordRow before = await db.select(db.records).getSingle();

    final Result<void> result = await saved.writer.update(
      edit.copyWith(
        photos: <PhotoDraft>[
          PhotoDraft(
            id: 'photo-bad',
            projectId: saved.projectId,
            relativePath: '/outside/photo.jpg',
            sha256: 'bad-sha',
          ),
        ],
        captions: const <String, String>{'': 'Changed'},
      ),
    );

    expect(result, isA<FailureResult<void>>());
    expect(await db.select(db.tombstones).get(), isEmpty);
    final Caption record =
        await (db.select(db.captions)..where(
              (row) => row.ownerType.equalsValue(CaptionOwnerType.record),
            ))
            .getSingle();
    expect(record.textRefined, isNull);
    expect((await db.select(db.records).getSingle()).rev, before.rev);
    expect(
      await (db.select(
        db.photos,
      )..where((row) => row.id.equals('photo-bad'))).getSingleOrNull(),
      isNull,
    );
  });

  test('only an edit session can update a record', () async {
    final _Saved saved = await _saved();
    final capture.CaptureSession edit = _ok(
      await saved.writer.load(saved.recordId),
    );
    expect(
      await saved.writer.update(edit.copyWith(editing: false)),
      isA<FailureResult<void>>(),
    );
  });
}

typedef _Saved = ({
  AppDatabase db,
  CaptureRecordWriter writer,
  String recordId,
  String projectId,
  String templateId,
  DateTime now,
});

/// A database holding one saved record from [_session].
Future<_Saved> _saved() async {
  final AppDatabase db = await seededDatabase();
  addTearDown(db.close);
  final DateTime now = DateTime.utc(2026, 9, 23, 16, 35);
  final FixedClock clock = FixedClock(now);
  final CaptureRecordWriter writer = CaptureRecordWriter(
    db: db,
    clock: clock,
    deviceId: 'device-a',
    ids: UuidV7Service.sequence(clock),
  );
  final Project project = await db.select(db.projects).getSingle();
  final Template template = await db.select(db.templates).getSingle();
  final String recordId = _ok(
    await writer.persist(
      _session(projectId: project.id, templateId: template.id, now: now),
    ),
  );
  return (
    db: db,
    writer: writer,
    recordId: recordId,
    projectId: project.id,
    templateId: template.id,
    now: now,
  );
}

/// A photo written during an edit: a row with its file, not yet filed.
Future<PhotoDraft> _draft(_Saved saved, String id) async {
  final PhotoDraft photo = PhotoDraft(
    id: id,
    projectId: saved.projectId,
    captureSessionId: saved.recordId,
    originalFilename: '$id.jpg',
    storedFilename: '$id.jpg',
    relativePath: 'photos/$id.jpg',
    sha256: '$id-sha',
    fileSize: 1024,
    capturedAt: saved.now,
  );
  final FixedClock clock = FixedClock(saved.now);
  _ok(
    await upsertPhoto(
      saved.db,
      row: PhotosCompanion(
        id: Value<String>(photo.id),
        projectId: Value<String>(photo.projectId),
        captureSessionId: Value<String>(photo.captureSessionId),
        originalFilename: Value<String>(photo.originalFilename),
        storedFilename: Value<String>(photo.storedFilename),
        relativePath: Value<String>(photo.relativePath),
        photoType: Value<String>(photo.photoType),
        sortOrder: Value<int>(photo.sortOrder),
        width: Value<int>(photo.width),
        height: Value<int>(photo.height),
        sha256: Value<String>(photo.sha256),
        fileSize: Value<int>(photo.fileSize),
        mimeType: Value<String>(photo.mimeType),
        capturedAt: Value<DateTime>(saved.now),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    ),
  );
  return photo;
}

capture.CaptureSession _session({
  required String projectId,
  required String templateId,
  required DateTime now,
  String photoPath = 'photos/photo-1.jpg',
}) {
  return capture.CaptureSession(
    id: 'session-1',
    projectId: projectId,
    templateId: templateId,
    contextSnapshot: const <String, String>{'country': 'Uganda'},
    photos: <PhotoDraft>[
      PhotoDraft(
        id: 'photo-1',
        projectId: projectId,
        captureSessionId: 'session-1',
        originalFilename: 'IMG_0001.jpg',
        storedFilename: 'photo-1.jpg',
        relativePath: photoPath,
        sha256: 'photo-sha',
        fileSize: 2048,
        width: 1600,
        height: 1200,
        capturedAt: now,
        hasCaption: true,
      ),
    ],
    audio: <AudioDraft>[
      AudioDraft(
        id: 'audio-1',
        projectId: projectId,
        relativePath: 'audio/audio-1.wav',
        mimeType: 'audio/wav',
        fileSize: 4096,
        sha256: 'audio-sha',
        durationMs: 1250,
        photoIds: const <String>['photo-1'],
      ),
    ],
    captions: const <String, String>{
      '': 'Record note',
      'photo-1': 'Photo note',
    },
    values: const <String, Object?>{'serial': 'SN-42'},
    isDirty: true,
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

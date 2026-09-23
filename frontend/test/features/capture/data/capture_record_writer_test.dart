import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
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

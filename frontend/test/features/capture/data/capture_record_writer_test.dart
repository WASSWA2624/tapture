import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/field_evidence.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
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
      expect(record.status, RecordStatus.captured.stored);
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
    'a capture writes the record its own created entry, once and first',
    () async {
      final _Saved saved = await _saved();
      // A retry of the committed session writes nothing more.
      final capture.CaptureSession again = _session(
        projectId: saved.projectId,
        templateId: saved.templateId,
        now: saved.now,
      );
      expect(_ok(await saved.writer.persist(again)), saved.recordId);

      final List<AuditLogData> rows = await saved.db
          .select(saved.db.auditLog)
          .get();
      final List<AuditLogData> created = <AuditLogData>[
        for (final AuditLogData row in rows)
          if (row.entityType == 'records' &&
              row.entityId == saved.recordId &&
              row.fieldKey == null)
            row,
      ];
      expect(created, hasLength(1));
      expect(created.single.action, AuditAction.created);
      expect(created.single.newValue, RecordStatus.captured.stored);
      expect(created.single.reason, 'capture');
      expect(created.single.device, 'device-a');
      expect(created.single.at.toUtc(), saved.now);
      // The field rows follow it, so the history reads capture first.
      final List<AuditLogData> forRecord = <AuditLogData>[
        for (final AuditLogData row in rows)
          if (row.entityType == 'records' && row.entityId == saved.recordId)
            row,
      ];
      expect(forRecord.first, created.single);
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
      expect(await db.select(db.auditLog).get(), isEmpty);
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

  group('a photo removed from a saved record', () {
    test('flags the values it was the only evidence for and keeps them, '
        'while values still seen on a live photo and typed values stay '
        'unflagged', () async {
      final _Saved saved = await _savedWithTwoPhotos();
      final AppDatabase db = saved.db;
      // model was read only from photo-1; rating from both photos; maker
      // only from photo-2; serial was typed, even though a region of
      // photo-1 shows it.
      final String model = await _readValue(saved, 'model', 'X200', <String>[
        'photo-1',
      ]);
      final String rating = await _readValue(saved, 'rating', '5 kW', <String>[
        'photo-1',
        'photo-2',
      ]);
      final String maker = await _readValue(saved, 'maker', 'Acme', <String>[
        'photo-2',
      ]);
      final String serial = (await _fieldByKey(db, 'serial')).id;
      await _linkEvidence(saved, serial, 'photo-1');
      final int valuesBefore = (await db.select(db.recordFields).get()).length;

      await _removePhoto(saved, 'photo-1');

      final RecordField flagged = await _fieldById(db, model);
      expect(flagged.evidenceRemovedAt?.toUtc(), saved.now);
      // Flagged, never deleted: the value and its text are all still there.
      expect(flagged.valueRaw, 'X200');
      expect(flagged.source, 'ocr');
      expect(await db.select(db.recordFields).get(), hasLength(valuesBefore));
      expect((await _fieldById(db, rating)).evidenceRemovedAt, isNull);
      expect((await _fieldById(db, maker)).evidenceRemovedAt, isNull);
      expect((await _fieldById(db, serial)).evidenceRemovedAt, isNull);
      expect((await _fieldById(db, serial)).valueRaw, 'SN-42');
      // Its evidence rows stay too, so the history can say what was seen.
      expect(
        await (db.select(
          db.fieldEvidence,
        )..where((row) => row.recordFieldId.equals(model))).get(),
        hasLength(1),
      );

      final List<AuditLogData> flags = <AuditLogData>[
        for (final AuditLogData row in await db.select(db.auditLog).get())
          if (row.reason == evidenceRemovedAuditReason) row,
      ];
      expect(flags, hasLength(1));
      expect(flags.single.entityType, 'records');
      expect(flags.single.entityId, saved.recordId);
      expect(flags.single.fieldKey, 'model');
      expect(flags.single.previousValue, 'false');
      expect(flags.single.newValue, 'true');
    });

    test('flags a value once every photo it was read from is gone', () async {
      final _Saved saved = await _savedWithTwoPhotos();
      final String rating = await _readValue(saved, 'rating', '5 kW', <String>[
        'photo-1',
        'photo-2',
      ]);

      await _removePhoto(saved, 'photo-1');
      expect((await _fieldById(saved.db, rating)).evidenceRemovedAt, isNull);

      await _removePhoto(saved, 'photo-2');
      final RecordField flagged = await _fieldById(saved.db, rating);
      expect(flagged.evidenceRemovedAt, isNotNull);
      expect(flagged.valueRaw, '5 kW');
    });

    test('keeps a value live when an edited copy of its photo is filed in '
        'the same edit', () async {
      final _Saved saved = await _saved();
      final String model = await _readValue(saved, 'model', 'X200', <String>[
        'photo-1',
      ]);
      final capture.CaptureSession edit = _ok(
        await saved.writer.load(saved.recordId),
      );
      final PhotoDraft cropped = await _draft(
        saved,
        'photo-1-crop',
        derivedFrom: 'photo-1',
      );

      _ok(
        await saved.writer.update(
          edit.copyWith(photos: <PhotoDraft>[cropped], isDirty: true),
        ),
      );

      expect(
        (await _tombstonedPhotos(saved.db)).single,
        'photo-1',
        reason: 'the original left the record',
      );
      expect((await _fieldById(saved.db, model)).evidenceRemovedAt, isNull);
    });

    test('writes a history row for every photo added and removed', () async {
      final _Saved saved = await _saved();
      final capture.CaptureSession edit = _ok(
        await saved.writer.load(saved.recordId),
      );
      final PhotoDraft added = await _draft(saved, 'photo-2');

      _ok(
        await saved.writer.update(
          edit.copyWith(photos: <PhotoDraft>[added], isDirty: true),
        ),
      );

      final List<AuditLogData> photos = await _photoAudit(saved);
      expect(
        <String>[
          for (final AuditLogData row in photos)
            '${row.newValue}:${row.reason}',
        ],
        <String>['removed:photo-1', 'added:photo-2'],
      );
      for (final AuditLogData row in photos) {
        expect(row.entityType, 'records');
        expect(row.entityId, saved.recordId);
        expect(row.action, AuditAction.updated);
        expect(row.previousValue, isNull);
        expect(row.device, 'device-a');
        expect(row.at.toUtc(), saved.now);
      }
    });

    test('an edit that only changes a caption writes no photo history and '
        'flags nothing', () async {
      final _Saved saved = await _saved();
      final String model = await _readValue(saved, 'model', 'X200', <String>[
        'photo-1',
      ]);
      final capture.CaptureSession edit = _ok(
        await saved.writer.load(saved.recordId),
      );

      _ok(
        await saved.writer.update(
          edit.copyWith(
            captions: const <String, String>{
              '': 'Record note, pump room',
              'photo-1': 'Photo note',
            },
            isDirty: true,
          ),
        ),
      );

      expect(await _photoAudit(saved), isEmpty);
      expect((await _fieldById(saved.db, model)).evidenceRemovedAt, isNull);
    });
  });

  group('the status after a saved record is edited', () {
    test('an approved record whose photos change goes back to review, with '
        'the move in its history', () async {
      final _Saved saved = await _savedWithTwoPhotos();
      await _approve(saved);
      final RecordRow before = await saved.db
          .select(saved.db.records)
          .getSingle();

      await _removePhoto(saved, 'photo-2');

      final RecordRow after = await saved.db
          .select(saved.db.records)
          .getSingle();
      expect(after.status, RecordStatus.needsReview.stored);
      expect(after.rev, greaterThan(before.rev));
      // Leaving approved keeps who approved it, for the history.
      expect(after.approvedAt, isNotNull);
      final AuditLogData moved = (await _statusAudit(saved)).last;
      expect(moved.previousValue, RecordStatus.approved.stored);
      expect(moved.newValue, RecordStatus.needsReview.stored);
      expect(moved.reason, isNotEmpty);
      expect(moved.device, 'device-a');
    });

    test(
      'an approved record whose caption changes goes back to review',
      () async {
        final _Saved saved = await _saved();
        await _approve(saved);
        final capture.CaptureSession edit = _ok(
          await saved.writer.load(saved.recordId),
        );

        _ok(
          await saved.writer.update(
            edit.copyWith(
              captions: <String, String>{...edit.captions, '': 'Checked again'},
              isDirty: true,
            ),
          ),
        );

        expect(
          (await saved.db.select(saved.db.records).getSingle()).status,
          RecordStatus.needsReview.stored,
        );
      },
    );

    test('an approved record saved without a change stays approved', () async {
      final _Saved saved = await _saved();
      await _approve(saved);
      final int statusRows = (await _statusAudit(saved)).length;
      final capture.CaptureSession edit = _ok(
        await saved.writer.load(saved.recordId),
      );

      _ok(await saved.writer.update(edit.copyWith(isDirty: true)));

      expect(
        (await saved.db.select(saved.db.records).getSingle()).status,
        RecordStatus.approved.stored,
      );
      expect(await _statusAudit(saved), hasLength(statusRows));
      expect(await _photoAudit(saved), isEmpty);
    });

    test('a record that is not approved keeps its status', () async {
      final _Saved saved = await _savedWithTwoPhotos();
      final int statusRows = (await _statusAudit(saved)).length;

      await _removePhoto(saved, 'photo-2');

      expect(
        (await saved.db.select(saved.db.records).getSingle()).status,
        RecordStatus.captured.stored,
      );
      expect(await _statusAudit(saved), hasLength(statusRows));
    });

    test(
      'a failing edit rolls back its photo history, flags and status',
      () async {
        final _Saved saved = await _saved();
        final String model = await _readValue(saved, 'model', 'X200', <String>[
          'photo-1',
        ]);
        await _approve(saved);
        final int auditBefore =
            (await saved.db.select(saved.db.auditLog).get()).length;
        final capture.CaptureSession edit = _ok(
          await saved.writer.load(saved.recordId),
        );

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
          ),
        );

        expect(result, isA<FailureResult<void>>());
        expect(await _tombstonedPhotos(saved.db), isEmpty);
        expect((await _fieldById(saved.db, model)).evidenceRemovedAt, isNull);
        expect(
          (await saved.db.select(saved.db.records).getSingle()).status,
          RecordStatus.approved.stored,
        );
        expect(
          await saved.db.select(saved.db.auditLog).get(),
          hasLength(auditBefore),
        );
      },
    );
  });
}

/// [_saved] with a second photo, photo-2, filed on the record by an edit.
Future<_Saved> _savedWithTwoPhotos() async {
  final _Saved saved = await _saved();
  final capture.CaptureSession edit = _ok(
    await saved.writer.load(saved.recordId),
  );
  final PhotoDraft second = await _draft(saved, 'photo-2');
  _ok(
    await saved.writer.update(
      edit.copyWith(
        photos: <PhotoDraft>[...edit.photos, second.copyWith(sortOrder: 1)],
        isDirty: true,
      ),
    ),
  );
  return saved;
}

/// Saves an edit of [saved]'s record without the photo [photoId].
Future<void> _removePhoto(_Saved saved, String photoId) async {
  final capture.CaptureSession edit = _ok(
    await saved.writer.load(saved.recordId),
  );
  _ok(
    await saved.writer.update(
      edit.copyWith(
        photos: <PhotoDraft>[
          for (final PhotoDraft photo in edit.photos)
            if (photo.id != photoId) photo,
        ],
        isDirty: true,
      ),
    ),
  );
}

/// A value processing read as [text] for [fieldKey] from [photoIds]: an OCR
/// row with one photo evidence row per photo. Returns the value's id.
Future<String> _readValue(
  _Saved saved,
  String fieldKey,
  String text,
  List<String> photoIds,
) async {
  final FixedClock clock = FixedClock(saved.now);
  final RecordField value = _ok(
    await insertRecordField(
      saved.db,
      // Explicit ids: a fresh id sequence repeats the writer's own ids.
      row: RecordFieldsCompanion(
        id: Value<String>('value-$fieldKey'),
        recordId: Value<String>(saved.recordId),
        fieldKey: Value<String>(fieldKey),
        valueRaw: Value<String?>(text),
        source: const Value<String>('ocr'),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    ),
  );
  for (final String photoId in photoIds) {
    await _linkEvidence(saved, value.id, photoId);
  }
  return value.id;
}

/// Links value [recordFieldId] to a region of photo [photoId].
Future<void> _linkEvidence(
  _Saved saved,
  String recordFieldId,
  String photoId,
) async {
  final FixedClock clock = FixedClock(saved.now);
  _ok(
    await insertFieldEvidence(
      saved.db,
      row: FieldEvidenceCompanion(
        id: Value<String>('evidence-$recordFieldId-$photoId'),
        recordFieldId: Value<String>(recordFieldId),
        sourceType: const Value<FieldEvidenceSource>(FieldEvidenceSource.photo),
        photoId: Value<String?>(photoId),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    ),
  );
}

/// Approves [saved]'s record, as a reviewer would.
Future<void> _approve(_Saved saved) async {
  final RecordRow record = await saved.db.select(saved.db.records).getSingle();
  await saved.db.transaction(() {
    return writeRecordStatus(
      saved.db,
      recordId: saved.recordId,
      status: RecordStatus.approved.stored,
      previousStatus: record.status,
      clock: FixedClock(saved.now),
      deviceId: 'device-a',
      operator: 'Ada',
      reason: 'approve',
    );
  });
}

Future<RecordField> _fieldById(AppDatabase db, String id) {
  return (db.select(
    db.recordFields,
  )..where((row) => row.id.equals(id))).getSingle();
}

Future<RecordField> _fieldByKey(AppDatabase db, String fieldKey) {
  return (db.select(
    db.recordFields,
  )..where((row) => row.fieldKey.equals(fieldKey))).getSingle();
}

Future<List<String>> _tombstonedPhotos(AppDatabase db) async {
  return <String>[
    for (final Tombstone row in await db.select(db.tombstones).get())
      if (row.entityType == 'photos') row.entityId,
  ];
}

/// [saved]'s record-level photo history rows, in the order written.
Future<List<AuditLogData>> _photoAudit(_Saved saved) {
  return _auditFor(saved, 'photo');
}

/// [saved]'s record-level status history rows, in the order written.
Future<List<AuditLogData>> _statusAudit(_Saved saved) {
  return _auditFor(saved, 'status');
}

Future<List<AuditLogData>> _auditFor(_Saved saved, String fieldKey) async {
  return <AuditLogData>[
    for (final AuditLogData row
        in await saved.db.select(saved.db.auditLog).get())
      if (row.entityType == 'records' &&
          row.entityId == saved.recordId &&
          row.fieldKey == fieldKey)
        row,
  ];
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
/// [derivedFrom] makes it an edited copy of that photo.
Future<PhotoDraft> _draft(
  _Saved saved,
  String id, {
  String? derivedFrom,
}) async {
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
    derivedFrom: derivedFrom,
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
        derivedFrom: Value<String?>(derivedFrom),
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

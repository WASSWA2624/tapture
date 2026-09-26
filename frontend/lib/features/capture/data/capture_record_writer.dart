// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/audio_draft.dart';
import '../domain/capture_record_persistence.dart';
import '../domain/capture_session.dart';
import '../domain/photo_draft.dart';

/// The single transaction boundary that turns a capture session into a raw
/// record. Processing can add proposals later, but never rewrites these raw
/// values or the frozen context object. An edit session later changes the
/// record's evidence through [update], beside the raw values (D6).
final class CaptureRecordWriter implements CaptureRecordPersistence {
  /// Creates a writer over the application database.
  const CaptureRecordWriter({
    required sqlite.AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) : _db = db,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids;

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  /// Persists one complete CAPTURED record or rolls every row back.
  @override
  Future<Result<String>> persist(CaptureSession session) {
    return createRecord(session);
  }

  /// Create-path implementation kept distinct so raw-column guardrails can
  /// prove these values are inserted once and are never refinement updates.
  Future<Result<String>> createRecord(CaptureSession session) {
    return runInTransaction(_db, () async {
      // A capture session owns exactly one raw record. Using its stable id
      // makes a retry safe even when the record transaction committed but the
      // subsequent recovery-session checkpoint could not be written.
      final String recordId = session.recordId ?? session.id;
      final sqlite.RecordRow? committed = await (_db.select(
        _db.records,
      )..where((row) => row.id.equals(recordId))).getSingleOrNull();
      if (committed != null) {
        return recordId;
      }
      final DateTime now = _clock.nowUtc();
      _expect(
        await upsertRecord(
          _db,
          row: sqlite.RecordsCompanion(
            id: Value<String>(recordId),
            projectId: Value<String>(session.projectId),
            templateId: Value<String>(session.templateId),
            status: const Value<String>('CAPTURED'),
            processingMode: const Value<String>('manual'),
            contextJson: Value<String>(jsonEncode(session.contextSnapshot)),
            identityHash: Value<String>(
              sha256.convert(utf8.encode(session.id)).toString(),
            ),
            source: const Value<String>('capture'),
            capturedAt: Value<DateTime>(now),
            capturedBy: Value<String>(_deviceId),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );

      for (final PhotoDraft photo in session.photos) {
        _expect(
          await upsertPhoto(
            _db,
            row: sqlite.PhotosCompanion(
              id: Value<String>(photo.id),
              projectId: Value<String>(photo.projectId),
              recordId: Value<String?>(recordId),
              captureSessionId: Value<String>(photo.captureSessionId),
              originalFilename: Value<String>(photo.originalFilename),
              storedFilename: Value<String>(
                photo.storedFilename.isEmpty
                    ? photo.relativePath.split('/').last
                    : photo.storedFilename,
              ),
              relativePath: Value<String>(photo.relativePath),
              photoType: Value<String>(photo.photoType),
              sortOrder: Value<int>(photo.sortOrder),
              width: Value<int>(photo.width),
              height: Value<int>(photo.height),
              fileSize: Value<int>(photo.fileSize),
              mimeType: Value<String>(photo.mimeType),
              sha256: Value<String>(photo.sha256),
              capturedAt: Value<DateTime>(photo.capturedAt ?? now),
              gpsLat: Value<double?>(photo.gpsLat),
              gpsLon: Value<double?>(photo.gpsLon),
            ),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          ),
        );
      }

      for (
        int audioIndex = 0;
        audioIndex < session.audio.length;
        audioIndex++
      ) {
        final clip = session.audio[audioIndex];
        _expect(
          await upsertAttachment(
            _db,
            row: sqlite.AttachmentsCompanion(
              id: Value<String>(clip.id),
              projectId: Value<String>(clip.projectId),
              relativePath: Value<String>(clip.relativePath),
              mimeType: Value<String>(clip.mimeType),
              fileSize: Value<int>(clip.fileSize),
              sha256: Value<String>(clip.sha256),
              kind: const Value<AttachmentKind>(AttachmentKind.audio),
              durationMs: Value<int?>(clip.durationMs),
            ),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          ),
        );
        await _linkAttachment(
          attachmentId: clip.id,
          ownerType: AttachmentOwnerType.record,
          ownerId: recordId,
          sortOrder: audioIndex,
          now: now,
        );
        for (
          int photoIndex = 0;
          photoIndex < clip.photoIds.length;
          photoIndex++
        ) {
          await _linkAttachment(
            attachmentId: clip.id,
            ownerType: AttachmentOwnerType.photo,
            ownerId: clip.photoIds[photoIndex],
            sortOrder: photoIndex,
            now: now,
          );
        }
      }

      final String recordCaption = session.recordCaption.trim();
      if (recordCaption.isNotEmpty) {
        _expect(
          await insertCaption(
            _db,
            row: sqlite.CaptionsCompanion(
              ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.record),
              ownerId: Value<String>(recordId),
              textRaw: Value<String>(recordCaption),
              inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
            ),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          ),
        );
      }
      for (final PhotoDraft photo in session.photos) {
        final String text = (session.captions[photo.id] ?? '').trim();
        if (text.isEmpty) {
          continue;
        }
        _expect(
          await insertCaption(
            _db,
            row: sqlite.CaptionsCompanion(
              ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.photo),
              ownerId: Value<String>(photo.id),
              textRaw: Value<String>(text),
              inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
            ),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          ),
        );
      }

      final Map<String, ({Object? value, String source})> fields =
          <String, ({Object? value, String source})>{
            for (final MapEntry<String, String> entry
                in session.contextSnapshot.entries)
              entry.key: (value: entry.value, source: 'CONTEXT'),
            for (final MapEntry<String, Object?> entry
                in session.values.entries)
              entry.key: (value: entry.value, source: 'TYPED'),
          };
      for (final MapEntry<String, ({Object? value, String source})> entry
          in fields.entries) {
        _expect(
          await insertRecordField(
            _db,
            row: sqlite.RecordFieldsCompanion(
              recordId: Value<String>(recordId),
              fieldKey: Value<String>(entry.key),
              valueRaw: Value<String?>(_raw(entry.value.value)),
              source: Value<String>(entry.value.source),
            ),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          ),
        );
      }
      return recordId;
    });
  }

  @override
  Future<Result<CaptureSession>> load(String recordId) async {
    try {
      final CaptureSession? session = await _read(recordId);
      if (session == null) {
        return const FailureResult<CaptureSession>(_recordGone);
      }
      return Success<CaptureSession>(session);
    } on Failure catch (failure) {
      return FailureResult<CaptureSession>(failure);
    } on Object catch (error) {
      return FailureResult<CaptureSession>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> update(CaptureSession edited) {
    final String? recordId = edited.recordId;
    if (!edited.editing || recordId == null) {
      return Future<Result<void>>.value(
        const FailureResult<void>(
          ValidationFailure(message: 'Only a record edit can be saved here.'),
        ),
      );
    }
    return runInTransaction(_db, () async {
      final CaptureSession? stored = await _read(recordId);
      if (stored == null) {
        throw _recordGone;
      }
      final DateTime now = _clock.nowUtc();
      final Map<String, PhotoDraft> before = <String, PhotoDraft>{
        for (final PhotoDraft photo in stored.photos) photo.id: photo,
      };
      final Set<String> kept = <String>{
        for (final PhotoDraft photo in edited.photos) photo.id,
      };

      // Removed photos are tombstoned; their files stay for the purge job.
      for (final PhotoDraft photo in stored.photos) {
        if (!kept.contains(photo.id)) {
          await writeTombstone(
            _db,
            entityType: _db.photos.actualTableName,
            entityId: photo.id,
            reason: 'Removed while editing the record.',
            clock: _clock,
            deviceId: _deviceId,
          );
        }
      }

      // A changed caption is refined beside its raw text; a new one is
      // inserted raw. An emptied caption refines to '' (deleted).
      final List<({CaptionOwnerType type, String ownerId, String key})> owners =
          <({CaptionOwnerType type, String ownerId, String key})>[
            (type: CaptionOwnerType.record, ownerId: recordId, key: ''),
            for (final PhotoDraft photo in edited.photos)
              (type: CaptionOwnerType.photo, ownerId: photo.id, key: photo.id),
          ];
      for (final ({CaptionOwnerType type, String ownerId, String key}) owner
          in owners) {
        final String next =
            (owner.key.isEmpty
                    ? edited.recordCaption
                    : edited.captions[owner.key] ?? '')
                .trim();
        final String previous = (stored.captions[owner.key] ?? '').trim();
        if (next == previous) {
          continue;
        }
        final sqlite.Caption? row = await _latestCaption(
          owner.type,
          owner.ownerId,
        );
        if (row == null) {
          if (next.isNotEmpty) {
            _expect(
              await insertCaption(
                _db,
                row: sqlite.CaptionsCompanion(
                  ownerType: Value<CaptionOwnerType>(owner.type),
                  ownerId: Value<String>(owner.ownerId),
                  textRaw: Value<String>(next),
                  inputMode: const Value<CaptionInputMode>(
                    CaptionInputMode.typed,
                  ),
                ),
                clock: _clock,
                deviceId: _deviceId,
                ids: _ids,
              ),
            );
          }
          continue;
        }
        _expect(
          await writeCaptionRefined(
            _db,
            id: row.id,
            textRefined: next,
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          ),
        );
      }

      // Added photos are filed on the record; kept ones take a new order,
      // turn or type.
      for (final PhotoDraft photo in edited.photos) {
        final PhotoDraft? old = before[photo.id];
        if (old == null) {
          _expect(
            await upsertPhoto(
              _db,
              row: sqlite.PhotosCompanion(
                id: Value<String>(photo.id),
                projectId: Value<String>(photo.projectId),
                recordId: Value<String?>(recordId),
                captureSessionId: Value<String>(photo.captureSessionId),
                originalFilename: Value<String>(photo.originalFilename),
                storedFilename: Value<String>(
                  photo.storedFilename.isEmpty
                      ? photo.relativePath.split('/').last
                      : photo.storedFilename,
                ),
                relativePath: Value<String>(photo.relativePath),
                photoType: Value<String>(photo.photoType),
                sortOrder: Value<int>(photo.sortOrder),
                width: Value<int>(photo.width),
                height: Value<int>(photo.height),
                fileSize: Value<int>(photo.fileSize),
                mimeType: Value<String>(photo.mimeType),
                sha256: Value<String>(photo.sha256),
                capturedAt: Value<DateTime>(photo.capturedAt ?? now),
                gpsLat: Value<double?>(photo.gpsLat),
                gpsLon: Value<double?>(photo.gpsLon),
                derivedFrom: Value<String?>(photo.derivedFrom),
                rotationDegrees: Value<int?>(photo.rotationDegrees),
              ),
              clock: _clock,
              deviceId: _deviceId,
              ids: _ids,
            ),
          );
        } else if (old.sortOrder != photo.sortOrder ||
            old.rotationDegrees != photo.rotationDegrees ||
            old.photoType != photo.photoType) {
          _expect(
            await upsertPhoto(
              _db,
              row: sqlite.PhotosCompanion(
                id: Value<String>(photo.id),
                sortOrder: Value<int>(photo.sortOrder),
                rotationDegrees: Value<int?>(photo.rotationDegrees),
                photoType: Value<String>(photo.photoType),
              ),
              clock: _clock,
              deviceId: _deviceId,
              ids: _ids,
            ),
          );
        }
      }

      // New audio is linked to the record and to its photos.
      final Set<String> heard = <String>{
        for (final AudioDraft clip in stored.audio) clip.id,
      };
      int audioIndex = stored.audio.length;
      for (final AudioDraft clip in edited.audio) {
        if (heard.contains(clip.id)) {
          continue;
        }
        await _fileAudio(clip, recordId: recordId, index: audioIndex, now: now);
        audioIndex++;
      }

      _expect(
        await upsertRecord(
          _db,
          row: sqlite.RecordsCompanion(id: Value<String>(recordId)),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
    });
  }

  /// The edit session for [recordId] as stored now, or null when the record
  /// is gone.
  Future<CaptureSession?> _read(String recordId) async {
    final sqlite.RecordRow? record = await (_db.select(
      _db.records,
    )..where((row) => row.id.equals(recordId))).getSingleOrNull();
    if (record == null || _gone.contains(record.status.toLowerCase())) {
      return null;
    }
    final List<sqlite.Photo> rows =
        await (_db.select(_db.photos)
              ..where((row) => row.recordId.equals(recordId))
              ..orderBy(<OrderClauseGenerator<sqlite.$PhotosTable>>[
                (row) => OrderingTerm.asc(row.sortOrder),
                (row) => OrderingTerm.desc(row.capturedAt),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    final Set<String> removed = await _tombstoned(
      _db.photos.actualTableName,
      <String>[for (final sqlite.Photo row in rows) row.id],
    );
    final List<sqlite.Photo> live = <sqlite.Photo>[
      for (final sqlite.Photo row in rows)
        if (!removed.contains(row.id)) row,
    ];
    final Map<String, String> captions = <String, String>{};
    final sqlite.Caption? recordCaption = await _latestCaption(
      CaptionOwnerType.record,
      recordId,
    );
    if (recordCaption != null) {
      captions[''] = recordCaption.textRefined ?? recordCaption.textRaw;
    }
    for (final sqlite.Photo row in live) {
      final sqlite.Caption? caption = await _latestCaption(
        CaptionOwnerType.photo,
        row.id,
      );
      if (caption != null) {
        captions[row.id] = caption.textRefined ?? caption.textRaw;
      }
    }
    final List<PhotoDraft> photos = <PhotoDraft>[
      for (final sqlite.Photo row in live)
        PhotoDraft(
          id: row.id,
          projectId: row.projectId,
          recordId: row.recordId,
          captureSessionId: row.captureSessionId,
          originalFilename: row.originalFilename,
          storedFilename: row.storedFilename,
          relativePath: row.relativePath,
          photoType: row.photoType,
          sortOrder: row.sortOrder,
          width: row.width,
          height: row.height,
          fileSize: row.fileSize,
          mimeType: row.mimeType,
          sha256: row.sha256,
          capturedAt: row.capturedAt,
          gpsLat: row.gpsLat,
          gpsLon: row.gpsLon,
          rotationDegrees: row.rotationDegrees ?? 0,
          hasCaption: (captions[row.id] ?? '').isNotEmpty,
          derivedFrom: row.derivedFrom,
        ),
    ];
    return CaptureSession(
      id: recordId,
      projectId: record.projectId,
      templateId: record.templateId,
      contextSnapshot: _context(record.contextJson),
      recordId: recordId,
      editing: true,
      photos: photos,
      audio: await _audio(recordId),
      captions: captions,
    );
  }

  Future<List<AudioDraft>> _audio(String recordId) async {
    final List<sqlite.AttachmentOwner> links =
        await (_db.select(_db.attachmentOwners)
              ..where(
                (row) =>
                    row.ownerType.equalsValue(AttachmentOwnerType.record) &
                    row.ownerId.equals(recordId),
              )
              ..orderBy(<OrderClauseGenerator<sqlite.$AttachmentOwnersTable>>[
                (row) => OrderingTerm.asc(row.sortOrder),
              ]))
            .get();
    final List<AudioDraft> clips = <AudioDraft>[];
    for (final sqlite.AttachmentOwner link in links) {
      final sqlite.Attachment? clip = await (_db.select(
        _db.attachments,
      )..where((row) => row.id.equals(link.attachmentId))).getSingleOrNull();
      if (clip == null || clip.kind != AttachmentKind.audio) {
        continue;
      }
      final List<sqlite.AttachmentOwner> photoLinks =
          await (_db.select(_db.attachmentOwners)
                ..where(
                  (row) =>
                      row.attachmentId.equals(clip.id) &
                      row.ownerType.equalsValue(AttachmentOwnerType.photo),
                )
                ..orderBy(<OrderClauseGenerator<sqlite.$AttachmentOwnersTable>>[
                  (row) => OrderingTerm.asc(row.sortOrder),
                ]))
              .get();
      clips.add(
        AudioDraft(
          id: clip.id,
          projectId: clip.projectId,
          relativePath: clip.relativePath,
          mimeType: clip.mimeType,
          fileSize: clip.fileSize,
          sha256: clip.sha256,
          durationMs: clip.durationMs ?? 0,
          photoIds: <String>[
            for (final sqlite.AttachmentOwner photo in photoLinks)
              photo.ownerId,
          ],
        ),
      );
    }
    return clips;
  }

  /// The newest live caption row for one owner.
  Future<sqlite.Caption?> _latestCaption(
    CaptionOwnerType type,
    String ownerId,
  ) async {
    final List<sqlite.Caption> rows =
        await (_db.select(_db.captions)
              ..where(
                (row) =>
                    row.ownerType.equalsValue(type) &
                    row.ownerId.equals(ownerId),
              )
              ..orderBy(<OrderClauseGenerator<sqlite.$CaptionsTable>>[
                (row) => OrderingTerm.desc(row.createdAt),
                (row) => OrderingTerm.desc(row.id),
              ]))
            .get();
    final Set<String> removed = await _tombstoned(
      _db.captions.actualTableName,
      <String>[for (final sqlite.Caption row in rows) row.id],
    );
    for (final sqlite.Caption row in rows) {
      if (!removed.contains(row.id)) {
        return row;
      }
    }
    return null;
  }

  Future<Set<String>> _tombstoned(String entityType, List<String> ids) async {
    if (ids.isEmpty) {
      return const <String>{};
    }
    final List<sqlite.Tombstone> rows =
        await (_db.select(_db.tombstones)..where(
              (row) =>
                  row.entityType.equals(entityType) & row.entityId.isIn(ids),
            ))
            .get();
    return <String>{for (final sqlite.Tombstone row in rows) row.entityId};
  }

  Future<void> _fileAudio(
    AudioDraft clip, {
    required String recordId,
    required int index,
    required DateTime now,
  }) async {
    _expect(
      await upsertAttachment(
        _db,
        row: sqlite.AttachmentsCompanion(
          id: Value<String>(clip.id),
          projectId: Value<String>(clip.projectId),
          relativePath: Value<String>(clip.relativePath),
          mimeType: Value<String>(clip.mimeType),
          fileSize: Value<int>(clip.fileSize),
          sha256: Value<String>(clip.sha256),
          kind: const Value<AttachmentKind>(AttachmentKind.audio),
          durationMs: Value<int?>(clip.durationMs),
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      ),
    );
    await _linkAttachment(
      attachmentId: clip.id,
      ownerType: AttachmentOwnerType.record,
      ownerId: recordId,
      sortOrder: index,
      now: now,
    );
    for (int photoIndex = 0; photoIndex < clip.photoIds.length; photoIndex++) {
      await _linkAttachment(
        attachmentId: clip.id,
        ownerType: AttachmentOwnerType.photo,
        ownerId: clip.photoIds[photoIndex],
        sortOrder: photoIndex,
        now: now,
      );
    }
  }

  Future<void> _linkAttachment({
    required String attachmentId,
    required AttachmentOwnerType ownerType,
    required String ownerId,
    required int sortOrder,
    required DateTime now,
  }) async {
    await _db
        .into(_db.attachmentOwners)
        .insertOnConflictUpdate(
          sqlite.AttachmentOwnersCompanion(
            id: Value<String>(_ids.newId()),
            attachmentId: Value<String>(attachmentId),
            ownerType: Value<AttachmentOwnerType>(ownerType),
            ownerId: Value<String>(ownerId),
            sortOrder: Value<int>(sortOrder),
            createdAt: Value<DateTime>(now),
            updatedAt: Value<DateTime>(now),
            updatedByDevice: Value<String>(_deviceId),
            rev: const Value<int>(1),
          ),
        );
  }
}

/// Statuses of a record that is no longer shown or edited.
const Set<String> _gone = <String>{'archived', 'deleted'};

const StorageFailure _recordGone = StorageFailure(
  message: 'That record is no longer on this device.',
  recoveryAction: 'Go back to the project and pick another record.',
);

Map<String, String> _context(String json) {
  try {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map) {
      return const <String, String>{};
    }
    return <String, String>{
      for (final MapEntry<Object?, Object?> entry in decoded.entries)
        if (entry.key is String && entry.value != null)
          entry.key! as String: entry.value is String
              ? entry.value! as String
              : jsonEncode(entry.value),
    };
  } on FormatException {
    return const <String, String>{};
  }
}

String? _raw(Object? value) {
  if (value == null) {
    return null;
  }
  return value is String ? value : jsonEncode(value);
}

void _expect<T>(Result<T> result) {
  switch (result) {
    case Success<T>():
      return;
    case FailureResult<T>(:final Failure failure):
      throw StorageFailure(
        message: failure.message,
        recoveryAction: failure.recoveryAction ?? 'Try again.',
      );
  }
}

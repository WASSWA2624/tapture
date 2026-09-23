// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/capture_session.dart';
import '../domain/photo_draft.dart';

/// The single transaction boundary that turns a capture session into a raw
/// record. Processing can add proposals later, but never rewrites these raw
/// values or the frozen context object.
final class CaptureRecordWriter {
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
  Future<Result<String>> persist(CaptureSession session) {
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

/// Production overrides this with [CaptureRecordWriter]. Tests can inject a
/// writer without opening Drift.
final Provider<CaptureRecordWriter?> captureRecordWriterProvider =
    Provider<CaptureRecordWriter?>((Ref _) => null);

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

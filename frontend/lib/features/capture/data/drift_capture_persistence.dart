// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/capture_sessions.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/owned_capture_persistence.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

/// Drift and project-tree backed capture persistence used by production.
final class DriftCapturePersistence implements OwnedCapturePersistence {
  /// Creates a durable capture store.
  DriftCapturePersistence({
    required sqlite.AppDatabase db,
    required CapturePhotoRepository photos,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) : _db = db,
       _photos = photos,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids;

  final sqlite.AppDatabase _db;
  final CapturePhotoRepository _photos;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  @override
  PhotoRepository get photos => _photos;

  @override
  Future<Result<PhotoDraft>> savePhoto(PhotoDraft photo, {Uint8List? bytes}) {
    return _photos.saveDraft(photo, bytes: bytes);
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) {
    return _photos.delete(photoId, reason: reason);
  }

  @override
  Future<Result<void>> saveSession(CaptureSession session) =>
      _saveSession(session);

  @override
  Future<Result<void>> saveOwnedSession(
    CaptureSession session, {
    required ({String sessionId, String templateId, int? templateVersion})
    owner,
  }) => _saveSession(session, owner: owner);

  Future<Result<void>> _saveSession(
    CaptureSession session, {
    ({String sessionId, String templateId, int? templateVersion})? owner,
  }) async {
    try {
      final String payload = jsonEncode(session.toJson());
      if (!isCaptureSessionJson(payload) || session.projectId.isEmpty) {
        return FailureResult<void>(
          ValidationFailure(
            localizedMessage: Copy.messages.failureTheCaptureSessionIsNotValid,
          ),
        );
      }
      // The project_id column holds the storage key: the project for a new
      // capture, `edit:<recordId>` for an edit (D6).
      final String key = session.storageKey;
      return await _db.transaction(() async {
        final sqlite.CaptureSession? existing =
            await (_db.select(_db.captureSessions)..where(
                  (sqlite.$CaptureSessionsTable row) =>
                      row.projectId.equals(key),
                ))
                .getSingleOrNull();
        if (owner != null) {
          final CaptureSession? current =
              existing != null && isCaptureSessionJson(existing.payloadJson)
              ? CaptureSession.fromJson(
                  Map<String, Object?>.from(
                    jsonDecode(existing.payloadJson) as Map,
                  ),
                )
              : null;
          if (current == null ||
              current.projectId != session.projectId ||
              current.storageKey != session.storageKey ||
              !_owns(current, owner) ||
              !_owns(session, owner)) {
            return FailureResult<void>(
              StorageFailure(
                localizedMessage: Copy.messages.captureChangeNotSaved,
                localizedRecovery: Copy.messages.captureChangeNotSavedRecovery,
              ),
            );
          }
        }
        final DateTime now = _clock.nowUtc();
        await _db
            .into(_db.captureSessions)
            .insertOnConflictUpdate(
              sqlite.CaptureSessionsCompanion(
                id: Value<String>(existing?.id ?? _ids.newId()),
                projectId: Value<String>(key),
                payloadJson: Value<String>(payload),
                createdAt: Value<DateTime>(existing?.createdAt ?? now),
                updatedAt: Value<DateTime>(now),
                updatedByDevice: Value<String>(_deviceId),
                rev: Value<int>((existing?.rev ?? 0) + 1),
              ),
            );
        return const Success<void>(null);
      });
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }

  bool _owns(
    CaptureSession session,
    ({String sessionId, String templateId, int? templateVersion}) owner,
  ) =>
      session.id == owner.sessionId &&
      session.templateId == owner.templateId &&
      session.templateVersion == owner.templateVersion;

  @override
  Future<Result<CaptureSession?>> loadSession(String key) async {
    try {
      final sqlite.CaptureSession? row =
          await (_db.select(_db.captureSessions)..where(
                (sqlite.$CaptureSessionsTable row) => row.projectId.equals(key),
              ))
              .getSingleOrNull();
      if (row == null || !isCaptureSessionJson(row.payloadJson)) {
        return const Success<CaptureSession?>(null);
      }
      return Success<CaptureSession?>(
        CaptureSession.fromJson(
          Map<String, Object?>.from(jsonDecode(row.payloadJson) as Map),
        ),
      );
    } on Object catch (error) {
      return FailureResult<CaptureSession?>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> clearSession(String key) async {
    try {
      await (_db.delete(_db.captureSessions)..where(
            (sqlite.$CaptureSessionsTable row) => row.projectId.equals(key),
          ))
          .go();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }
}

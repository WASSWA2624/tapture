// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/capture_sessions.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

/// Drift and project-tree backed capture persistence used by production.
final class DriftCapturePersistence implements CapturePersistence {
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
  Future<Result<void>> saveSession(CaptureSession session) async {
    try {
      final String payload = jsonEncode(session.toJson());
      if (!isCaptureSessionJson(payload) || session.projectId.isEmpty) {
        return const FailureResult<void>(
          ValidationFailure(message: 'The capture session is not valid.'),
        );
      }
      final sqlite.CaptureSession? existing =
          await (_db.select(_db.captureSessions)..where(
                (sqlite.$CaptureSessionsTable row) =>
                    row.projectId.equals(session.projectId),
              ))
              .getSingleOrNull();
      final DateTime now = _clock.nowUtc();
      await _db
          .into(_db.captureSessions)
          .insertOnConflictUpdate(
            sqlite.CaptureSessionsCompanion(
              id: Value<String>(existing?.id ?? _ids.newId()),
              projectId: Value<String>(session.projectId),
              payloadJson: Value<String>(payload),
              createdAt: Value<DateTime>(existing?.createdAt ?? now),
              updatedAt: Value<DateTime>(now),
              updatedByDevice: Value<String>(_deviceId),
              rev: Value<int>((existing?.rev ?? 0) + 1),
            ),
          );
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String projectId) async {
    try {
      final sqlite.CaptureSession? row =
          await (_db.select(_db.captureSessions)..where(
                (sqlite.$CaptureSessionsTable row) =>
                    row.projectId.equals(projectId),
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
  Future<Result<void>> clearSession(String projectId) async {
    try {
      await (_db.delete(_db.captureSessions)..where(
            (sqlite.$CaptureSessionsTable row) =>
                row.projectId.equals(projectId),
          ))
          .go();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }
}

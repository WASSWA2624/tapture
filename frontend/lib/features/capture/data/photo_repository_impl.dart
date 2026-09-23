// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide Uint8List;
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/capture_sessions.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

/// [CapturePersistence] over a [PhotoRepository] and session [TextStore].
final class CapturePersistenceImpl implements CapturePersistence {
  /// Creates persistence over [_photos] and a session [_store].
  CapturePersistenceImpl({required this._photos, required this._store});

  final PhotoRepository _photos;
  final TextStore _store;

  @override
  PhotoRepository get photos => _photos;

  @override
  Future<Result<PhotoDraft>> savePhoto(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    if (_photos case final CapturePhotoRepository complete) {
      return complete.saveDraft(photo, bytes: bytes);
    }
    final Result<PhotoAsset> saved = await _photos.save(photo.asAsset);
    return saved.fold(
      FailureResult<PhotoDraft>.new,
      (PhotoAsset asset) => Success<PhotoDraft>(
        photo.copyWith(
          id: asset.id,
          projectId: asset.projectId,
          recordId: asset.recordId,
          relativePath: asset.relativePath,
          sha256: asset.sha256,
        ),
      ),
    );
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) {
    return _photos.delete(photoId, reason: reason);
  }

  @override
  Future<Result<void>> saveSession(CaptureSession session) async {
    try {
      await _store.write(jsonEncode(session.toJson()));
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        StorageFailure(message: error.toString(), recoveryAction: 'Try again.'),
      );
    }
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String projectId) async {
    try {
      final String? raw = _store.read();
      if (raw == null || raw.isEmpty) {
        return const Success<CaptureSession?>(null);
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const Success<CaptureSession?>(null);
      }
      return Success<CaptureSession?>(
        CaptureSession.fromJson(Map<String, Object?>.from(decoded)),
      );
    } on Object catch (error) {
      return FailureResult<CaptureSession?>(
        StorageFailure(
          message: error.toString(),
          recoveryAction: 'Discard the interrupted session and start again.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> clearSession(String projectId) async {
    try {
      await _store.write('');
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        StorageFailure(message: error.toString(), recoveryAction: 'Try again.'),
      );
    }
  }
}

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

/// Complete Drift photo repository. Bytes are published atomically before the
/// row becomes visible, so the tray never announces evidence that lacks a
/// file.
final class DriftPhotoRepository implements CapturePhotoRepository {
  /// Creates the repository over one application database and storage root.
  DriftPhotoRepository({
    required sqlite.AppDatabase db,
    required FileWriter writer,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) : _db = db,
       _writer = writer,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids;

  final sqlite.AppDatabase _db;
  final FileWriter _writer;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  @override
  Stream<List<PhotoAsset>> watchByRecord(String recordId) {
    final query = _db.select(_db.photos)
      ..where((sqlite.$PhotosTable row) => row.recordId.equals(recordId))
      ..orderBy(<OrderClauseGenerator<sqlite.$PhotosTable>>[
        (sqlite.$PhotosTable row) => OrderingTerm.asc(row.sortOrder),
      ]);
    return query.watch().map(
      (List<sqlite.Photo> rows) => rows.map(_asset).toList(growable: false),
    );
  }

  @override
  Future<Result<PhotoAsset?>> byId(String id) async {
    try {
      final sqlite.Photo? row =
          await (_db.select(_db.photos)
                ..where((sqlite.$PhotosTable row) => row.id.equals(id)))
              .getSingleOrNull();
      return Success<PhotoAsset?>(row == null ? null : _asset(row));
    } on Object catch (error) {
      return FailureResult<PhotoAsset?>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<PhotoAsset>> save(PhotoAsset photo) async {
    final sqlite.Photo? existing =
        await (_db.select(_db.photos)
              ..where((sqlite.$PhotosTable row) => row.id.equals(photo.id)))
            .getSingleOrNull();
    if (existing == null) {
      return const FailureResult<PhotoAsset>(
        ValidationFailure(
          message: 'Complete photo metadata is required for a new capture.',
        ),
      );
    }
    final Result<sqlite.Photo> saved = await upsertPhoto(
      _db,
      row: sqlite.PhotosCompanion(
        id: Value<String>(photo.id),
        recordId: Value<String?>(photo.recordId),
        relativePath: Value<String>(photo.relativePath),
      ),
      clock: _clock,
      deviceId: _deviceId,
      ids: _ids,
    );
    return saved.map(_asset);
  }

  @override
  Future<Result<PhotoDraft>> saveDraft(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    try {
      PhotoDraft ready = photo;
      if (bytes != null) {
        final sqlite.Project? project =
            await (_db.select(_db.projects)..where(
                  (sqlite.$ProjectsTable row) => row.id.equals(photo.projectId),
                ))
                .getSingleOrNull();
        if (project == null) {
          return const FailureResult<PhotoDraft>(
            StorageFailure(message: 'The photo project was not found.'),
          );
        }
        final Result<WrittenFile> file = await _writer.write(
          Stream<List<int>>.value(bytes),
          'projects/${project.folderName}/${photo.relativePath}',
        );
        switch (file) {
          case FailureResult<WrittenFile>(:final Failure failure):
            return FailureResult<PhotoDraft>(failure);
          case Success<WrittenFile>(:final WrittenFile value):
            ready = photo.copyWith(
              storedFilename: photo.storedFilename.isEmpty
                  ? photo.relativePath.split('/').last
                  : photo.storedFilename,
              sha256: value.sha256,
              fileSize: value.byteLength,
            );
        }
      }
      final DateTime captured = ready.capturedAt ?? _clock.nowUtc();
      final Result<sqlite.Photo> saved = await upsertPhoto(
        _db,
        row: sqlite.PhotosCompanion(
          id: Value<String>(ready.id),
          projectId: Value<String>(ready.projectId),
          recordId: Value<String?>(ready.recordId),
          captureSessionId: Value<String>(ready.captureSessionId),
          originalFilename: Value<String>(ready.originalFilename),
          storedFilename: Value<String>(
            ready.storedFilename.isEmpty
                ? ready.relativePath.split('/').last
                : ready.storedFilename,
          ),
          relativePath: Value<String>(ready.relativePath),
          photoType: Value<String>(ready.photoType),
          sortOrder: Value<int>(ready.sortOrder),
          width: Value<int>(ready.width),
          height: Value<int>(ready.height),
          fileSize: Value<int>(ready.fileSize),
          mimeType: Value<String>(ready.mimeType),
          sha256: Value<String>(ready.sha256),
          capturedAt: Value<DateTime>(captured),
          gpsLat: Value<double?>(ready.gpsLat),
          gpsLon: Value<double?>(ready.gpsLon),
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      );
      return saved.map((sqlite.Photo row) => _draft(row, ready));
    } on Object catch (error) {
      return FailureResult<PhotoDraft>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    try {
      final DateTime now = _clock.nowUtc();
      await _db
          .into(_db.tombstones)
          .insertOnConflictUpdate(
            sqlite.TombstonesCompanion(
              id: Value<String>(_ids.newId()),
              entityType: const Value<String>('photos'),
              entityId: Value<String>(id),
              deletedAt: Value<DateTime>(now),
              deletedByDevice: Value<String>(_deviceId),
              reason: Value<String>(reason),
              createdAt: Value<DateTime>(now),
              updatedAt: Value<DateTime>(now),
              updatedByDevice: Value<String>(_deviceId),
              rev: const Value<int>(1),
            ),
          );
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }
}

PhotoAsset _asset(sqlite.Photo row) => (
  id: row.id,
  projectId: row.projectId,
  recordId: row.recordId,
  relativePath: row.relativePath,
  sha256: row.sha256,
);

PhotoDraft _draft(sqlite.Photo row, PhotoDraft presentation) {
  return PhotoDraft(
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
    rotationDegrees: presentation.rotationDegrees,
    processingState: presentation.processingState,
    hasCaption: presentation.hasCaption,
    supersededBy: presentation.supersededBy,
    derivedFrom: presentation.derivedFrom,
  );
}

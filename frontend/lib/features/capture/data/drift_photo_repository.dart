// ignore_for_file: prefer_initializing_formals

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide Uint8List;
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/thumbnail_cache.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

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
    StorageRoot? storageRoot,
    Future<List<int>> Function(
      String sourcePath, {
      required int longEdge,
      required int quality,
    })?
    decodeThumbnail,
  }) : _db = db,
       _writer = writer,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _storageRoot = storageRoot,
       _thumbs = storageRoot == null
           ? null
           : ThumbnailCache(storageRoot: storageRoot, decode: decodeThumbnail);

  final sqlite.AppDatabase _db;
  final FileWriter _writer;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final StorageRoot? _storageRoot;
  final ThumbnailCache? _thumbs;

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
          derivedFrom: Value<String?>(ready.derivedFrom),
          rotationDegrees: Value<int?>(ready.rotationDegrees),
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
  Future<Result<Uint8List>> readBytes(PhotoDraft photo) async {
    try {
      final Result<File> file = await _sourceFile(photo);
      switch (file) {
        case FailureResult<File>(:final Failure failure):
          return FailureResult<Uint8List>(failure);
        case Success<File>(:final File value):
          if (!value.existsSync()) {
            return const FailureResult<Uint8List>(
              StorageFailure(
                message: 'That photo could not be read from this device.',
                recoveryAction: 'Capture the photo again, then try again.',
              ),
            );
          }
          return Success<Uint8List>(await value.readAsBytes());
      }
    } on Object catch (error) {
      return FailureResult<Uint8List>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<String>> cachedThumbnailPath(
    PhotoDraft photo, {
    required int edge,
  }) async {
    final ThumbnailCache? thumbs = _thumbs;
    if (thumbs == null) {
      return const FailureResult<String>(
        StorageFailure(
          message: 'That photo could not be read from this device.',
          recoveryAction: 'Capture the photo again, then try again.',
        ),
      );
    }
    final Result<File> source = await _sourceFile(photo);
    switch (source) {
      case FailureResult<File>(:final Failure failure):
        return FailureResult<String>(failure);
      case Success<File>(:final File value):
        if (!value.existsSync()) {
          return const FailureResult<String>(
            StorageFailure(
              message: 'That photo could not be read from this device.',
              recoveryAction: 'Capture the photo again, then try again.',
            ),
          );
        }
        final Result<File> thumb = await thumbs.thumbnail(
          photo.sha256,
          value.path,
          edge: edge,
        );
        return thumb.map((File file) => file.path);
    }
  }

  @override
  Future<Result<void>> retireDerived(String id) async {
    try {
      final sqlite.Photo? row =
          await (_db.select(_db.photos)
                ..where((sqlite.$PhotosTable table) => table.id.equals(id)))
              .getSingleOrNull();
      if (row == null) {
        return const Success<void>(null);
      }
      if (row.derivedFrom == null) {
        return const FailureResult<void>(
          ValidationFailure(
            message: 'The original photo stays in place.',
            recoveryAction: 'Revert an edited photo instead.',
          ),
        );
      }
      await (_db.delete(
        _db.photos,
      )..where((sqlite.$PhotosTable table) => table.id.equals(id))).go();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }

  Future<Result<File>> _sourceFile(PhotoDraft photo) async {
    final StorageRoot? storageRoot = _storageRoot;
    if (storageRoot == null) {
      return const FailureResult<File>(
        StorageFailure(
          message: 'That photo could not be read from this device.',
          recoveryAction: 'Capture the photo again, then try again.',
        ),
      );
    }
    final sqlite.Project? project =
        await (_db.select(_db.projects)..where(
              (sqlite.$ProjectsTable row) => row.id.equals(photo.projectId),
            ))
            .getSingleOrNull();
    if (project == null) {
      return const FailureResult<File>(
        StorageFailure(message: 'The photo project was not found.'),
      );
    }
    final Result<Directory> root = await storageRoot.resolve();
    switch (root) {
      case FailureResult<Directory>(:final Failure failure):
        return FailureResult<File>(failure);
      case Success<Directory>(:final Directory value):
        return Success<File>(
          File(
            '${value.path}/projects/${project.folderName}/${photo.relativePath}',
          ),
        );
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
    rotationDegrees: row.rotationDegrees ?? 0,
    processingState: presentation.processingState,
    hasCaption: presentation.hasCaption,
    supersededBy: presentation.supersededBy,
    derivedFrom: row.derivedFrom,
  );
}

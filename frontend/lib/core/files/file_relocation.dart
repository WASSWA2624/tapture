import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_path_builder.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// Moves a record's files when its context folder changes, in the same
/// transaction as the stored paths.
abstract interface class FileRelocation {
  /// Resolves project folders through [storageRoot]. Tests pass
  /// [StorageRoot.fake] and the move / transaction seams.
  factory FileRelocation({
    required AppDatabase db,
    required StorageRoot storageRoot,
    Clock? clock,
    String? deviceId,
    IdService? ids,
    Future<void> Function(File from, File to)? move,
    void Function()? failTransaction,
  }) {
    return _FileRelocation(
      db: db,
      storageRoot: storageRoot,
      clock: clock ?? const SystemClock(),
      deviceId: deviceId ?? 'local',
      ids: ids ?? UuidV7Service(const SystemClock()),
      move: move,
      failTransaction: failTransaction,
    );
  }

  /// Moves every file of [recordId] into the folder its snapshot now names.
  /// Returns how many files moved.
  Future<Result<int>> relocateRecord(String recordId);
}

final class _FileRelocation implements FileRelocation {
  _FileRelocation({
    required this._db,
    required this._storageRoot,
    required this._clock,
    required this._deviceId,
    required this._ids,
    required this._move,
    required this._failTransaction,
  });

  final AppDatabase _db;
  final StorageRoot _storageRoot;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final Future<void> Function(File from, File to)? _move;
  final void Function()? _failTransaction;

  @override
  Future<Result<int>> relocateRecord(String recordId) async {
    final List<_PlannedMove> planned = <_PlannedMove>[];
    try {
      final RecordRow? record =
          await (_db.select(_db.records)
                ..where(($RecordsTable tbl) => tbl.id.equals(recordId)))
              .getSingleOrNull();
      if (record == null) {
        return const FailureResult<int>(
          StorageFailure(
            message: 'That record is no longer on this device.',
            recoveryAction: 'Refresh the list and try again.',
          ),
        );
      }
      final Project? project =
          await (_db.select(
                _db.projects,
              )..where(($ProjectsTable tbl) => tbl.id.equals(record.projectId)))
              .getSingleOrNull();
      if (project == null) {
        return const FailureResult<int>(
          StorageFailure(
            message: 'That project is no longer on this device.',
            recoveryAction: 'Open a project, then try again.',
          ),
        );
      }
      final Result<Directory> folder = await ProjectFolders(
        storageRoot: _storageRoot,
      ).resolve(project);
      switch (folder) {
        case FailureResult<Directory>(:final failure):
          return FailureResult<int>(failure);
        case Success<Directory>(:final value):
          planned.addAll(await _plan(record, project, value));
          for (final _PlannedMove move in planned) {
            if (move.movesFile) {
              await _rename(move.from, move.to);
            }
          }
          final Result<int> written = await runInTransaction(_db, () async {
            await _writePaths(planned);
            _failTransaction?.call();
            return planned.length;
          });
          switch (written) {
            case FailureResult<int>(:final failure):
              await _undo(planned);
              return FailureResult<int>(failure);
            case Success<int>(:final value):
              return Success<int>(value);
          }
      }
    } on Failure catch (failure) {
      await _undo(planned);
      return FailureResult<int>(failure);
    } on Object catch (error) {
      await _undo(planned);
      return FailureResult<int>(storageFailureFrom(error));
    }
  }

  Future<List<_PlannedMove>> _plan(
    RecordRow record,
    Project project,
    Directory projectDir,
  ) async {
    final PhotoFolderStrategy strategy = _strategyOf(project);
    final List<String> contextValues = await _contextValues(
      record.projectId,
      record.contextJson,
    );
    final Template? template =
        await (_db.select(
              _db.templates,
            )..where(($TemplatesTable tbl) => tbl.id.equals(record.templateId)))
            .getSingleOrNull();
    final List<Photo> photos = await (_db.select(
      _db.photos,
    )..where(($PhotosTable tbl) => tbl.recordId.equals(record.id))).get();
    final List<Attachment> attachments =
        await (_db.select(_db.attachments)..where(
              ($AttachmentsTable tbl) => tbl.projectId.equals(project.id),
            ))
            .get();
    final List<_PlannedMove> planned = <_PlannedMove>[];
    for (final Photo photo in photos) {
      final String folder = buildPhotoPath(
        strategy: strategy,
        contextValues: contextValues,
        capturedAt: photo.capturedAt,
        templateName: template?.name,
      );
      final String next = '$folder/${photo.storedFilename}';
      if (next == photo.relativePath.replaceAll(r'\', '/')) {
        continue;
      }
      planned.add(
        _PlannedMove.photo(
          photo: photo,
          from: File('${projectDir.path}/${photo.relativePath}'),
          to: File('${projectDir.path}/$next'),
          nextPath: next,
        ),
      );
    }
    final Map<String, String> photoMoves = <String, String>{
      for (final _PlannedMove move in planned)
        if (move.photo != null) move.photo!.relativePath: move.nextPath,
    };
    for (final Attachment attachment in attachments) {
      final String? next = photoMoves[attachment.relativePath];
      if (next == null) {
        continue;
      }
      planned.add(
        _PlannedMove.attachment(
          attachment: attachment,
          from: File('${projectDir.path}/${attachment.relativePath}'),
          to: File('${projectDir.path}/$next'),
          nextPath: next,
        ),
      );
    }
    return planned;
  }

  Future<void> _writePaths(List<_PlannedMove> planned) async {
    for (final _PlannedMove move in planned) {
      final Photo? photo = move.photo;
      if (photo != null) {
        final Result<Photo> written = await upsertPhoto(
          _db,
          row: PhotosCompanion(
            id: Value<String>(photo.id),
            relativePath: Value<String>(move.nextPath),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        );
        if (written is FailureResult<Photo>) {
          throw written.failure;
        }
      }
      final Attachment? attachment = move.attachment;
      if (attachment != null) {
        final Result<Attachment> written = await upsertAttachment(
          _db,
          row: AttachmentsCompanion(
            id: Value<String>(attachment.id),
            relativePath: Value<String>(move.nextPath),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        );
        if (written is FailureResult<Attachment>) {
          throw written.failure;
        }
      }
    }
  }

  Future<void> _rename(File from, File to) async {
    if (!from.existsSync()) {
      throw StorageFailure(
        message: 'Tapture could not find ${from.path}.',
        recoveryAction: 'Recreate the project folder, then try again.',
      );
    }
    if (_move != null) {
      await _move(from, to);
      return;
    }
    await to.parent.create(recursive: true);
    await from.rename(to.path);
  }

  Future<void> _undo(List<_PlannedMove> planned) async {
    for (final _PlannedMove move in planned.reversed) {
      if (!move.movesFile || !move.to.existsSync() || move.from.existsSync()) {
        continue;
      }
      try {
        await move.to.rename(move.from.path);
      } on Object {
        // The failure already reports that files and rows must be reconciled.
      }
    }
  }

  Future<List<String>> _contextValues(String projectId, String json) async {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map) {
      return const <String>[];
    }
    final Map<Object?, Object?> map = decoded;
    final levels =
        await (_db.select(_db.context)
              ..where(($ContextTable tbl) => tbl.projectId.equals(projectId))
              ..orderBy(<OrderClauseGenerator<$ContextTable>>[
                ($ContextTable tbl) => OrderingTerm.asc(tbl.level),
              ]))
            .get();
    if (levels.isEmpty) {
      return <String>[for (final Object? value in map.values) '$value'];
    }
    return <String>[for (final level in levels) '${map[level.fieldKey] ?? ''}'];
  }
}

PhotoFolderStrategy _strategyOf(Project project) {
  try {
    final Object? decoded = jsonDecode(project.settings);
    if (decoded is Map) {
      final Object? name =
          decoded['photoFolderStrategy'] ?? decoded['folderStrategy'];
      if (name is String) {
        return switch (name) {
          'byTemplate' => PhotoFolderStrategy.byTemplate,
          'byCaptureDate' => PhotoFolderStrategy.byCaptureDate,
          'flat' => PhotoFolderStrategy.flat,
          _ => PhotoFolderStrategy.byContext,
        };
      }
    }
  } on Object {
    // Missing or malformed settings fall back to the default strategy.
  }
  return PhotoPathBuilder.defaultStrategy;
}

final class _PlannedMove {
  _PlannedMove.photo({
    required Photo this.photo,
    required this.from,
    required this.to,
    required this.nextPath,
  }) : attachment = null,
       movesFile = true;

  _PlannedMove.attachment({
    required Attachment this.attachment,
    required this.from,
    required this.to,
    required this.nextPath,
  }) : photo = null,
       movesFile = false;

  final Photo? photo;
  final Attachment? attachment;
  final File from;
  final File to;
  final String nextPath;
  final bool movesFile;
}

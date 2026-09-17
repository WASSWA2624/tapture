import 'dart:io';

import 'package:drift/drift.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/hash/hashing_service.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

part 'missing_file.dart';
part 'orphan_file.dart';
part 'orphan_report.dart';

/// Scans one project's folder tree against its photo and attachment rows.
///
/// The scan never deletes or moves a file. Adoption and the evidence-missing
/// flag are separate, confirmed choices (rule 1 of the standard).
abstract interface class OrphanScanner {
  /// Walks under [storageRoot] and reads rows from [db]. Tests pass
  /// [StorageRoot.fake] and an in-memory database.
  factory OrphanScanner({
    required AppDatabase db,
    required StorageRoot storageRoot,
    Clock? clock,
    String? deviceId,
    IdService? ids,
  }) {
    return _OrphanScanner(
      db: db,
      storageRoot: storageRoot,
      clock: clock ?? const SystemClock(),
      deviceId: deviceId ?? 'local',
      ids: ids ?? UuidV7Service(const SystemClock()),
    );
  }

  /// Files with no row and rows with no file, with progress. [cancel]
  /// returns [CancelledFailure] and no report.
  Future<Result<OrphanReport>> scan(
    String projectId, {
    void Function(double)? onProgress,
    CancellationToken? cancel,
  });

  /// Inserts a normal media row for [file] on [recordId], with hash and
  /// merge columns. The file stays where it is.
  Future<Result<void>> adopt(OrphanFile file, {required String recordId});

  /// Records an evidence-missing flag for [row] without deleting the row
  /// or any remaining evidence.
  Future<Result<void>> flagMissing(MissingFile row);
}

final class _OrphanScanner implements OrphanScanner {
  _OrphanScanner({
    required this._db,
    required this._storageRoot,
    required this._clock,
    required this._deviceId,
    required this._ids,
  });

  final AppDatabase _db;
  final StorageRoot _storageRoot;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  @override
  Future<Result<OrphanReport>> scan(
    String projectId, {
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) async {
    try {
      if (cancel?.isCancelled ?? false) {
        return const FailureResult<OrphanReport>(CancelledFailure());
      }
      if (projectId.isEmpty) {
        return const FailureResult<OrphanReport>(
          ValidationFailure(
            message: 'That project could not be scanned.',
            recoveryAction: 'Open the project and try again.',
          ),
        );
      }
      final Project? project =
          await (_db.select(_db.projects)
                ..where(($ProjectsTable tbl) => tbl.id.equals(projectId)))
              .getSingleOrNull();
      if (project == null) {
        return const FailureResult<OrphanReport>(
          StorageFailure(
            message: 'That project is no longer on this device.',
            recoveryAction: 'Refresh the list and try again.',
          ),
        );
      }
      final Result<Directory> folder = await ProjectFolders(
        storageRoot: _storageRoot,
      ).resolve(project);
      switch (folder) {
        case FailureResult<Directory>(:final failure):
          return FailureResult<OrphanReport>(failure);
        case Success<Directory>(:final value):
          final List<_RowFile> rows = await _loadRows(projectId);
          final Result<Map<String, Object>> walked = await runIsolate(
            _scanTree,
            <Object>[
              value.path,
              AppConstants.lists.pageSize,
              for (final _RowFile row in rows) row.relativePath,
            ],
            onProgress: onProgress,
            cancel: cancel,
          );
          switch (walked) {
            case FailureResult<Map<String, Object>>(:final failure):
              return FailureResult<OrphanReport>(failure);
            case Success<Map<String, Object>>(
              value: final Map<String, Object> found,
            ):
              return Success<OrphanReport>(
                await _report(rows: rows, walked: found, projectDir: value),
              );
          }
      }
    } on Failure catch (failure) {
      return FailureResult<OrphanReport>(failure);
    } on Object {
      return const FailureResult<OrphanReport>(
        StorageFailure(
          message: 'The project folder could not be scanned on this device.',
          recoveryAction: 'Free space or allow storage access, then try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> adopt(
    OrphanFile file, {
    required String recordId,
  }) async {
    try {
      final String relative = _safeRelative(file.path);
      final RecordRow? record =
          await (_db.select(_db.records)
                ..where(($RecordsTable tbl) => tbl.id.equals(recordId)))
              .getSingleOrNull();
      if (record == null) {
        return const FailureResult<void>(
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
        return const FailureResult<void>(
          StorageFailure(
            message: 'That project is no longer on this device.',
            recoveryAction: 'Refresh the list and try again.',
          ),
        );
      }
      final Result<Directory> folder = await ProjectFolders(
        storageRoot: _storageRoot,
      ).resolve(project);
      switch (folder) {
        case FailureResult<Directory>(:final failure):
          return FailureResult<void>(failure);
        case Success<Directory>(:final value):
          final File onDisk = File('${value.path}/$relative');
          if (!onDisk.existsSync()) {
            return FailureResult<void>(
              StorageFailure(
                message: 'Tapture could not find $relative.',
                recoveryAction:
                    'Put the file back in the project folder, then try again.',
              ),
            );
          }
          final Result<String> hashed = await sha256OfFile(onDisk);
          switch (hashed) {
            case FailureResult<String>(:final failure):
              return FailureResult<void>(failure);
            case Success<String>(value: final String digest):
              return _insertMedia(
                file: file,
                relative: relative,
                record: record,
                sha256: digest,
                byteLength: onDisk.lengthSync(),
              );
          }
      }
    } on Failure catch (failure) {
      return FailureResult<void>(failure);
    } on Object {
      return const FailureResult<void>(
        StorageFailure(
          message: 'The file could not be adopted on this device.',
          recoveryAction: 'Free space or allow storage access, then try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> flagMissing(MissingFile row) async {
    try {
      if (row.entityType == _photos) {
        final Photo? photo =
            await (_db.select(_db.photos)
                  ..where(($PhotosTable tbl) => tbl.id.equals(row.id)))
                .getSingleOrNull();
        if (photo == null) {
          return const FailureResult<void>(_missingRow);
        }
      } else if (row.entityType == _attachments) {
        final Attachment? attachment =
            await (_db.select(_db.attachments)
                  ..where(($AttachmentsTable tbl) => tbl.id.equals(row.id)))
                .getSingleOrNull();
        if (attachment == null) {
          return const FailureResult<void>(_missingRow);
        }
      } else {
        return const FailureResult<void>(_missingRow);
      }
      await appendAudit(
        _db,
        entityType: row.entityType,
        entityId: row.id,
        action: AuditAction.updated,
        fieldKey: _evidenceMissing,
        previousValue: 'false',
        newValue: 'true',
        reason: 'The file is missing from disk.',
        clock: _clock,
        device: _deviceId,
      );
      return const Success<void>(null);
    } on Failure catch (failure) {
      return FailureResult<void>(failure);
    } on Object {
      return const FailureResult<void>(
        StorageFailure(
          message: 'The missing file could not be flagged on this device.',
          recoveryAction: 'Refresh the list and try again.',
        ),
      );
    }
  }

  Future<Result<void>> _insertMedia({
    required OrphanFile file,
    required String relative,
    required RecordRow record,
    required String sha256,
    required int byteLength,
  }) async {
    final String name = relative.split('/').last;
    if (file.kind == _kindDocument || file.kind == _kindAudio) {
      final Result<Attachment> written = await upsertAttachment(
        _db,
        row: AttachmentsCompanion(
          projectId: Value<String>(record.projectId),
          relativePath: Value<String>(relative),
          mimeType: Value<String>(_mime(relative)),
          fileSize: Value<int>(byteLength),
          sha256: Value<String>(sha256),
          kind: Value<AttachmentKind>(
            file.kind == _kindAudio
                ? AttachmentKind.audio
                : AttachmentKind.document,
          ),
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      );
      return _voidOf(written);
    }
    final Result<Photo> written = await upsertPhoto(
      _db,
      row: PhotosCompanion(
        projectId: Value<String>(record.projectId),
        recordId: Value<String?>(record.id),
        captureSessionId: const Value<String>(_adoptedSession),
        originalFilename: Value<String>(name),
        storedFilename: Value<String>(name),
        relativePath: Value<String>(relative),
        photoType: const Value<String>(_adoptedType),
        sortOrder: const Value<int>(_firstSort),
        width: const Value<int>(_unknownPx),
        height: const Value<int>(_unknownPx),
        fileSize: Value<int>(byteLength),
        mimeType: Value<String>(_mime(relative)),
        sha256: Value<String>(sha256),
        capturedAt: Value<DateTime>(_clock.nowUtc()),
      ),
      clock: _clock,
      deviceId: _deviceId,
      ids: _ids,
    );
    return _voidOf(written);
  }

  Future<OrphanReport> _report({
    required List<_RowFile> rows,
    required Map<String, Object> walked,
    required Directory projectDir,
  }) async {
    final List<OrphanFile> orphans = _orphansOf(walked);
    final Set<String> missingPaths = _missingOf(walked);
    await _hashAmbiguous(
      projectDir: projectDir,
      orphans: orphans,
      rows: rows,
      missingPaths: missingPaths,
    );
    final List<MissingFile> missing = <MissingFile>[
      for (final _RowFile row in rows)
        if (missingPaths.contains(row.relativePath))
          MissingFile(
            entityType: row.entityType,
            id: row.id,
            expectedPath: row.relativePath,
          ),
    ];
    var reclaimable = 0;
    for (final OrphanFile file in orphans) {
      reclaimable += file.bytes;
    }
    return OrphanReport(
      filesWithoutRows: orphans,
      rowsWithoutFiles: missing,
      reclaimableBytes: reclaimable,
    );
  }

  Future<List<_RowFile>> _loadRows(String projectId) async {
    return <_RowFile>[
      ...await _pageRows(projectId: projectId, table: _photos),
      ...await _pageRows(projectId: projectId, table: _attachments),
    ];
  }

  Future<List<_RowFile>> _pageRows({
    required String projectId,
    required String table,
  }) async {
    final List<_RowFile> rows = <_RowFile>[];
    var after = '';
    while (true) {
      final List<QueryRow> page = await _db
          .customSelect(
            'SELECT id, relative_path AS path, sha256 FROM $table '
            'WHERE project_id = ? AND id > ? ORDER BY id LIMIT ?',
            variables: <Variable<Object>>[
              Variable<String>(projectId),
              Variable<String>(after),
              Variable<int>(AppConstants.lists.pageSize),
            ],
          )
          .get();
      if (page.isEmpty) {
        break;
      }
      for (final QueryRow row in page) {
        final String id = row.read<String>('id');
        after = id;
        rows.add(
          _RowFile(
            entityType: table,
            id: id,
            relativePath: _slash(row.read<String>('path')),
            sha256: row.read<String>('sha256'),
          ),
        );
      }
    }
    return rows;
  }
}

Future<void> _hashAmbiguous({
  required Directory projectDir,
  required List<OrphanFile> orphans,
  required List<_RowFile> rows,
  required Set<String> missingPaths,
}) async {
  final Set<String> missingNames = <String>{
    for (final _RowFile row in rows)
      if (missingPaths.contains(row.relativePath)) _basename(row.relativePath),
  };
  for (final OrphanFile file in orphans) {
    if (!missingNames.contains(_basename(file.path))) {
      continue;
    }
    final Result<String> hashed = await sha256OfFile(
      File('${projectDir.path}/${file.path}'),
    );
    switch (hashed) {
      case FailureResult<String>():
        break;
      case Success<String>(value: final String value):
        for (final _RowFile row in rows) {
          if (row.sha256 == value) {
            break;
          }
        }
    }
  }
}

List<OrphanFile> _orphansOf(Map<String, Object> walked) {
  final Object? raw = walked['orphans'];
  if (raw is! Iterable<Object?>) {
    return const <OrphanFile>[];
  }
  final List<OrphanFile> files = <OrphanFile>[];
  for (final Object? entry in raw) {
    if (entry is! Iterable<Object?>) {
      continue;
    }
    final List<Object?> items = List<Object?>.of(entry);
    if (items.length < 3) {
      continue;
    }
    final Object? path = items[0];
    final Object? bytes = items[1];
    final Object? kind = items[2];
    if (path is! String || bytes is! int || kind is! String) {
      continue;
    }
    files.add(OrphanFile(path: path, bytes: bytes, kind: kind));
  }
  return files;
}

Set<String> _missingOf(Map<String, Object> walked) {
  final Object? raw = walked['missing'];
  if (raw is! Iterable<Object?>) {
    return const <String>{};
  }
  return <String>{
    for (final Object? path in raw)
      if (path is String) path,
  };
}

/// Walks [job] (project path, batch size, known relative paths) off the UI
/// thread. Skips `.cache` and `.part`.
Map<String, Object> _scanTree(List<Object> job) {
  final String projectPath = job[0] as String;
  final int batchSize = job[1] as int;
  final Set<String> known = <String>{
    for (final Object path in job.skip(2)) _slash(path as String),
  };
  IsolateRunner.reportProgress(0);
  final Directory root = Directory(projectPath);
  final List<List<Object>> orphans = <List<Object>>[];
  final Set<String> onDisk = <String>{};
  if (!root.existsSync()) {
    IsolateRunner.reportProgress(1);
    return <String, Object>{
      'orphans': <Object>[],
      'missing': <String>[...known],
    };
  }
  final String rootPath = _slash(root.absolute.path);
  var seen = 0;
  for (final FileSystemEntity entity in root.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }
    final String absolute = _slash(entity.absolute.path);
    if (!_isInside(rootPath, absolute)) {
      continue;
    }
    final String relative = absolute.substring(rootPath.length + 1);
    if (_skip(relative)) {
      continue;
    }
    onDisk.add(relative);
    if (!known.contains(relative)) {
      orphans.add(<Object>[relative, entity.lengthSync(), _kindOf(relative)]);
    }
    seen += 1;
    if (seen % batchSize == 0) {
      IsolateRunner.reportProgress(0.9);
    }
  }
  IsolateRunner.reportProgress(1);
  return <String, Object>{
    'orphans': <Object>[...orphans],
    'missing': <String>[
      for (final String path in known)
        if (!onDisk.contains(path)) path,
    ],
  };
}

bool _skip(String relative) {
  if (relative.endsWith(_partSuffix)) {
    return true;
  }
  for (final String part in relative.split('/')) {
    if (part == _cacheName) {
      return true;
    }
  }
  return false;
}

String _kindOf(String relative) {
  if (relative.startsWith('$_photos/')) {
    return _kindPhoto;
  }
  if (relative.startsWith('$_documents/')) {
    return _kindDocument;
  }
  if (relative.startsWith('$_audio/')) {
    return _kindAudio;
  }
  return _kindOther;
}

String _safeRelative(String relativePath) {
  final String relative = _slash(relativePath).trim();
  if (relative.isEmpty ||
      relative.startsWith('/') ||
      _drive.hasMatch(relative)) {
    throw const ValidationFailure(
      message: 'The file path must stay inside the project folder.',
      recoveryAction: 'Save the file under the project folder and try again.',
    );
  }
  for (final String part in relative.split('/')) {
    if (part.isEmpty || part == '.' || part == '..' || part == _cacheName) {
      throw const ValidationFailure(
        message: 'The file path must stay inside the project folder.',
        recoveryAction: 'Save the file under the project folder and try again.',
      );
    }
  }
  return relative;
}

String _mime(String path) {
  final String lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.pdf')) {
    return 'application/pdf';
  }
  if (lower.endsWith('.m4a') || lower.endsWith('.wav')) {
    return 'audio/mp4';
  }
  return 'application/octet-stream';
}

bool _isInside(String root, String path) {
  return path == root || path.startsWith('$root/');
}

String _slash(String path) => path.replaceAll(r'\', '/');

String _basename(String path) {
  final int slash = path.lastIndexOf('/');
  return slash == -1 ? path : path.substring(slash + 1);
}

final class _RowFile {
  const _RowFile({
    required this.entityType,
    required this.id,
    required this.relativePath,
    required this.sha256,
  });

  final String entityType;
  final String id;
  final String relativePath;
  final String sha256;
}

const StorageFailure _missingRow = StorageFailure(
  message: 'That file row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

final RegExp _drive = RegExp(r'^[A-Za-z]:');

const String _photos = 'photos';
const String _attachments = 'attachments';
const String _documents = 'documents';
const String _audio = 'audio';
const String _cacheName = '.cache';
const String _partSuffix = '.part';
const String _kindPhoto = 'photo';
const String _kindDocument = 'document';
const String _kindAudio = 'audio';
const String _kindOther = 'other';
const String _adoptedSession = 'adopted';
const String _adoptedType = 'front';
const String _evidenceMissing = 'evidenceMissing';
const int _firstSort = 0;
const int _unknownPx = 0;

Result<void> _voidOf<T>(Result<T> result) {
  return switch (result) {
    FailureResult<T>(:final Failure failure) => FailureResult<void>(failure),
    Success<T>() => const Success<void>(null),
  };
}

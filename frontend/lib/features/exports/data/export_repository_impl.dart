import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/tables/exports.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/xlsx_book.dart';
import 'package:tapture/core/export/xlsx_cell.dart';
import 'package:tapture/core/export/xlsx_column.dart';
import 'package:tapture/core/export/xlsx_encoder.dart';
import 'package:tapture/core/export/xlsx_sheet.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/exports/domain/export_file_name.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';

/// Device [ExportRepository]. A workbook is a new file under the project's
/// `exports/` folder; the row is inserted only after that file exists.
final class ExportRepositoryImpl implements ExportRepository {
  /// Creates the repository over the local database and storage root.
  ExportRepositoryImpl({
    required sqlite.AppDatabase db,
    required StorageRoot storageRoot,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    FileWriter? writer,
  }) : _db = db,
       _storageRoot = storageRoot,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _writer = writer ?? FileWriter(storageRoot: storageRoot),
       _dao = _ExportDao(db, clock: clock, deviceId: deviceId, ids: ids);

  final sqlite.AppDatabase _db;
  final StorageRoot _storageRoot;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final FileWriter _writer;
  final _ExportDao _dao;

  @override
  Stream<List<ExportEntry>> watchByProject(String projectId) {
    return (_db.select(_db.exports)
          ..where((sqlite.$ExportsTable row) => row.projectId.equals(projectId))
          ..orderBy(<OrderClauseGenerator<sqlite.$ExportsTable>>[
            (sqlite.$ExportsTable row) => OrderingTerm.desc(row.createdAt),
          ]))
        .watch()
        .map(
          (List<sqlite.ExportRow> rows) => <ExportEntry>[
            for (final sqlite.ExportRow row in rows) _entry(row),
          ],
        );
  }

  @override
  Future<Result<ExportEntry?>> byId(String id) async {
    final sqlite.ExportRow? row =
        await (_db.select(_db.exports)
              ..where((sqlite.$ExportsTable table) => table.id.equals(id)))
            .getSingleOrNull();
    return Success<ExportEntry?>(row == null ? null : _entry(row));
  }

  @override
  Future<Result<ExportEntry>> save(ExportEntry entry) async {
    if (entry.projectId.isEmpty) {
      return const FailureResult<ExportEntry>(
        ValidationFailure(
          message: 'An export needs a project.',
          recoveryAction: 'Open a project and export again.',
        ),
      );
    }
    return const FailureResult<ExportEntry>(
      ValidationFailure(
        message: 'An export is recorded only when the file is finished.',
        recoveryAction: 'Finish writing the file, then record the export.',
      ),
    );
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) {
    if (id.isEmpty) {
      return Future<Result<void>>.value(const FailureResult<void>(_missing));
    }
    if (reason.isEmpty) {
      return Future<Result<void>>.value(
        const FailureResult<void>(_needsReason),
      );
    }
    return _dao.softDelete(id, reason: reason);
  }

  @override
  Future<Result<ExportedWorkbook>> exportProject(
    String projectId, {
    required CancellationToken cancel,
  }) async {
    if (cancel.isCancelled) {
      return const FailureResult<ExportedWorkbook>(CancelledFailure());
    }
    final sqlite.Project? project =
        await (_db.select(_db.projects)
              ..where((sqlite.$ProjectsTable row) => row.id.equals(projectId)))
            .getSingleOrNull();
    if (project == null) {
      return const FailureResult<ExportedWorkbook>(
        StorageFailure(message: 'The photo project was not found.'),
      );
    }
    final List<QueryRow> records = await _db
        .customSelect(
          'SELECT r.status AS status, '
          '(SELECT COUNT(*) FROM photos p WHERE p.record_id = r.id) '
          'AS photo_count '
          'FROM records r WHERE r.project_id = ? AND r.status != ? '
          'ORDER BY r.created_at, r.id',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            const Variable<String>('deleted'),
          ],
          readsFrom: <TableInfo<dynamic, dynamic>>{_db.records, _db.photos},
        )
        .get();
    if (records.isEmpty) {
      return const FailureResult<ExportedWorkbook>(
        ValidationFailure(
          message: 'Nothing to export',
          recoveryAction: 'Capture a record before exporting this project.',
        ),
      );
    }
    final Result<Uint8List> encoded =
        await runIsolate<List<Object?>, Uint8List>(_encodeWorkbook, <Object?>[
          project.name,
          _clock.nowUtc().toIso8601String(),
          <List<Object?>>[
            for (final QueryRow row in records)
              <Object?>[
                row.read<String>('status'),
                row.read<int>('photo_count'),
              ],
          ],
        ], cancel: cancel);
    if (encoded is FailureResult<Uint8List>) {
      return FailureResult<ExportedWorkbook>(encoded.failure);
    }
    if (cancel.isCancelled) {
      return const FailureResult<ExportedWorkbook>(CancelledFailure());
    }
    final Uint8List bytes = (encoded as Success<Uint8List>).value;
    final String id = _ids.newId();
    final String storedName = '$id.xlsx';
    final String relative =
        'projects/${project.folderName}/exports/$storedName';
    final String displayName = ExportFileName.build(
      projectName: project.name,
      local: _clock.nowUtc().toLocal(),
    );
    final Result<WrittenFile> written = await _writer.write(
      Stream<List<int>>.value(bytes),
      relative,
    );
    if (written is FailureResult<WrittenFile>) {
      return FailureResult<ExportedWorkbook>(written.failure);
    }
    final WrittenFile file = (written as Success<WrittenFile>).value;
    if (cancel.isCancelled) {
      await _discard(file.relativePath);
      return const FailureResult<ExportedWorkbook>(CancelledFailure());
    }
    final Result<sqlite.ExportRow> row = await completeExport(
      _db,
      produce: () async => sqlite.ExportsCompanion(
        id: Value<String>(id),
        projectId: Value<String>(projectId),
        formats: Value<String>(jsonEncode(<String>['xlsx'])),
        filters: Value<String>(
          jsonEncode(<String, String>{'project': projectId}),
        ),
        recordCount: Value<int>(records.length),
        filePath: Value<String>(file.relativePath),
        fileHash: Value<String>(file.sha256),
        createdBy: Value<String>(_deviceId),
      ),
      clock: _clock,
      deviceId: _deviceId,
      ids: _ids,
    );
    switch (row) {
      case FailureResult<sqlite.ExportRow>(:final Failure failure):
        await _discard(file.relativePath);
        return FailureResult<ExportedWorkbook>(failure);
      case Success<sqlite.ExportRow>(:final sqlite.ExportRow value):
        return Success<ExportedWorkbook>((
          id: value.id,
          projectId: value.projectId,
          version: value.version,
          fileName: displayName,
          bytes: bytes,
        ));
    }
  }

  Future<void> _discard(String relativePath) async {
    final Result<Directory> root = await _storageRoot.resolve();
    if (root is! Success<Directory>) {
      return;
    }
    await discardUnpublishedFile(File('${root.value.path}/$relativePath'));
  }

  ExportEntry _entry(sqlite.ExportRow row) {
    return (
      id: row.id,
      projectId: row.projectId,
      version: row.version,
      status: 'complete',
    );
  }
}

/// The device export store. Tests leave this empty and pass a fake.
final Provider<ExportRepository?> exportRepositoryProvider =
    Provider<ExportRepository?>((Ref _) => null);

final class _ExportDao extends BaseDao<Exports, sqlite.ExportRow> {
  _ExportDao(
    sqlite.AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.exports);
}

Future<Uint8List> _encodeWorkbook(List<Object?> job) {
  final String name = job[0]! as String;
  final DateTime created = DateTime.parse(job[1]! as String);
  final List<Object?> source = job[2]! as List<Object?>;
  IsolateRunner.reportProgress(1);
  final XlsxBook book = XlsxBook(
    createdUtc: created,
    subject: name,
    sheets: <XlsxSheet>[
      XlsxSheet(
        name: 'Records',
        freezeHeader: true,
        columns: const <XlsxColumn>[
          XlsxColumn('Record', width: 12),
          XlsxColumn('Status', width: 18),
          XlsxColumn('Photos', width: 12),
        ],
        rows: <List<XlsxCell>>[
          for (int index = 0; index < source.length; index++)
            <XlsxCell>[
              XlsxCell.number(index + 1),
              XlsxCell.text((source[index]! as List<Object?>)[0]! as String),
              XlsxCell.number((source[index]! as List<Object?>)[1]! as int),
            ],
        ],
      ),
    ],
  );
  return Future<Uint8List>.value(XlsxEncoder.encode(book));
}

const StorageFailure _missing = StorageFailure(
  message: 'That row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _needsReason = StorageFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why this row should be removed, then try again.',
);

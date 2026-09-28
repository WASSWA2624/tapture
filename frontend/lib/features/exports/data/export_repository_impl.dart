import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/exports.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/xlsx_encoder.dart';
import 'package:tapture/core/export/xlsx_writer.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/exports/domain/export_file_name.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/deliverable_repository.dart';
import 'export_record_loader.dart';

/// Device [ExportRepository]. An export is a new project package under the
/// project's `exports/` folder, the workbook inside it; the row is inserted
/// only after that file exists.
///
/// The same transaction writes the export's membership into each included
/// record's history: one audit row on entity `records`, field key `export`,
/// new value `v<version>` and the formats as the reason (task 014 D10).
final class ExportRepositoryImpl implements ExportRepository {
  /// Creates the repository over the local database and storage root.
  ExportRepositoryImpl({
    required sqlite.AppDatabase db,
    required StorageRoot storageRoot,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required TemplateRepository templates,
    FileWriter? writer,
    FileReader? files,
    EvidencePurge? cleanup,
    BundleWriter? bundles,
  }) : _db = db,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _writer = writer ?? FileWriter(storageRoot: storageRoot),
       _loader = ExportRecordLoader(
         records: RecordRepositoryImpl(
           db: db,
           clock: clock,
           deviceId: deviceId,
           ids: ids,
         ),
         templates: templates,
       ),
       _cleanup = cleanup ?? EvidencePurge(storageRoot: storageRoot),
       _bundles =
           bundles ??
           BundleWriter(
             db: db,
             storageRoot: storageRoot,
             files: files ?? FileReader(storageRoot: storageRoot),
             clock: clock,
             ids: ids,
             deviceId: deviceId,
           ),
       _dao = _ExportDao(db, clock: clock, deviceId: deviceId, ids: ids);

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final FileWriter _writer;
  final EvidencePurge _cleanup;
  final BundleWriter _bundles;
  final _ExportDao _dao;
  final ExportRecordLoader _loader;

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
  Future<Result<int>> estimatePackage(String projectId) {
    return _bundles.estimate(projectId);
  }

  @override
  Future<Result<ExportedPackage>> exportProject(
    String projectId, {
    required CancellationToken cancel,
    void Function(double)? onProgress,
  }) async {
    if (cancel.isCancelled) {
      return const FailureResult<ExportedPackage>(CancelledFailure());
    }
    final sqlite.Project? project =
        await (_db.select(_db.projects)
              ..where((sqlite.$ProjectsTable row) => row.id.equals(projectId)))
            .getSingleOrNull();
    if (project == null) {
      return const FailureResult<ExportedPackage>(
        StorageFailure(message: 'The photo project was not found.'),
      );
    }
    final Result<PreparedDeliverable> loaded = await _loader.load(
      ExportRequest(
        projectId: projectId,
        formats: const <ExportFormat>{ExportFormat.xlsx},
        scope: (
          kind: ExportScopeKind.all,
          context: null,
          from: null,
          to: null,
          filter: null,
        ),
        columns: (raw: true, refined: true, confidence: true, evidence: true),
        extras: (
          dictionary: true,
          photoIndex: true,
          photoMode: 'path',
          delimiter: ',',
        ),
      ),
      cancel: cancel,
    );
    if (loaded case FailureResult<PreparedDeliverable>(
      :final Failure failure,
    )) {
      return FailureResult<ExportedPackage>(failure);
    }
    final ExportRequest request =
        (loaded as Success<PreparedDeliverable>).value.request;
    final List<ExportRecord> records = request.records;
    if (records.isEmpty) {
      return const FailureResult<ExportedPackage>(
        ValidationFailure(
          message: 'Nothing to export',
          recoveryAction: 'Capture a record before exporting this project.',
        ),
      );
    }
    final Result<Uint8List> encoded =
        await runIsolate<
          ({ExportRequest request, DateTime created}),
          Uint8List
        >(_encodeWorkbook, (
          request: request,
          created: _clock.nowUtc(),
        ), cancel: cancel);
    if (encoded is FailureResult<Uint8List>) {
      return FailureResult<ExportedPackage>(encoded.failure);
    }
    if (cancel.isCancelled) {
      return const FailureResult<ExportedPackage>(CancelledFailure());
    }
    // The workbook travels inside the package, for a reader outside the
    // app (task 076, D13).
    final Result<BundleOutput> written = await _bundles.write(
      projectId: projectId,
      cancel: cancel,
      onProgress: onProgress,
      extras: <String, List<int>>{
        BundleFormat.workbook: (encoded as Success<Uint8List>).value,
      },
    );
    if (written case FailureResult<BundleOutput>(:final Failure failure)) {
      return FailureResult<ExportedPackage>(failure);
    }
    final BundleOutput package = (written as Success<BundleOutput>).value;
    final String id = _ids.newId();
    final String relative;
    switch (package) {
      case StoredBundle(:final String relativePath):
        relative = relativePath;
      case InMemoryBundle(:final Uint8List bytes):
        // A browser keeps its copy where it keeps every project file.
        relative =
            'projects/${project.folderName}/exports/$id.'
            '${BundleFormat.extension}';
        final Result<WrittenFile> kept = await _writer.write(
          Stream<List<int>>.value(bytes),
          relative,
        );
        if (kept case FailureResult<WrittenFile>(:final Failure failure)) {
          return FailureResult<ExportedPackage>(failure);
        }
    }
    if (cancel.isCancelled) {
      await _discard(relative);
      return const FailureResult<ExportedPackage>(CancelledFailure());
    }
    final List<String> formats = <String>['bundle', 'xlsx'];
    final Result<sqlite.ExportRow> row = await runInTransaction(_db, () async {
      final Result<sqlite.ExportRow> completed = await completeExport(
        _db,
        produce: () async => sqlite.ExportsCompanion(
          id: Value<String>(id),
          projectId: Value<String>(projectId),
          formats: Value<String>(jsonEncode(formats)),
          filters: Value<String>(
            jsonEncode(<String, String>{'project': projectId}),
          ),
          recordCount: Value<int>(records.length),
          filePath: Value<String>(relative),
          fileHash: Value<String>(package.sha256),
          createdBy: Value<String>(_deviceId),
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      );
      final sqlite.ExportRow stored = switch (completed) {
        Success<sqlite.ExportRow>(:final sqlite.ExportRow value) => value,
        FailureResult<sqlite.ExportRow>(:final Failure failure) =>
          throw Failure.from(failure),
      };
      await _recordMembership(
        <String>[for (final ExportRecord record in records) record.id],
        version: stored.version,
        formats: formats,
      );
      return stored;
    });
    switch (row) {
      case FailureResult<sqlite.ExportRow>(:final Failure failure):
        await _discard(relative);
        return FailureResult<ExportedPackage>(failure);
      case Success<sqlite.ExportRow>(:final sqlite.ExportRow value):
        return Success<ExportedPackage>((
          id: value.id,
          projectId: value.projectId,
          version: value.version,
          fileName: ExportFileName.build(
            projectName: project.name,
            local: _clock.nowUtc().toLocal(),
            extension: BundleFormat.extension,
          ),
          package: package,
        ));
    }
  }

  @override
  Stream<ExportSummary> watchSummary(String projectId) {
    // The same records exportProject writes: every status but deleted.
    const String written = 'r.project_id = ? AND r.status != ?';
    final List<Variable<Object>> scope = <Variable<Object>>[
      Variable<String>(projectId),
      Variable<String>(RecordStatus.deleted.stored),
    ];
    final String unprocessed = List<String>.filled(
      _unprocessedStatuses.length,
      '?',
    ).join(', ');
    return _db
        .customSelect(
          'SELECT '
          '(SELECT name FROM projects WHERE id = ?) AS project_name, '
          '(SELECT COUNT(*) FROM records r WHERE $written) AS records, '
          '(SELECT COUNT(*) FROM records r WHERE $written AND r.status IN '
          '($unprocessed)) AS unprocessed, '
          '(SELECT COUNT(*) FROM records r WHERE $written '
          'AND r.status = ?) AS needs_review, '
          '(SELECT COUNT(*) FROM records r WHERE $written '
          'AND r.status = ?) AS approved, '
          '(SELECT COUNT(*) FROM photos p JOIN records r ON r.id = p.record_id '
          'WHERE $written AND $activePhotoCondition) AS photos, '
          '(SELECT COUNT(DISTINCT o.attachment_id) FROM attachment_owners o '
          'JOIN attachments a ON a.id = o.attachment_id '
          'JOIN records r ON r.id = o.owner_id '
          "WHERE o.owner_type = 'record' AND a.kind = 'audio' AND $written) "
          'AS audio, '
          '(SELECT MIN(r.captured_at) FROM records r WHERE $written) AS first, '
          '(SELECT MAX(r.captured_at) FROM records r WHERE $written) AS last',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            ...scope,
            ...scope,
            for (final RecordStatus status in _unprocessedStatuses)
              Variable<String>(status.stored),
            ...scope,
            Variable<String>(RecordStatus.needsReview.stored),
            ...scope,
            Variable<String>(RecordStatus.approved.stored),
            for (int block = 0; block < 4; block++) ...scope,
          ],
          readsFrom: <TableInfo<dynamic, dynamic>>{
            _db.projects,
            _db.records,
            _db.photos,
            _db.tombstones,
            _db.attachments,
            _db.attachmentOwners,
            _db.templates,
          },
        )
        .watchSingle()
        .asyncMap((QueryRow row) async {
          final List<QueryRow> templates = await _db
              .customSelect(
                'SELECT t.name AS name, COUNT(*) AS records FROM records r '
                'JOIN templates t ON t.id = r.template_id WHERE $written '
                'GROUP BY r.template_id ORDER BY records DESC, t.name',
                variables: scope,
              )
              .get();
          return (
            projectName: row.read<String?>('project_name') ?? '',
            records: row.read<int>('records'),
            photos: row.read<int>('photos'),
            audioClips: row.read<int>('audio'),
            unprocessed: row.read<int>('unprocessed'),
            needsReview: row.read<int>('needs_review'),
            approved: row.read<int>('approved'),
            templates: <ExportTemplateCount>[
              for (final QueryRow template in templates)
                (
                  name: template.read<String>('name'),
                  records: template.read<int>('records'),
                ),
            ],
            firstCapturedAt: row.read<DateTime?>('first'),
            lastCapturedAt: row.read<DateTime?>('last'),
          );
        });
  }

  /// Appends the export to the history of each record in [recordIds],
  /// inside the caller's transaction: the membership the list and the
  /// history read.
  Future<void> _recordMembership(
    List<String> recordIds, {
    required int version,
    required List<String> formats,
  }) async {
    final String reason = formats.join(',');
    for (final String recordId in recordIds) {
      await appendAudit(
        _db,
        entityType: _db.records.actualTableName,
        entityId: recordId,
        action: AuditAction.updated,
        fieldKey: _exportAuditKey,
        newValue: 'v$version',
        reason: reason,
        clock: _clock,
        device: _deviceId,
      );
    }
  }

  Future<void> _discard(String relativePath) async {
    await _cleanup.removeFiles(<String>[relativePath]);
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

Future<Uint8List> _encodeWorkbook(
  ({ExportRequest request, DateTime created}) job,
) {
  IsolateRunner.reportProgress(1);
  return Future<Uint8List>.value(
    XlsxEncoder.encode(XlsxWriter.build(job.request, createdUtc: job.created)),
  );
}

/// Audit `field_key` of a record's export membership, on entity `records`.
const String _exportAuditKey = 'export';

/// Statuses the summary counts as not yet processed: waiting to be, being,
/// or failed and waiting to be again.
const List<RecordStatus> _unprocessedStatuses = <RecordStatus>[
  RecordStatus.draft,
  RecordStatus.captured,
  RecordStatus.queued,
  RecordStatus.processing,
  RecordStatus.failed,
];

const StorageFailure _missing = StorageFailure(
  message: 'That row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _needsReason = StorageFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why this row should be removed, then try again.',
);

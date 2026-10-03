import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/bundle/bundle_privacy.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
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
import 'package:tapture/core/export/export_status_bucket.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/xlsx_encoder.dart';
import 'package:tapture/core/export/xlsx_writer.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/photo_privacy_service.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/exports/domain/export_file_name.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/deliverable_repository.dart';
import '../domain/export_sharing_policy.dart';
import 'export_operator.dart';
import 'export_privacy.dart';
import 'export_record_loader.dart';

/// Device [ExportRepository]. An export is a new project package under the
/// project's `exports/` folder, the workbook inside it; the row is inserted
/// only after that file exists.
///
/// The same transaction writes the export's membership into each included
/// record's history: one audit row on entity `records`, field key `export`,
/// new value `v<version>` and the formats as the reason (task 014 D10).
final class ExportRepositoryImpl
    implements ExportRepository, ExportSharingPolicy {
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
    PhotoPrivacyService? privacy,
    Future<bool> Function()? excludeCoordinates,
    Future<bool> Function()? blurFaces,
  }) : _db = db,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _writer = writer ?? FileWriter(storageRoot: storageRoot),
       _files = files ?? FileReader(storageRoot: storageRoot),
       _excludeCoordinates = excludeCoordinates ?? _excludeByDefault,
       _privacy = ExportPrivacy(
         db: db,
         records: RecordRepositoryImpl(
           db: db,
           clock: clock,
           deviceId: deviceId,
           ids: ids,
         ),
         templates: templates,
         photos:
             privacy ??
             PhotoPrivacyService(
               db: db,
               files: files ?? FileReader(storageRoot: storageRoot),
               writer: writer ?? FileWriter(storageRoot: storageRoot),
               clock: clock,
               deviceId: deviceId,
             ),
         excludeCoordinates: excludeCoordinates ?? _excludeByDefault,
         blurFaces: blurFaces ?? _noFaceBlur,
       ),
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
  final FileReader _files;
  final Future<bool> Function() _excludeCoordinates;
  final ExportPrivacy _privacy;
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
      return FailureResult<ExportEntry>(
        ValidationFailure(
          localizedMessage: Copy.messages.failureAnExportNeedsAProject,
          localizedRecovery: Copy.messages.failureOpenAProjectAndExportAgain,
        ),
      );
    }
    return FailureResult<ExportEntry>(
      ValidationFailure(
        localizedMessage: Copy.messages.failureAnExportIsRecordedOnlyWhenThe,
        localizedRecovery:
            Copy.messages.failureFinishWritingTheFileThenRecordThe,
      ),
    );
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) {
    if (id.isEmpty) {
      return Future<Result<void>>.value(FailureResult<void>(_missing));
    }
    if (reason.isEmpty) {
      return Future<Result<void>>.value(FailureResult<void>(_needsReason));
    }
    return _dao.softDelete(id, reason: reason);
  }

  @override
  Future<Result<int>> estimatePackage(
    String projectId, {
    ExportScope? scope,
    bool withoutPhotos = false,
  }) => Result.captureAsync<int>(() async {
    if (scope == null && !withoutPhotos) {
      return (await _bundles.estimate(projectId)).getOrThrow();
    }
    final ExportRequest request = (await _loader.load(
      _packageRequest(projectId, scope),
      cancel: CancellationToken(),
    )).getOrThrow().request;
    final BundleTables source = (await BundleTables.read(_db, projectId))!;
    final Set<String> selected = request.records
        .map((ExportRecord record) => record.id)
        .toSet();
    final BundlePrivacy policy = BundlePrivacy(
      recordIds: selected,
      photoRows: <String, Map<String, Object?>>{
        if (!withoutPhotos)
          for (final Map<String, Object?> photo in source.rows['photos']!)
            if (selected.contains(photo['record_id']))
              photo['id']! as String: photo,
      },
    );
    return (await _bundles.estimate(projectId, privacy: policy)).getOrThrow();
  });

  @override
  Future<Result<ExportedPackage>> exportProject(
    String projectId, {
    required CancellationToken cancel,
    ExportScope? scope,
    bool withoutPhotos = false,
    String? password,
    void Function(double)? onProgress,
    void Function(({String stage, double fraction}))? onStageProgress,
  }) async {
    if (cancel.isCancelled) {
      return const FailureResult<ExportedPackage>(CancelledFailure());
    }
    onStageProgress?.call((stage: 'records', fraction: 0));
    final sqlite.Project? project =
        await (_db.select(_db.projects)
              ..where((sqlite.$ProjectsTable row) => row.id.equals(projectId)))
            .getSingleOrNull();
    if (project == null) {
      return FailureResult<ExportedPackage>(
        StorageFailure(
          localizedMessage: Copy.messages.failureThePhotoProjectWasNotFound,
        ),
      );
    }
    final Result<PreparedDeliverable> loaded = await _loader.load(
      _packageRequest(projectId, scope),
      cancel: cancel,
    );
    if (loaded case FailureResult<PreparedDeliverable>(
      :final Failure failure,
    )) {
      return FailureResult<ExportedPackage>(failure);
    }
    ExportRequest request;
    final BundlePrivacy policy;
    try {
      final ExportRequest selected =
          (loaded as Success<PreparedDeliverable>).value.request;
      request = await _privacy.resolve(
        withoutPhotos ? _withoutPhotos(selected) : selected,
        cancel,
      );
      policy = await _bundlePolicy(request, cancel);
      request = request.copyWith(
        records: <ExportRecord>[
          for (final ExportRecord row in request.records)
            ExportRecord.fromJson(<String, Object?>{
              ...row.toJson(),
              'photos': <Object?>[
                for (final Object? photo
                    in row.toJson()['photos']! as List<Object?>)
                  if (photo is Map)
                    <String, Object?>{
                      ...Map<String, Object?>.from(photo),
                      'storedPath':
                          policy.photoRows[photo['id']]!['relative_path'],
                    },
              ],
            }),
        ],
      );
    } on Object catch (error) {
      return FailureResult<ExportedPackage>(Failure.from(error));
    }
    final List<ExportRecord> records = request.records;
    if (records.isEmpty) {
      return FailureResult<ExportedPackage>(
        ValidationFailure(
          localizedMessage: Copy.messages.projectExportEmptyHeadline,
          localizedRecovery: Copy.messages.projectExportEmptyMessage,
        ),
      );
    }
    onStageProgress?.call((stage: 'records', fraction: 1));
    // Photo paths are collected with the resolved records, then streamed
    // into the archive; no full original is loaded for this stage.
    onStageProgress?.call((stage: 'photos', fraction: 1));
    onStageProgress?.call((stage: 'reports', fraction: 0));
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
    onStageProgress?.call((stage: 'reports', fraction: 1));
    onStageProgress?.call((stage: 'archive', fraction: 0));
    // The workbook travels inside the package, for a reader outside the
    // app (task 076, D13).
    final Result<BundleOutput> written = await _bundles.write(
      projectId: projectId,
      cancel: cancel,
      onProgress: (double fraction) {
        onProgress?.call(fraction);
        onStageProgress?.call((stage: 'archive', fraction: fraction));
      },
      extras: <String, List<int>>{
        BundleFormat.workbook: (encoded as Success<Uint8List>).value,
        'privacy-summary.json': utf8.encode(
          jsonEncode(<String, Object?>{
            'omittedRecordIds': request.omittedRecordIds,
            'photoFaceCounts': request.photoFaceCounts,
          }),
        ),
      },
      privacy: policy,
      password: password,
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
    final String operator = await exportOperator(_db, fallback: _deviceId);
    final Result<sqlite.ExportRow> row = await runInTransaction(_db, () async {
      if (request.privacyFingerprint != await _privacy.fingerprint(projectId)) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.exportPrivacyChanged,
        );
      }
      final Result<sqlite.ExportRow> completed = await completeExport(
        _db,
        produce: () async => sqlite.ExportsCompanion(
          id: Value<String>(id),
          projectId: Value<String>(projectId),
          formats: Value<String>(jsonEncode(formats)),
          filters: Value<String>(
            jsonEncode(<String, Object?>{
              'project': projectId,
              'privacyFingerprint': request.privacyFingerprint,
              'omittedRecordIds': request.omittedRecordIds,
              'photoFaceCounts': request.photoFaceCounts,
            }),
          ),
          recordCount: Value<int>(records.length),
          filePath: Value<String>(relative),
          fileHash: Value<String>(package.sha256),
          createdBy: Value<String>(operator),
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
      ExportStatusBucket.unprocessedStatuses.length,
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
            for (final RecordStatus status
                in ExportStatusBucket.unprocessedStatuses)
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

  Future<BundlePrivacy> _bundlePolicy(
    ExportRequest request,
    CancellationToken cancel,
  ) async {
    final bool exclude = await _excludeCoordinates();
    final Map<String, Map<String, Object?>> rows =
        <String, Map<String, Object?>>{};
    final Map<String, String> sources = <String, String>{};
    for (final ExportRecord record in request.records) {
      for (final ExportPhoto photo in record.photos) {
        if (cancel.isCancelled) throw const CancelledFailure();
        final String source = record.photoSources[photo.id] ?? photo.storedPath;
        final Uint8List bytes = (await _files.read(source)).getOrThrow();
        final _PhotoAsset info = (await runIsolate<Uint8List, _PhotoAsset>(
          _photoAsset,
          bytes,
          cancel: cancel,
        )).getOrThrow();
        final String name =
            'privacy_${crypto.sha256.convert(utf8.encode(photo.id))}.${info.extension}';
        final String path = 'photos/$name';
        rows[photo.id] = <String, Object?>{
          'relative_path': path,
          'stored_filename': name,
          'sha256': info.hash,
          'file_size': bytes.length,
          'width': info.width,
          'height': info.height,
          'mime_type': info.mimeType,
          if (exclude) 'gps_lat': null,
          if (exclude) 'gps_lon': null,
          'derived_from': null,
          if (source.startsWith('.cache/')) 'rotation_degrees': 0,
        };
        sources[path] = source;
      }
    }
    return BundlePrivacy(
      recordIds: request.records.map((ExportRecord row) => row.id).toSet(),
      photoRows: rows,
      fileSources: sources,
      excludeCoordinates: exclude,
    );
  }

  @override
  Future<Result<void>> allowShare(String exportId) =>
      Result.captureAsync(() async {
        final sqlite.ExportRow? row =
            await (_db.select(_db.exports)..where(
                  (sqlite.$ExportsTable table) => table.id.equals(exportId),
                ))
                .getSingleOrNull();
        if (row == null) {
          throw StorageFailure(
            localizedMessage: Copy.messages.exportReplayMissing,
          );
        }
        final Map<String, Object?> filters = Map<String, Object?>.from(
          jsonDecode(row.filters) as Map,
        );
        if (filters['privacyFingerprint'] !=
            await _privacy.fingerprint(row.projectId)) {
          throw ValidationFailure(
            localizedMessage: Copy.messages.exportPrivacyChanged,
          );
        }
      });

  @override
  Future<Result<ExportPrivacySummary>> privacySummary(String exportId) =>
      Result.captureAsync(() async {
        final sqlite.ExportRow row =
            await (_db.select(_db.exports)..where(
                  (sqlite.$ExportsTable table) => table.id.equals(exportId),
                ))
                .getSingle();
        final Map<String, Object?> value = Map<String, Object?>.from(
          jsonDecode(row.filters) as Map,
        );
        return (
          omittedRecordIds: (value['omittedRecordIds'] as List? ?? <Object?>[])
              .cast<String>(),
          photoFaceCounts: Map<String, int>.from(
            value['photoFaceCounts'] as Map? ?? <Object?, Object?>{},
          ),
        );
      });

  ExportEntry _entry(sqlite.ExportRow row) {
    return (
      id: row.id,
      projectId: row.projectId,
      version: row.version,
      status: 'complete',
    );
  }
}

typedef _PhotoAsset = ({
  String hash,
  int width,
  int height,
  String extension,
  String mimeType,
});
_PhotoAsset _photoAsset(Uint8List bytes) {
  final img.Image? photo = img.decodeImage(bytes);
  if (photo == null) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThisExportedPhotoCannotBeRead,
    );
  }
  final bool png =
      bytes.length >= 4 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71;
  final bool jpeg = bytes.length >= 2 && bytes[0] == 255 && bytes[1] == 216;
  if (!png && !jpeg) {
    throw ValidationFailure(
      localizedMessage:
          Copy.messages.failureThisPhotoFormatCannotBePackagedSafely,
    );
  }
  return (
    hash: crypto.sha256.convert(bytes).toString(),
    width: photo.width,
    height: photo.height,
    extension: png ? 'png' : 'jpg',
    mimeType: png ? 'image/png' : 'image/jpeg',
  );
}

Future<bool> _excludeByDefault() async => true;
Future<bool> _noFaceBlur() async => false;

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

final StorageFailure _missing = StorageFailure(
  localizedMessage: Copy.messages.failureThatRowIsNoLongerOnThis,
  localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
);

final StorageFailure _needsReason = StorageFailure(
  localizedMessage: Copy.messages.failureADeleteNeedsAReason,
  localizedRecovery: Copy.messages.failureSayWhyThisRowShouldBeRemoved,
);

ExportRequest _packageRequest(String projectId, ExportScope? scope) =>
    ExportRequest(
      projectId: projectId,
      formats: const <ExportFormat>{ExportFormat.xlsx},
      scope:
          scope ??
          (
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
        pdfPhotos: 'thumbnail',
        delimiter: ',',
      ),
    );

ExportRequest _withoutPhotos(ExportRequest source) => source.copyWith(
  extras: (
    dictionary: source.extras.dictionary,
    photoIndex: source.extras.photoIndex,
    photoMode: 'none',
    pdfPhotos: source.extras.pdfPhotos,
    delimiter: source.extras.delimiter,
  ),
  records: <ExportRecord>[
    for (final ExportRecord record in source.records)
      ExportRecord.fromJson(<String, Object?>{
        ...record.toJson(),
        'photos': const <Object?>[],
        'photoSources': const <String, String>{},
      }),
  ],
);

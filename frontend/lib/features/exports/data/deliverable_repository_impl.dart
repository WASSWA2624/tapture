import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/exports.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_manifest.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/photo_naming.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/xlsx_multi_sheet.dart';
import 'package:tapture/core/export/xlsx_photo_refs.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/export_archive.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/deliverable_repository.dart';
import 'deliverable_renderer.dart';
import 'export_record_loader.dart';

/// Writes deliverables from actual selected records and commits history only
/// after both output and its replayable request are durable.
final class DeliverableRepositoryImpl implements DeliverableRepository {
  /// Composes the same stores already used by capture and review.
  DeliverableRepositoryImpl({
    required this._db,
    required StorageRoot storageRoot,
    required RecordRepository records,
    required TemplateRepository templates,
    required this._clock,
    required this._ids,
    required this._deviceId,
    FileReader? files,
    FileWriter? writer,
    EvidencePurge? cleanup,
    bool inBrowser = kIsWeb,
    Future<Uint8List> Function()? font,
  }) : _files = files ?? FileReader(storageRoot: storageRoot),
       _writer = writer ?? FileWriter(storageRoot: storageRoot),
       _cleanup = cleanup ?? EvidencePurge(storageRoot: storageRoot),
       _loader = ExportRecordLoader(records: records, templates: templates),
       _renderer = DeliverableRenderer(
         files: files ?? FileReader(storageRoot: storageRoot),
         font: font,
       ),
       _archive = ExportArchive(
         storageRoot: storageRoot,
         files: files ?? FileReader(storageRoot: storageRoot),
         writer: writer ?? FileWriter(storageRoot: storageRoot),
         inBrowser: inBrowser,
       );

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final IdService _ids;
  final String _deviceId;
  final FileReader _files;
  final FileWriter _writer;
  final EvidencePurge _cleanup;
  final ExportRecordLoader _loader;
  final DeliverableRenderer _renderer;
  final ExportArchive _archive;

  Future<sqlite.Project?> _project(String id) => (_db.select(
    _db.projects,
  )..where((sqlite.$ProjectsTable row) => row.id.equals(id))).getSingleOrNull();

  @override
  Future<Result<ExportRequest>> options(String projectId) async {
    try {
      final sqlite.Project? project = await _project(projectId);
      if (project == null) {
        return const FailureResult<ExportRequest>(_missingProjectFailure);
      }
      final Map<String, Object?> settings = Map<String, Object?>.from(
        jsonDecode(project.settings) as Map,
      );
      final Object? remembered = settings['exportOptions'];
      return Success<ExportRequest>(
        remembered is Map
            ? ExportRequest.fromJson(<String, Object?>{
                ...Map<String, Object?>.from(remembered),
                'projectId': projectId,
              })
            : ExportRequest(
                projectId: projectId,
                formats: const <ExportFormat>{
                  ExportFormat.xlsx,
                  ExportFormat.zip,
                },
                scope: (
                  kind: ExportScopeKind.approved,
                  context: null,
                  from: null,
                  to: null,
                  filter: null,
                ),
                columns: (
                  raw: false,
                  refined: settings['refineColumns'] != false,
                  confidence: false,
                  evidence: false,
                ),
                extras: (
                  dictionary: true,
                  photoIndex: true,
                  photoMode: 'relative',
                  delimiter: ',',
                ),
              ),
      );
    } on Object catch (error) {
      return FailureResult<ExportRequest>(Failure.from(error));
    }
  }

  @override
  Future<Result<void>> remember(ExportRequest request) async {
    try {
      final sqlite.Project? project = await _project(request.projectId);
      if (project == null) {
        return const FailureResult<void>(_missingProjectFailure);
      }
      final Map<String, Object?> settings = Map<String, Object?>.from(
        jsonDecode(project.settings) as Map,
      );
      settings['exportOptions'] = request
          .copyWith(
            records: const <ExportRecord>[],
            files: const <ExportFile>[],
          )
          .toJson();
      final Result<sqlite.Project> written = await upsertProject(
        _db,
        row: project
            .toCompanion(false)
            .copyWith(settings: Value<String>(jsonEncode(settings))),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      );
      return switch (written) {
        Success<sqlite.Project>() => const Success<void>(null),
        FailureResult<sqlite.Project>(:final Failure failure) =>
          FailureResult<void>(failure),
      };
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    }
  }

  @override
  Stream<int> watchCount(ExportRequest request) => _loader.watchCount(request);

  @override
  Future<Result<PreparedDeliverable>> prepare(
    ExportRequest request, {
    required CancellationToken cancel,
  }) => _loader.load(request, cancel: cancel);

  @override
  Future<Result<DeliverableEntry>> write(
    ExportRequest request, {
    required CancellationToken cancel,
    void Function(DeliverableProgress)? onProgress,
  }) async {
    final List<String> temporary = <String>[];
    final List<String> unpublished = <String>[];
    try {
      _checkCancelled(cancel);
      if (request.records.isEmpty) {
        throw const ValidationFailure(
          message: 'Nothing to export',
          recoveryAction: 'Choose a scope with records.',
        );
      }
      if (request.formats.difference(const <ExportFormat>{
        ExportFormat.zip,
      }).isEmpty) {
        throw const ValidationFailure(message: 'Choose an output format.');
      }
      final sqlite.Project? project = await _project(request.projectId);
      if (project == null) {
        throw _missingProjectFailure;
      }
      _report(onProgress, 'records', 1);
      final String id = _ids.newId();
      final DateTime createdAt = _clock.nowUtc();
      final String date = createdAt.toIso8601String().substring(0, 10);
      final String folder = 'projects/${project.folderName}/exports/$date/$id';
      final ExportRequest named = _namePhotos(request, project.name);
      final Map<String, String> sources = <String, String>{};
      for (final ExportRecord record in named.records) {
        for (final ExportPhoto photo in record.photos) {
          sources[photo.storedPath] =
              record.photoSources[photo.id] ?? photo.storedPath;
        }
      }
      _report(onProgress, 'photos', 1);
      final Map<String, Uint8List> outputs = _unwrap(
        await _renderer.render(
          named,
          createdAt: createdAt,
          cancel: cancel,
          onProgress: (double fraction) =>
              _report(onProgress, 'reports', fraction),
        ),
      );
      _checkCancelled(cancel);
      final bool zip =
          named.formats.contains(ExportFormat.zip) ||
          outputs.length != 1 ||
          sources.isNotEmpty;
      // Photo links in `relative` mode assume this layout (XlsxPhotoRefs).
      const String outputsFolder = XlsxPhotoRefs.outputsFolder;
      final List<ExportFile> paths = <ExportFile>[
        for (final String name in outputs.keys)
          (path: zip ? '$outputsFolder/$name' : name, role: 'output'),
        for (final String name in sources.keys) (path: name, role: 'photo'),
      ];
      final ExportRequest resolved = named.copyWith(files: paths);
      final String snapshotPath = '$folder/request.json';
      final String manifestPath = '$folder/manifest.json';
      final Uint8List manifest = Uint8List.fromList(
        utf8.encode(_manifest(id, createdAt, resolved).encode()),
      );
      WrittenFile output;
      if (zip) {
        final List<MapEntry<String, Uint8List>> staged = outputs.entries
            .toList();
        for (int index = 0; index < staged.length; index++) {
          // Staged by position, since two output names may sanitise alike,
          // and inside the project folder, the only place cleanup reaches.
          final String path = '$folder/$_stagingFolder/$index';
          temporary.add(path);
          _unwrap(
            await _writer.write(
              Stream<List<int>>.value(staged[index].value),
              path,
            ),
          );
          sources['$outputsFolder/${staged[index].key}'] = path;
        }
        final String target = '$folder/deliverables.zip';
        unpublished.add(target);
        output = _unwrap(
          await _archive.write(
            target: target,
            sources: sources,
            manifest: manifest,
            cancel: cancel,
            onProgress: (double fraction) =>
                _report(onProgress, 'archive', fraction),
          ),
        );
      } else {
        final MapEntry<String, Uint8List> entry = outputs.entries.single;
        final String target = '$folder/${sanitiseSegment(entry.key)}';
        unpublished.add(target);
        output = _unwrap(
          await _writer.write(Stream<List<int>>.value(entry.value), target),
        );
      }
      _checkCancelled(cancel);
      unpublished.addAll(<String>[snapshotPath, manifestPath]);
      _unwrap(
        await _writer.write(
          Stream<List<int>>.value(utf8.encode(jsonEncode(resolved.toJson()))),
          snapshotPath,
        ),
      );
      _unwrap(
        await _writer.write(Stream<List<int>>.value(manifest), manifestPath),
      );
      _checkCancelled(cancel);
      final sqlite.ExportRow row = _unwrap(
        await runInTransaction(_db, () async {
          final sqlite.ExportRow row = _unwrap(
            await completeExport(
              _db,
              produce: () async => sqlite.ExportsCompanion(
                id: Value<String>(id),
                projectId: Value<String>(request.projectId),
                formats: Value<String>(
                  jsonEncode(
                    request.formats.map((ExportFormat f) => f.name).toList(),
                  ),
                ),
                filters: Value<String>(
                  jsonEncode(<String, Object?>{
                    'kind': 'deliverable',
                    'scope': request.toJson()['scope'],
                  }),
                ),
                recordCount: Value<int>(request.records.length),
                filePath: Value<String>(output.relativePath),
                fileHash: Value<String>(output.sha256),
                createdBy: Value<String>(_deviceId),
              ),
              clock: _clock,
              deviceId: _deviceId,
              ids: _ids,
            ),
          );
          for (final ExportRecord record in request.records) {
            await appendAudit(
              _db,
              entityType: 'records',
              entityId: record.id,
              action: AuditAction.updated,
              fieldKey: 'export',
              newValue: 'v${row.version}',
              reason: request.formats.map((ExportFormat f) => f.name).join(','),
              clock: _clock,
              device: _deviceId,
            );
          }
          return row;
        }),
      );
      unpublished.clear();
      _report(onProgress, 'archive', 1);
      return Success<DeliverableEntry>(await _entry(row, project.name));
    } on Object catch (error) {
      await _cleanup.removeFiles(unpublished);
      return FailureResult<DeliverableEntry>(Failure.from(error));
    } finally {
      await _cleanup.removeFiles(temporary);
    }
  }

  /// Stops a write the operator cancelled before its next durable step.
  static void _checkCancelled(CancellationToken cancel) {
    if (cancel.isCancelled) {
      throw const CancelledFailure();
    }
  }

  /// Reports [fraction] of [stage] to [onProgress], when anything listens.
  static void _report(
    void Function(DeliverableProgress)? onProgress,
    String stage,
    double fraction,
  ) {
    onProgress?.call((stage: stage, fraction: fraction));
  }

  @override
  Stream<List<DeliverableEntry>> watchHistory({String? projectId}) {
    final SimpleSelectStatement<sqlite.$ExportsTable, sqlite.ExportRow> query =
        _db.select(_db.exports)
          ..where(
            (sqlite.$ExportsTable row) =>
                row.filters.like('%"kind":"deliverable"%'),
          )
          ..orderBy(<OrderClauseGenerator<sqlite.$ExportsTable>>[
            (sqlite.$ExportsTable row) => OrderingTerm.desc(row.createdAt),
          ]);
    if (projectId != null) {
      query.where(
        (sqlite.$ExportsTable row) => row.projectId.equals(projectId),
      );
    }
    return query.watch().asyncMap(
      (List<sqlite.ExportRow> rows) async => <DeliverableEntry>[
        for (final sqlite.ExportRow row in rows)
          await _entry(
            row,
            (await _project(row.projectId))?.name ?? row.projectId,
          ),
      ],
    );
  }

  Future<DeliverableEntry> _entry(
    sqlite.ExportRow row,
    String projectName,
  ) async {
    final Result<int?> length = await _files.length(row.filePath);
    final String extension = row.filePath.split('.').last;
    return (
      id: row.id,
      projectId: row.projectId,
      projectName: projectName,
      version: row.version,
      createdAt: row.createdAt,
      operatorName: row.createdBy,
      recordCount: row.recordCount,
      path: row.filePath,
      fileName: '${_fileStem(projectName)}_v${row.version}.$extension',
      mimeType: switch (extension) {
        'zip' => 'application/zip',
        'xlsx' =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'pdf' => 'application/pdf',
        'json' => 'application/json',
        _ => 'text/csv',
      },
      sha256: row.fileHash,
      missing: length is! Success<int?> || length.value == null,
    );
  }

  @override
  Future<Result<ExportRequest>> replay(String exportId) async {
    try {
      final sqlite.ExportRow? row =
          await (_db.select(_db.exports)
                ..where((sqlite.$ExportsTable row) => row.id.equals(exportId)))
              .getSingleOrNull();
      if (row == null) {
        throw const StorageFailure(
          message: 'This export is no longer available.',
        );
      }
      final String parent = row.filePath.substring(
        0,
        row.filePath.lastIndexOf('/'),
      );
      final Uint8List bytes = _unwrap(
        await _files.read('$parent/request.json'),
      );
      return Success<ExportRequest>(
        ExportRequest.fromJson(
          Map<String, Object?>.from(jsonDecode(utf8.decode(bytes)) as Map),
        ),
      );
    } on Object catch (error) {
      return FailureResult<ExportRequest>(Failure.from(error));
    }
  }
}

/// Production composition root supplies this shared export workflow.
final Provider<DeliverableRepository?> deliverableRepositoryProvider =
    Provider<DeliverableRepository?>((Ref _) => null);

T _unwrap<T>(Result<T> result) => switch (result) {
  Success<T>(:final T value) => value,
  FailureResult<T>(failure: final Failure resultFailure) => throw resultFailure,
};

const StorageFailure _missingProjectFailure = StorageFailure(
  message: 'The project was not found.',
);

/// Folder inside an export's own folder holding outputs until they are zipped.
const String _stagingFolder = '.staging';

/// [projectName] as a shared file's stem. A name with nothing a file name can
/// keep falls back, so a committed export is never reported as failed.
String _fileStem(String projectName) {
  try {
    return sanitiseSegment(projectName);
  } on ValidationFailure {
    return 'Project';
  }
}

ExportRequest _namePhotos(ExportRequest request, String projectName) {
  final Set<String> taken = <String>{};
  const PhotoNaming names = PhotoNaming('{record}_{type}_{sequence}');
  return request.copyWith(
    records: <ExportRecord>[
      for (final ExportRecord record in request.records)
        ExportRecord.fromJson(<String, Object?>{
          ...record.toJson(),
          'photoSources': <String, String>{
            for (final ExportPhoto photo in record.photos)
              photo.id: record.photoSources[photo.id] ?? photo.storedPath,
          },
          'photos': <Map<String, Object?>>[
            for (final ExportPhoto photo in record.photos)
              <String, Object?>{
                'id': photo.id,
                'recordId': photo.recordId,
                'type': photo.type,
                'caption': photo.caption,
                'originalName': photo.originalName,
                'sequence': photo.sequence,
                'storedPath':
                    'photos/${names.nameFor((project: projectName, recordNumber: record.number, photoType: photo.type, sequence: photo.sequence, context: const <String, String>{}, serial: null, asset: null), taken: taken)}.${photo.storedPath.split('.').last}',
              },
          ],
        }),
    ],
  );
}

ExportManifest _manifest(String id, DateTime time, ExportRequest request) {
  final Map<String, String> templates = <String, String>{
    for (final ExportRecord record in request.records)
      record.templateId: record.templateName,
  };
  final Map<String, String> sheets = <String, String>{
    for (final SheetPlan plan
        in XlsxMultiSheet.plan(<({String id, String name})>[
          for (final MapEntry<String, String> template in templates.entries)
            (id: template.key, name: template.value),
        ]))
      plan.templateId: plan.sheetName,
  };
  final Map<String, int> nextRow = <String, int>{};
  return ExportManifest(
    exportId: id,
    createdAt: time,
    request: request,
    entries: <ManifestEntry>[
      for (final ExportRecord record in request.records)
        (
          recordId: record.id,
          recordNumber: record.number,
          sheet: sheets[record.templateId]!,
          row: nextRow.update(
            record.templateId,
            (int row) => row + 1,
            ifAbsent: () => 2,
          ),
          photoPaths: record.photos
              .map((ExportPhoto photo) => photo.storedPath)
              .toList(),
        ),
    ],
  );
}

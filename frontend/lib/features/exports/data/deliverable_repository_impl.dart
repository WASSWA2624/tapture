import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
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
import 'package:tapture/core/export/text_export_writer.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/xlsx_multi_sheet.dart';
import 'package:tapture/core/export/xlsx_photo_refs.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/export_archive.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/photo_privacy_service.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/meetings/meetings.dart';
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show TranscriptRepository, TranscriptRepositoryImpl;

import '../domain/deliverable_repository.dart';
import '../domain/export_sharing_policy.dart';
import '../domain/export_versioning.dart';
import 'deliverable_renderer.dart';
import 'deliverable_reports.dart';
import 'export_operator.dart';
import 'export_privacy.dart';
import 'export_record_loader.dart';

/// Writes deliverables from actual selected records and commits history only
/// after both output and its replayable request are durable.
final class DeliverableRepositoryImpl
    implements DeliverableRepository, ExportSharingPolicy {
  /// Composes the same stores already used by capture and review. The
  /// meetings, quality and transcript stores default to ones over [db].
  DeliverableRepositoryImpl({
    required sqlite.AppDatabase db,
    required StorageRoot storageRoot,
    required RecordRepository records,
    required TemplateRepository templates,
    required Clock clock,
    required IdService ids,
    required String deviceId,
    MeetingRepository? meetings,
    QualityRepository? quality,
    TranscriptRepository? transcripts,
    FileReader? files,
    FileWriter? writer,
    EvidencePurge? cleanup,
    bool inBrowser = kIsWeb,
    Future<Uint8List> Function()? font,
    PhotoPrivacyService? privacy,
    Future<bool> Function()? excludeCoordinates,
    Future<bool> Function()? blurFaces,
  }) : _db = db,
       _clock = clock,
       _ids = ids,
       _deviceId = deviceId,
       _streamText = !inBrowser,
       _textWriter = TextExportWriter(storageRoot),
       _templates = templates,
       _files = files ?? FileReader(storageRoot: storageRoot),
       _writer = writer ?? FileWriter(storageRoot: storageRoot),
       _cleanup = cleanup ?? EvidencePurge(storageRoot: storageRoot),
       _loader = ExportRecordLoader(records: records, templates: templates),
       _privacy = ExportPrivacy(
         db: db,
         records: records,
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
       _reports = DeliverableReports(
         db: db,
         meetings:
             meetings ??
             MeetingRepositoryImpl(
               db: db,
               clock: clock,
               deviceId: deviceId,
               ids: ids,
             ),
         quality:
             quality ??
             QualityRepositoryImpl(
               db: db,
               clock: clock,
               deviceId: deviceId,
               ids: ids,
               templates: templates,
             ),
         transcripts:
             transcripts ??
             TranscriptRepositoryImpl(
               db: db,
               clock: clock,
               deviceId: deviceId,
               ids: ids,
             ),
       ),
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
  final bool _streamText;
  final TextExportWriter _textWriter;
  final TemplateRepository _templates;
  final FileReader _files;
  final FileWriter _writer;
  final EvidencePurge _cleanup;
  final ExportRecordLoader _loader;
  final ExportPrivacy _privacy;
  final DeliverableReports _reports;
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
        return FailureResult<ExportRequest>(_missingProjectFailure);
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
                formats: const <ExportFormat>{ExportFormat.zip},
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
                  pdfPhotos: PdfPhotoLayout.thumbnail,
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
        return FailureResult<void>(_missingProjectFailure);
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
  }) async {
    final Result<PreparedDeliverable> loaded = await _loader.load(
      request,
      cancel: cancel,
    );
    if (loaded is! Success<PreparedDeliverable>) {
      return loaded;
    }
    try {
      final PreparedDeliverable prepared = loaded.value;
      final List<String> blocked = await _blockedMeetings(
        prepared.request.records,
        request.projectId,
      );
      return Success<PreparedDeliverable>((
        request: prepared.request,
        validation: (
          incomplete: prepared.validation.incomplete,
          unapproved: prepared.validation.unapproved,
          blocked: blocked,
        ),
      ));
    } on Object catch (error) {
      return FailureResult<PreparedDeliverable>(Failure.from(error));
    }
  }

  /// Meeting records whose actions lack an owner or a due date while their
  /// template asks for them (task 017): they are not exported as they are.
  Future<List<String>> _blockedMeetings(
    List<ExportRecord> records,
    String projectId,
  ) async {
    final Map<String, MeetingRecord> meetings = await _reports.meetingsOf(
      projectId,
      <String>{for (final ExportRecord record in records) record.id},
    );
    final List<String> blocked = <String>[];
    for (final ExportRecord record in records) {
      final MeetingRecord? meeting = meetings[record.id];
      if (meeting == null) {
        continue;
      }
      final Result<TemplateDef?> template = await _templates.byId(
        record.templateId,
      );
      final bool requireOwner = switch (template) {
        Success<TemplateDef?>(:final TemplateDef value?) => value.fields.any(
          (FieldDef field) =>
              field.fieldKey == _actionsField &&
              field.requiredness != Requiredness.optional,
        ),
        // A meeting whose template is gone keeps the strict rule its review
        // screen applies.
        _ => true,
      };
      if (meeting.meeting.exportBlocks(requireOwner: requireOwner).isNotEmpty) {
        blocked.add(record.id);
      }
    }
    return blocked;
  }

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
        throw ValidationFailure(
          localizedMessage: Copy.messages.projectExportEmptyHeadline,
          localizedRecovery: Copy.messages.exportEmptyRecovery,
        );
      }
      if (request.formats.difference(const <ExportFormat>{
        ExportFormat.zip,
      }).isEmpty) {
        throw ValidationFailure(localizedMessage: Copy.messages.exportNoFormat);
      }
      final sqlite.Project? project = await _project(request.projectId);
      if (project == null) {
        throw _missingProjectFailure;
      }
      request = await _privacy.resolve(request, cancel);
      if (request.records.isEmpty) {
        throw ValidationFailure(
          message: request.omittedRecordIds.isEmpty
              ? Copy.projectExportEmptyHeadline
              : Copy.exportConsentOmitted(request.omittedRecordIds),
        );
      }
      final String id = _ids.newId();
      final DateTime createdAt = _clock.nowUtc();
      final String operator = await exportOperator(_db, fallback: _deviceId);
      final String folder = await ExportVersioning(
        await _takenFolders(request.projectId),
      ).allocate('projects/${project.folderName}/exports', createdAt);
      final ExportRequest named = _namePhotos(
        request,
        project.name,
        (double fraction) => _report(onProgress, 'records', fraction),
      );
      final Map<String, String> sources = <String, String>{
        for (final ExportRecord record in named.records)
          for (final ExportPhoto photo in record.photos)
            photo.storedPath: record.photoSources[photo.id] ?? photo.storedPath,
      };
      _report(onProgress, 'records', 1);
      _checkCancelled(cancel);
      final DeliverableReportInputs reports = await _reports.load(
        named,
        projectName: project.name,
        operator: operator,
        createdAt: createdAt,
      );
      final Map<String, WrittenFile> text = _streamText
          ? _unwrap(await _textWriter.write(named, folder, cancel: cancel))
          : const <String, WrittenFile>{};
      unpublished.addAll(
        text.values.map((WrittenFile file) => file.relativePath),
      );
      final Map<String, Uint8List> outputs = _unwrap(
        await _renderer.render(
          named,
          includeText: !_streamText,
          createdAt: createdAt,
          cancel: cancel,
          reports: reports,
          onStage: (String stage, double fraction) =>
              _report(onProgress, stage, fraction),
        ),
      );
      _checkCancelled(cancel);
      final bool zip =
          named.formats.contains(ExportFormat.zip) ||
          outputs.length + text.length != 1 ||
          sources.isNotEmpty;
      // Photo links in `relative` mode assume this layout (XlsxPhotoRefs).
      const String outputsFolder = XlsxPhotoRefs.outputsFolder;
      final List<ExportFile> paths = <ExportFile>[
        for (final String name in <String>{...outputs.keys, ...text.keys})
          (path: zip ? '$outputsFolder/$name' : name, role: 'output'),
        for (final String name in sources.keys) (path: name, role: 'photo'),
      ];
      final ExportRequest resolved = named.copyWith(files: paths);
      final String snapshotPath = '$folder/request.json';
      final String manifestPath = '$folder/manifest.json';
      final ExportManifest manifestDocument = _manifest(
        id,
        createdAt,
        operator,
        await _privacy.publicSnapshot(resolved),
      );
      final Uint8List manifest = _streamText
          ? Uint8List(0)
          : Uint8List.fromList(utf8.encode(manifestDocument.encode()));
      unpublished.addAll(<String>[snapshotPath, manifestPath]);
      if (_streamText) {
        _unwrap(
          await _textWriter.writeSnapshots(
            resolved,
            manifestDocument,
            folder,
            cancel: cancel,
          ),
        );
      } else {
        _unwrap(
          await _writer.write(
            Stream<List<int>>.value(utf8.encode(jsonEncode(resolved.toJson()))),
            snapshotPath,
          ),
        );
        _unwrap(
          await _writer.write(Stream<List<int>>.value(manifest), manifestPath),
        );
      }
      WrittenFile output;
      if (zip) {
        temporary.addAll(
          text.values.map((WrittenFile file) => file.relativePath),
        );
        for (final MapEntry<String, WrittenFile> file in text.entries) {
          sources['$outputsFolder/${file.key}'] = file.value.relativePath;
        }
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
            manifestSource: _streamText ? manifestPath : null,
            cancel: cancel,
            onProgress: (double fraction) =>
                _report(onProgress, 'archive', fraction),
          ),
        );
      } else if (text.isNotEmpty) {
        output = text.values.single;
      } else {
        final MapEntry<String, Uint8List> entry = outputs.entries.single;
        final String target = '$folder/${sanitiseSegment(entry.key)}';
        unpublished.add(target);
        output = _unwrap(
          await _writer.write(Stream<List<int>>.value(entry.value), target),
        );
      }
      _checkCancelled(cancel);
      _checkCancelled(cancel);
      final sqlite.ExportRow row = _unwrap(
        await runInTransaction(_db, () async {
          if (resolved.privacyFingerprint !=
              await _privacy.fingerprint(request.projectId)) {
            throw ValidationFailure(
              localizedMessage: Copy.messages.exportPrivacyChanged,
            );
          }
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
                    'scope': request
                        .copyWith(records: const <ExportRecord>[])
                        .toJson()['scope'],
                    'privacyFingerprint': resolved.privacyFingerprint,
                    'omittedRecordIds': resolved.omittedRecordIds,
                    'photoFaceCounts': resolved.photoFaceCounts,
                  }),
                ),
                recordCount: Value<int>(request.records.length),
                filePath: Value<String>(output.relativePath),
                fileHash: Value<String>(output.sha256),
                createdBy: Value<String>(operator),
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

  /// The folders [projectId]'s recorded exports already occupy, so a new
  /// export never lands in one.
  Future<Set<String>> _takenFolders(String projectId) async {
    final List<sqlite.ExportRow> rows =
        await (_db.select(_db.exports)..where(
              (sqlite.$ExportsTable row) => row.projectId.equals(projectId),
            ))
            .get();
    return <String>{
      for (final sqlite.ExportRow row in rows)
        if (row.filePath.contains('/'))
          row.filePath.substring(0, row.filePath.lastIndexOf('/')),
    };
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
    final sqlite.$ExportsTable exports = _db.exports;
    final sqlite.$ProjectsTable projects = _db.projects;
    final JoinedSelectStatement<HasResultSet, dynamic> query = _db
        .select(exports)
        .join(<Join<HasResultSet, Object?>>[
          leftOuterJoin(projects, projects.id.equalsExp(exports.projectId)),
        ]);
    query
      ..where(
        exports.filters.like('%"kind":"deliverable"%') |
            exports.formats.like('%"bundle"%'),
      )
      ..orderBy(<OrderingTerm>[
        OrderingTerm.desc(exports.createdAt),
        OrderingTerm.desc(exports.id),
      ]);
    if (projectId != null) query.where(exports.projectId.equals(projectId));
    return query.watch().asyncMap(
      (List<TypedResult> rows) async => <DeliverableEntry>[
        for (final TypedResult row in rows)
          await _entry(
            row.readTable(exports),
            row.readTableOrNull(projects)?.name ??
                row.readTable(exports).projectId,
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
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'txt' => 'text/plain',
        'json' => 'application/json',
        _ => 'text/csv',
      },
      sha256: row.fileHash,
      missing: length is! Success<int?> || length.value == null,
      package: row.formats.contains('"bundle"'),
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
        throw StorageFailure(
          localizedMessage: Copy.messages.exportReplayMissing,
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
}

Future<bool> _excludeByDefault() async => true;
Future<bool> _noFaceBlur() async => false;

/// Production composition root supplies this shared export workflow.
final Provider<DeliverableRepository?> deliverableRepositoryProvider =
    Provider<DeliverableRepository?>((Ref _) => null);

T _unwrap<T>(Result<T> result) => switch (result) {
  Success<T>(:final T value) => value,
  FailureResult<T>(failure: final Failure resultFailure) => throw resultFailure,
};

final StorageFailure _missingProjectFailure = StorageFailure(
  localizedMessage: Copy.messages.failureTheProjectWasNotFound,
);

/// Folder inside an export's own folder holding outputs until they are zipped.
const String _stagingFolder = '.staging';

/// The meeting template's action register field (task 017).
const String _actionsField = 'action_items';

/// Records named per batch while reporting the records stage.
const int _namingBatch = 50;

/// [projectName] as a shared file's stem. A name with nothing a file name can
/// keep falls back, so a committed export is never reported as failed.
String _fileStem(String projectName) {
  try {
    return sanitiseSegment(projectName);
  } on ValidationFailure {
    return 'Project';
  }
}

/// [request] with every photo named from the naming pattern, in its
/// persisted order; [onProgress] hears each batch of records named.
ExportRequest _namePhotos(
  ExportRequest request,
  String projectName,
  void Function(double fraction) onProgress,
) {
  final Set<String> taken = <String>{};
  const PhotoNaming names = PhotoNaming('{record}_{type}_{sequence}');
  final List<ExportRecord> named = <ExportRecord>[];
  for (int index = 0; index < request.records.length; index++) {
    final ExportRecord record = request.records[index];
    named.add(
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
    );
    if ((index + 1) % _namingBatch == 0) {
      onProgress((index + 1) / request.records.length);
    }
  }
  return request.copyWith(records: named);
}

ExportManifest _manifest(
  String id,
  DateTime time,
  String operator,
  ExportRequest request,
) {
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
    exportedBy: operator,
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

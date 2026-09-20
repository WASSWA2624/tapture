import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/projects.dart' as projects_db;
import 'package:tapture/core/db/tables/reference.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/db/tables/template_rows.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/project_tree_stub.dart'
    if (dart.library.io) 'package:tapture/core/files/project_tree_io.dart'
    as project_tree;
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/project_repository.dart';
import 'project_mapper.dart';

/// Drift-backed [ProjectRepository]. The only feature file besides the
/// mapper that imports both the table and the domain.
final class ProjectRepositoryImpl implements ProjectRepository {
  /// Opens against [_db], stamping writes from [_clock], [_deviceId] and
  /// [_ids]. Tests inject [_createTree] and [_discardTree] so suites never
  /// touch the real documents folder (FE-TEST-03).
  ProjectRepositoryImpl({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
    Future<Result<void>> Function({
      required String id,
      required String name,
      required String folderName,
    })?
    createTree,
    Future<Result<void>> Function({
      required String id,
      required String name,
      required String folderName,
    })?
    discardTree,
    Future<Result<void>> Function({
      required String id,
      required String name,
      required String folderName,
    })?
    recycleTree,
  }) : _createTree = createTree ?? project_tree.writeProjectTree,
       _discardTree = discardTree ?? project_tree.discardProjectTree,
       _recycleTree = recycleTree ?? project_tree.recycleProjectTree;

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final _ProjectTreeWrite _createTree;
  final _ProjectTreeWrite _discardTree;
  final _ProjectTreeWrite _recycleTree;

  @override
  Stream<List<Project>> watchAll({bool includeArchived = false}) {
    final SimpleSelectStatement<sqlite.$ProjectsTable, sqlite.Project> query =
        _db.select(_db.projects)
          ..orderBy(projects_db.projectPinThenNewestOrder);
    if (includeArchived) {
      query.where(
        (sqlite.$ProjectsTable tbl) =>
            tbl.status.equalsValue(projects_db.ProjectStatus.deleted).not(),
      );
    } else {
      query.where(
        (sqlite.$ProjectsTable tbl) =>
            tbl.status.equalsValue(projects_db.ProjectStatus.active),
      );
    }
    return query.watch().map((List<sqlite.Project> rows) {
      return <Project>[
        for (final sqlite.Project row in rows) ProjectMapper.fromRow(row),
      ];
    });
  }

  @override
  Future<Result<Project>> create(Project project) async {
    final ValidationFailure? invalid = _validateName(project.name);
    if (invalid != null) {
      return FailureResult<Project>(invalid);
    }
    if (project.id.isNotEmpty) {
      final sqlite.Project? existing = await _byId(project.id);
      if (existing != null) {
        return const FailureResult<Project>(
          StorageFailure(
            message: 'A project with that id already exists.',
            recoveryAction: 'Open the existing project or use a new id.',
          ),
        );
      }
    }
    return _write(project);
  }

  @override
  Future<Result<Project>> createReady({
    required String name,
    String? description,
    String? organisation,
    String? sourceId,
  }) async {
    final String trimmed = name.trim();
    final ValidationFailure? invalid = _validateName(trimmed);
    if (invalid != null) {
      return FailureResult<Project>(invalid);
    }
    sqlite.Project? source;
    ProjectSettings settings = ProjectSettings.defaults;
    if (sourceId != null && sourceId.isNotEmpty) {
      source = await _byId(sourceId);
      if (source == null) {
        return const FailureResult<Project>(_missing);
      }
      settings = ProjectMapper.fromRow(source).settings;
    }
    final String id = _ids.newId();
    final String folderName;
    try {
      folderName = folderNameFor(name: trimmed, id: id);
    } on ValidationFailure catch (failure) {
      return FailureResult<Project>(failure);
    }
    final Project draft = Project(
      id: id,
      name: trimmed,
      status: ProjectStatus.active,
      folderName: folderName,
      settings: settings,
      createdAt: _clock.nowUtc(),
      updatedAt: _clock.nowUtc(),
      description: _optionalText(description),
      organisation: _optionalText(organisation),
    );
    return runInTransaction(_db, () async {
      final Result<Project> written = await _write(draft);
      switch (written) {
        case FailureResult<Project>(:final Failure failure):
          throw StorageFailure(
            message: failure.message,
            recoveryAction: failure.recoveryAction ?? 'Try again.',
          );
        case Success<Project>(:final Project value):
          if (source == null) {
            await _insertDefaultContext(value.id);
          } else {
            await _copyStructure(from: source.id, to: value.id);
          }
          final Result<void> tree = await _createTree(
            id: value.id,
            name: value.name,
            folderName: value.folderName,
          );
          switch (tree) {
            case Success<void>():
              return value;
            case FailureResult<void>(:final Failure failure):
              await _discardTree(
                id: value.id,
                name: value.name,
                folderName: value.folderName,
              );
              throw StorageFailure(
                message: failure.message,
                recoveryAction: failure.recoveryAction ?? 'Try again.',
              );
          }
      }
    });
  }

  @override
  Future<Result<void>> update(Project project) async {
    final ValidationFailure? invalid = _validateName(project.name);
    if (invalid != null) {
      return FailureResult<void>(invalid);
    }
    final sqlite.Project? existing = await _byId(project.id);
    if (existing == null) {
      return const FailureResult<void>(_missing);
    }
    final Project current = ProjectMapper.fromRow(existing);
    final Result<Project> written = await _write(
      Project(
        id: current.id,
        name: project.name,
        status: project.status,
        folderName: current.folderName,
        settings: project.settings,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
        description: project.description,
        organisation: project.organisation,
        startsOn: project.startsOn,
        endsOn: project.endsOn,
        pinnedAt: current.pinnedAt,
      ),
    );
    return written.map((Project _) {});
  }

  @override
  Stream<List<ProjectListRow>> watchList({bool includeArchived = false}) {
    final sqlite.$ProjectsTable projects = _db.projects;
    final sqlite.$RecordsTable records = _db.records;
    final Expression<int> recordCount = records.id.count();
    final Expression<int> unprocessedCount = records.id.count(
      filter: records.status.isNotIn(_closedRecordStatuses),
    );
    final Expression<DateTime> lastRecordAt = records.updatedAt.max();
    final JoinedSelectStatement<HasResultSet, dynamic> query = _db
        .select(projects)
        .join(<Join<HasResultSet, Object?>>[
          leftOuterJoin(
            records,
            records.projectId.equalsExp(projects.id),
            useColumns: false,
          ),
        ]);
    query
      ..where(
        includeArchived
            ? projects.status
                  .equalsValue(projects_db.ProjectStatus.deleted)
                  .not()
            : projects.status.equalsValue(projects_db.ProjectStatus.active),
      )
      ..addColumns(<Expression<Object>>[
        recordCount,
        unprocessedCount,
        lastRecordAt,
      ])
      ..groupBy(<Expression<Object>>[projects.id])
      ..orderBy(<OrderingTerm>[
        OrderingTerm(
          expression: projects.pinnedAt.isNotNull(),
          mode: OrderingMode.desc,
        ),
        OrderingTerm.desc(projects.updatedAt),
        OrderingTerm.asc(projects.id),
      ]);
    return query.watch().map((List<TypedResult> rows) {
      return <ProjectListRow>[
        for (final TypedResult row in rows)
          _listRow(
            row: row,
            projects: projects,
            recordCount: recordCount,
            unprocessedCount: unprocessedCount,
            lastRecordAt: lastRecordAt,
          ),
      ];
    });
  }

  @override
  Stream<ProjectHomeCounts> watchHome(String projectId) {
    return _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM records WHERE project_id = ? AND '
          "status = 'needsReview') AS review, "
          '(SELECT COUNT(*) FROM records WHERE project_id = ? AND '
          "status IN ('queued', 'processing')) AS process, "
          '(SELECT COUNT(*) FROM records WHERE project_id = ? AND '
          "status = 'approved') AS to_export, "
          '(SELECT COUNT(*) FROM exports WHERE project_id = ?) AS to_share',
          variables: <Variable<String>>[
            Variable<String>(projectId),
            Variable<String>(projectId),
            Variable<String>(projectId),
            Variable<String>(projectId),
          ],
          readsFrom: <TableInfo<dynamic, dynamic>>{_db.records, _db.exports},
        )
        .watch()
        .map(_homeCounts);
  }

  @override
  Future<Result<ProjectOwnedCounts>> ownedCounts(String id) async {
    if (await _byId(id) == null) {
      return const FailureResult<ProjectOwnedCounts>(_missing);
    }
    final int records =
        (await (_db.select(_db.records)..where(
                  (sqlite.$RecordsTable tbl) => tbl.projectId.equals(id),
                ))
                .get())
            .length;
    final int photos =
        (await (_db.select(
                  _db.photos,
                )..where((sqlite.$PhotosTable tbl) => tbl.projectId.equals(id)))
                .get())
            .length;
    final int attachments =
        (await (_db.select(_db.attachments)..where(
                  (sqlite.$AttachmentsTable tbl) => tbl.projectId.equals(id),
                ))
                .get())
            .length;
    return Success<ProjectOwnedCounts>((
      records: records,
      files: photos + attachments,
    ));
  }

  @override
  Future<Result<void>> delete(String id) async {
    final sqlite.Project? existing = await _byId(id);
    if (existing == null) {
      return const FailureResult<void>(_missing);
    }
    final Project current = ProjectMapper.fromRow(existing);
    final Result<void> marked = await runInTransaction(_db, () async {
      await _tombstoneOwned(id);
      final Result<Project> written = await _write(
        current.copyWith(status: ProjectStatus.deleted),
      );
      switch (written) {
        case FailureResult<Project>(:final Failure failure):
          throw StorageFailure(
            message: failure.message,
            recoveryAction: failure.recoveryAction ?? 'Try again.',
          );
        case Success<Project>():
          return;
      }
    });
    switch (marked) {
      case FailureResult<void>(:final Failure failure):
        return FailureResult<void>(failure);
      case Success<void>():
        break;
    }
    return _recycleTree(
      id: current.id,
      name: current.name,
      folderName: current.folderName,
    );
  }

  @override
  Future<Result<void>> setStatus(String id, ProjectStatus status) async {
    final sqlite.Project? existing = await _byId(id);
    if (existing == null) {
      return const FailureResult<void>(_missing);
    }
    final Result<Project> written = await _write(
      ProjectMapper.fromRow(existing).copyWith(status: status),
    );
    return written.map((Project _) {});
  }

  @override
  Future<Result<void>> setPinned(String id, bool pinned) async {
    final sqlite.Project? existing = await _byId(id);
    if (existing == null) {
      return const FailureResult<void>(_missing);
    }
    try {
      await (_db.update(
        _db.projects,
      )..where((sqlite.$ProjectsTable tbl) => tbl.id.equals(id))).write(
        sqlite.ProjectsCompanion(
          pinnedAt: Value<DateTime?>(pinned ? _clock.nowUtc() : null),
        ),
      );
      return const Success<void>(null);
    } on Failure catch (failure) {
      return FailureResult<void>(failure);
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }

  Future<void> _tombstoneOwned(String projectId) async {
    final List<sqlite.RecordRow> records =
        await (_db.select(_db.records)..where(
              (sqlite.$RecordsTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.Photo> photos =
        await (_db.select(_db.photos)..where(
              (sqlite.$PhotosTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.Attachment> attachments =
        await (_db.select(_db.attachments)..where(
              (sqlite.$AttachmentsTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.Template> templates =
        await (_db.select(_db.templates)..where(
              (sqlite.$TemplatesTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.ContextData> contexts =
        await (_db.select(_db.context)..where(
              (sqlite.$ContextTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.ContextStateRow> states =
        await (_db.select(_db.contextState)..where(
              (sqlite.$ContextStateTable tbl) =>
                  tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.ContextPreset> presets =
        await (_db.select(_db.contextPresets)..where(
              (sqlite.$ContextPresetsTable tbl) =>
                  tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.ReferenceDatasetRow> datasets =
        await (_db.select(_db.reference)..where(
              (sqlite.$ReferenceTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.ExportRow> exports =
        await (_db.select(_db.exports)..where(
              (sqlite.$ExportsTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.DuplicatePair> duplicates =
        await (_db.select(_db.duplicates)..where(
              (sqlite.$DuplicatesTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final List<sqlite.Variance> variances =
        await (_db.select(_db.variances)..where(
              (sqlite.$VariancesTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();

    for (final sqlite.RecordRow record in records) {
      await _mark(_db.records, record.id);
      final List<sqlite.RecordField> fields =
          await (_db.select(_db.recordFields)..where(
                (sqlite.$RecordFieldsTable tbl) =>
                    tbl.recordId.equals(record.id),
              ))
              .get();
      for (final sqlite.RecordField field in fields) {
        await _mark(_db.recordFields, field.id);
      }
      final List<sqlite.Caption> captions =
          await (_db.select(_db.captions)..where(
                (sqlite.$CaptionsTable tbl) => tbl.ownerId.equals(record.id),
              ))
              .get();
      for (final sqlite.Caption caption in captions) {
        await _mark(_db.captions, caption.id);
      }
    }
    for (final sqlite.Photo photo in photos) {
      await _mark(_db.photos, photo.id);
      final List<sqlite.Caption> captions =
          await (_db.select(_db.captions)..where(
                (sqlite.$CaptionsTable tbl) => tbl.ownerId.equals(photo.id),
              ))
              .get();
      for (final sqlite.Caption caption in captions) {
        await _mark(_db.captions, caption.id);
      }
    }
    for (final sqlite.Attachment attachment in attachments) {
      await _mark(_db.attachments, attachment.id);
    }
    for (final sqlite.Template header in templates) {
      await _mark(_db.templates, header.id);
      final List<sqlite.TemplateField> fields =
          await (_db.select(_db.templateFields)..where(
                (sqlite.$TemplateFieldsTable tbl) =>
                    tbl.templateId.equals(header.id),
              ))
              .get();
      for (final sqlite.TemplateField field in fields) {
        await _mark(_db.templateFields, field.id);
      }
      final List<sqlite.TemplateRow> rows =
          await (_db.select(_db.templateRows)..where(
                (sqlite.$TemplateRowsTable tbl) =>
                    tbl.templateId.equals(header.id),
              ))
              .get();
      for (final sqlite.TemplateRow row in rows) {
        await _mark(_db.templateRows, row.id);
      }
    }
    for (final sqlite.ContextData row in contexts) {
      await _mark(_db.context, row.id);
    }
    for (final sqlite.ContextStateRow row in states) {
      await _mark(_db.contextState, row.id);
    }
    for (final sqlite.ContextPreset row in presets) {
      await _mark(_db.contextPresets, row.id);
    }
    for (final sqlite.ReferenceDatasetRow dataset in datasets) {
      await _mark(_db.reference, dataset.id);
      final List<sqlite.ReferenceLookupRow> rows =
          await (_db.select(_db.referenceRows)..where(
                (sqlite.$ReferenceRowsTable tbl) =>
                    tbl.datasetId.equals(dataset.id),
              ))
              .get();
      for (final sqlite.ReferenceLookupRow row in rows) {
        await _mark(_db.referenceRows, row.id);
      }
    }
    for (final sqlite.ExportRow row in exports) {
      await _mark(_db.exports, row.id);
    }
    for (final sqlite.DuplicatePair row in duplicates) {
      await _mark(_db.duplicates, row.id);
    }
    for (final sqlite.Variance row in variances) {
      await _mark(_db.variances, row.id);
    }
    await _mark(_db.projects, projectId);
  }

  Future<void> _mark(TableInfo<dynamic, dynamic> table, String entityId) {
    return writeTombstone(
      _db,
      entityType: table.actualTableName,
      entityId: entityId,
      reason: _deleteReason,
      clock: _clock,
      deviceId: _deviceId,
    );
  }

  Future<Result<Project>> _write(Project project) async {
    final Result<sqlite.Project> written = await projects_db.upsertProject(
      _db,
      row: ProjectMapper.toRow(project),
      clock: _clock,
      deviceId: _deviceId,
      ids: _ids,
    );
    return written.map(ProjectMapper.fromRow);
  }

  Future<sqlite.Project?> _byId(String id) {
    if (id.isEmpty) {
      return Future<sqlite.Project?>.value();
    }
    return (_db.select(_db.projects)
          ..where((sqlite.$ProjectsTable tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> _insertDefaultContext(String projectId) async {
    final DateTime now = _clock.nowUtc();
    await _db
        .into(_db.context)
        .insert(
          sqlite.ContextCompanion.insert(
            projectId: projectId,
            level: 1,
            fieldKey: 'site',
            label: 'Site',
            createdAt: now,
            updatedAt: now,
            updatedByDevice: _deviceId,
          ),
        );
  }

  Future<void> _copyStructure({
    required String from,
    required String to,
  }) async {
    await _copyContext(from: from, to: to);
    await _copyTemplates(from: from, to: to);
    await _copyReference(from: from, to: to);
  }

  Future<void> _copyContext({required String from, required String to}) async {
    final List<sqlite.ContextData> rows = await (_db.select(
      _db.context,
    )..where((sqlite.$ContextTable tbl) => tbl.projectId.equals(from))).get();
    final DateTime now = _clock.nowUtc();
    for (final sqlite.ContextData row in rows) {
      await _db
          .into(_db.context)
          .insert(
            sqlite.ContextCompanion.insert(
              projectId: to,
              level: row.level,
              fieldKey: row.fieldKey,
              label: row.label,
              createdAt: now,
              updatedAt: now,
              updatedByDevice: _deviceId,
            ),
          );
    }
  }

  Future<void> _copyTemplates({
    required String from,
    required String to,
  }) async {
    final List<sqlite.Template> headers = await (_db.select(
      _db.templates,
    )..where((sqlite.$TemplatesTable tbl) => tbl.projectId.equals(from))).get();
    for (final sqlite.Template header in headers) {
      final String newId = _ids.newId();
      _throwIfFailed(
        await upsertTemplate(
          _db,
          row: sqlite.TemplatesCompanion(
            id: Value<String>(newId),
            projectId: Value<String>(to),
            name: Value<String>(header.name),
            kind: Value<String>(header.kind),
            source: Value<String>(header.source),
            sourceFilePath: Value<String?>(header.sourceFilePath),
            sheetName: Value<String?>(header.sheetName),
            headerRow: Value<int?>(header.headerRow),
            identityFields: Value<String>(header.identityFields),
            detection: Value<String>(header.detection),
            version: Value<int>(header.version),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
      await _copyTemplateFields(from: header.id, to: newId);
      await _copyTemplateRows(from: header.id, to: newId);
    }
  }

  Future<void> _copyTemplateFields({
    required String from,
    required String to,
  }) async {
    final List<sqlite.TemplateField> fields =
        await (_db.select(_db.templateFields)..where(
              (sqlite.$TemplateFieldsTable tbl) => tbl.templateId.equals(from),
            ))
            .get();
    for (final sqlite.TemplateField field in fields) {
      _throwIfFailed(
        await upsertTemplateField(
          _db,
          row: sqlite.TemplateFieldsCompanion(
            templateId: Value<String>(to),
            fieldKey: Value<String>(field.fieldKey),
            label: Value<String>(field.label),
            type: Value<String>(field.type),
            outputColumn: Value<String?>(field.outputColumn),
            isRequired: Value<bool>(field.isRequired),
            inputMode: Value<String>(field.inputMode),
            stickable: Value<bool>(field.stickable),
            contextLevel: Value<int?>(field.contextLevel),
            autoFill: Value<bool>(field.autoFill),
            defaultValue: Value<String?>(field.defaultValue),
            options: Value<String>(field.options),
            unit: Value<String?>(field.unit),
            validation: Value<String>(field.validation),
            lookup: Value<String>(field.lookup),
            refine: Value<bool>(field.refine),
            sortOrder: Value<int>(field.sortOrder),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
    }
  }

  Future<void> _copyTemplateRows({
    required String from,
    required String to,
  }) async {
    final List<sqlite.TemplateRow> rows =
        await (_db.select(_db.templateRows)..where(
              (sqlite.$TemplateRowsTable tbl) => tbl.templateId.equals(from),
            ))
            .get();
    for (final sqlite.TemplateRow row in rows) {
      _throwIfFailed(
        await upsertTemplateRow(
          _db,
          row: sqlite.TemplateRowsCompanion(
            templateId: Value<String>(to),
            outputRowNumber: Value<int>(row.outputRowNumber),
            identifier: Value<String>(row.identifier),
            label: Value<String>(row.label),
            aliases: Value<String>(row.aliases),
            metadata: Value<String>(row.metadata),
            foundStatus: Value<String>(row.foundStatus),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
    }
  }

  Future<void> _copyReference({
    required String from,
    required String to,
  }) async {
    final List<sqlite.ReferenceDatasetRow> datasets =
        await (_db.select(_db.reference)..where(
              (sqlite.$ReferenceTable tbl) =>
                  tbl.projectId.equals(from) &
                  tbl.scope.equalsValue(ReferenceScope.project),
            ))
            .get();
    for (final sqlite.ReferenceDatasetRow dataset in datasets) {
      final String newId = _ids.newId();
      _throwIfFailed(
        await upsertReferenceDataset(
          _db,
          row: sqlite.ReferenceCompanion(
            id: Value<String>(newId),
            name: Value<String>(dataset.name),
            scope: const Value<ReferenceScope>(ReferenceScope.project),
            projectId: Value<String>(to),
            keyColumn: Value<String>(dataset.keyColumn),
            columns: Value<String>(dataset.columns),
            sourceFile: Value<String>(dataset.sourceFile),
            importedAt: Value<DateTime>(dataset.importedAt),
            rowCount: Value<int>(dataset.rowCount),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
      final List<sqlite.ReferenceLookupRow> rows =
          await (_db.select(_db.referenceRows)..where(
                (sqlite.$ReferenceRowsTable tbl) =>
                    tbl.datasetId.equals(dataset.id),
              ))
              .get();
      for (final sqlite.ReferenceLookupRow row in rows) {
        _throwIfFailed(
          await upsertReferenceRow(
            _db,
            row: sqlite.ReferenceRowsCompanion(
              datasetId: Value<String>(newId),
              keyValue: Value<String>(row.keyValue),
              values: Value<String>(row.values),
            ),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          ),
        );
      }
    }
  }
}

/// The project store. Defaults to an empty in-memory stand-in so
/// suites never open Drift (FE-TEST-03). [main] replaces this with
/// [ProjectRepositoryImpl] against the on-disk database.
final Provider<ProjectRepository> projectRepositoryProvider =
    Provider<ProjectRepository>((Ref _) {
      return _EmptyProjectRepository();
    });

/// Empty watch streams and failing writes. Production never keeps this;
/// tests that need rows inject [FakeProjectRepository] or an in-memory
/// [ProjectRepositoryImpl].
final class _EmptyProjectRepository implements ProjectRepository {
  @override
  Stream<List<Project>> watchAll({bool includeArchived = false}) {
    return Stream<List<Project>>.value(const <Project>[]);
  }

  @override
  Stream<List<ProjectListRow>> watchList({bool includeArchived = false}) {
    return Stream<List<ProjectListRow>>.value(const <ProjectListRow>[]);
  }

  @override
  Stream<ProjectHomeCounts> watchHome(String projectId) {
    return Stream<ProjectHomeCounts>.value(emptyProjectHomeCounts);
  }

  @override
  Future<Result<Project>> create(Project project) async {
    return const FailureResult<Project>(_missing);
  }

  @override
  Future<Result<Project>> createReady({
    required String name,
    String? description,
    String? organisation,
    String? sourceId,
  }) async {
    return const FailureResult<Project>(_missing);
  }

  @override
  Future<Result<void>> update(Project project) async {
    return const FailureResult<void>(_missing);
  }

  @override
  Future<Result<void>> setStatus(String id, ProjectStatus status) async {
    return const FailureResult<void>(_missing);
  }

  @override
  Future<Result<void>> setPinned(String id, bool pinned) async {
    return const FailureResult<void>(_missing);
  }

  @override
  Future<Result<void>> delete(String id) async {
    return const FailureResult<void>(_missing);
  }

  @override
  Future<Result<ProjectOwnedCounts>> ownedCounts(String id) async {
    return const FailureResult<ProjectOwnedCounts>(_missing);
  }
}

ProjectListRow _listRow({
  required TypedResult row,
  required sqlite.$ProjectsTable projects,
  required Expression<int> recordCount,
  required Expression<int> unprocessedCount,
  required Expression<DateTime> lastRecordAt,
}) {
  final Project project = ProjectMapper.fromRow(row.readTable(projects));
  final DateTime? fromRecords = row.read<DateTime>(lastRecordAt);
  return (
    project: project,
    recordCount: row.read<int>(recordCount) ?? 0,
    unprocessedCount: row.read<int>(unprocessedCount) ?? 0,
    lastWorkedAt: _later(project.updatedAt, fromRecords),
  );
}

ProjectHomeCounts _homeCounts(List<QueryRow> rows) {
  final QueryRow row = rows.single;
  return (
    review: row.read<int>('review'),
    process: row.read<int>('process'),
    toExport: row.read<int>('to_export'),
    toShare: row.read<int>('to_share'),
  );
}

DateTime _later(DateTime project, DateTime? records) {
  if (records == null || !records.isAfter(project)) {
    return project;
  }
  return records;
}

const List<String> _closedRecordStatuses = <String>[
  'approved',
  'archived',
  'deleted',
];

const String _deleteReason = 'Project deleted';

typedef _ProjectTreeWrite =
    Future<Result<void>> Function({
      required String id,
      required String name,
      required String folderName,
    });

void _throwIfFailed<T>(Result<T> result) {
  switch (result) {
    case FailureResult<T>(:final Failure failure):
      throw StorageFailure(
        message: failure.message,
        recoveryAction: failure.recoveryAction ?? 'Try again.',
      );
    case Success<T>():
      return;
  }
}

String? _optionalText(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return raw.trim();
}

ValidationFailure? _validateName(String name) {
  if (name.trim().isEmpty) {
    return const ValidationFailure(
      message: 'A project needs a name.',
      recoveryAction: 'Enter a name and save again.',
    );
  }
  return null;
}

const StorageFailure _missing = StorageFailure(
  message: 'That row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/projects.dart' as projects_db;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/project_repository.dart';
import 'project_mapper.dart';

/// Drift-backed [ProjectRepository]. The only feature file besides the
/// mapper that imports both the table and the domain.
final class ProjectRepositoryImpl implements ProjectRepository {
  /// Opens against [_db], stamping writes from [_clock], [_deviceId] and
  /// [_ids].
  ProjectRepositoryImpl({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
  });

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  @override
  Stream<List<Project>> watchAll({bool includeArchived = false}) {
    final SimpleSelectStatement<sqlite.$ProjectsTable, sqlite.Project> query =
        _db.select(_db.projects)
          ..orderBy(<OrderClauseGenerator<sqlite.$ProjectsTable>>[
            (sqlite.$ProjectsTable tbl) => OrderingTerm.desc(tbl.updatedAt),
          ]);
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
      ),
    );
    return written.map((Project _) {});
  }

  @override
  Stream<List<ProjectListRow>> watchList() {
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
      ..where(projects.status.equalsValue(projects_db.ProjectStatus.active))
      ..addColumns(<Expression<Object>>[
        recordCount,
        unprocessedCount,
        lastRecordAt,
      ])
      ..groupBy(<Expression<Object>>[projects.id]);
    return query.watch().map((List<TypedResult> rows) {
      final List<ProjectListRow> list = <ProjectListRow>[
        for (final TypedResult row in rows)
          _listRow(
            row: row,
            projects: projects,
            recordCount: recordCount,
            unprocessedCount: unprocessedCount,
            lastRecordAt: lastRecordAt,
          ),
      ];
      list.sort(_byLastWorked);
      return list;
    });
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
  Stream<List<ProjectListRow>> watchList() {
    return Stream<List<ProjectListRow>>.value(const <ProjectListRow>[]);
  }

  @override
  Future<Result<Project>> create(Project project) async {
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

DateTime _later(DateTime project, DateTime? records) {
  if (records == null || !records.isAfter(project)) {
    return project;
  }
  return records;
}

int _byLastWorked(ProjectListRow a, ProjectListRow b) {
  final int byWork = b.lastWorkedAt.compareTo(a.lastWorkedAt);
  if (byWork != 0) {
    return byWork;
  }
  return b.project.updatedAt.compareTo(a.project.updatedAt);
}

const List<String> _closedRecordStatuses = <String>[
  'approved',
  'archived',
  'deleted',
];

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

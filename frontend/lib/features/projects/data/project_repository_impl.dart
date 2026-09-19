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

/// The project store. Tests replace this so screens never open a file.
final Provider<ProjectRepository> projectRepositoryProvider =
    Provider<ProjectRepository>((Ref ref) {
      final sqlite.AppDatabase db = sqlite.AppDatabase.memory();
      ref.onDispose(db.close);
      const Clock clock = SystemClock();
      return ProjectRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'local',
        ids: UuidV7Service(clock),
      );
    });

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

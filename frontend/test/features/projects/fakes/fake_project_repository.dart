import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';

/// In-memory [ProjectRepository] for feature tests that must not open a
/// database (FE-STATE-10).
final class FakeProjectRepository implements ProjectRepository {
  final Map<String, Project> _rows = <String, Project>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<Project>> watchAll({bool includeArchived = false}) {
    return _watch(() => _visible(includeArchived));
  }

  @override
  Future<Result<Project>> create(Project project) async {
    final ValidationFailure? invalid = _validateName(project.name);
    if (invalid != null) {
      return FailureResult<Project>(invalid);
    }
    if (project.id.isEmpty) {
      return const FailureResult<Project>(_missing);
    }
    if (_rows.containsKey(project.id)) {
      return const FailureResult<Project>(
        StorageFailure(
          message: 'A project with that id already exists.',
          recoveryAction: 'Open the existing project or use a new id.',
        ),
      );
    }
    _rows[project.id] = project;
    _emit();
    return Success<Project>(project);
  }

  @override
  Future<Result<void>> update(Project project) async {
    final ValidationFailure? invalid = _validateName(project.name);
    if (invalid != null) {
      return FailureResult<void>(invalid);
    }
    final Project? current = _rows[project.id];
    if (current == null) {
      return const FailureResult<void>(_missing);
    }
    _rows[project.id] = Project(
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
    );
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setStatus(String id, ProjectStatus status) async {
    final Project? current = _rows[id];
    if (current == null) {
      return const FailureResult<void>(_missing);
    }
    _rows[id] = current.copyWith(status: status);
    _emit();
    return const Success<void>(null);
  }

  List<Project> _visible(bool includeArchived) {
    final List<Project> rows = _rows.values.where((Project row) {
      if (row.status == ProjectStatus.deleted) {
        return false;
      }
      if (row.status == ProjectStatus.archived) {
        return includeArchived;
      }
      return true;
    }).toList();
    rows.sort((Project a, Project b) => b.updatedAt.compareTo(a.updatedAt));
    return rows;
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Stream<List<T>> _watch<T>(List<T> Function() snapshot) {
    return Stream<List<T>>.multi((MultiStreamController<List<T>> listener) {
      listener.add(snapshot());
      final StreamSubscription<void> sub = _changes.stream.listen((_) {
        listener.add(snapshot());
      });
      listener.onCancel = sub.cancel;
    });
  }
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

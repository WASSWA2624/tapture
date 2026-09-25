import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';

/// In-memory [ProjectRepository] for feature tests that must not open a
/// database (FE-STATE-10).
final class FakeProjectRepository implements ProjectRepository {
  final Map<String, Project> _rows = <String, Project>{};
  final Map<String, _ListCounts> _counts = <String, _ListCounts>{};
  final Map<String, ProjectHomeCounts> _home = <String, ProjectHomeCounts>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _created = 0;

  /// When set, [createReady] returns this failure instead of writing.
  Failure? createFailure;

  /// When set, [update] returns this failure instead of writing.
  Failure? updateFailure;

  /// Tombstones [delete] wrote. Widget tests read this instead of
  /// opening a database.
  final List<({String entityType, String entityId})> tombstones =
      <({String entityType, String entityId})>[];

  /// Folder names [delete] moved into the recycle area.
  final List<String> recycled = <String>[];

  final Map<String, int> _files = <String, int>{};

  /// How many rows are stored. Widget tests read this instead of
  /// awaiting [watchAll].
  int get count => _rows.length;

  /// Stored rows. Widget tests read this instead of awaiting [watchAll].
  List<Project> get stored => List<Project>.unmodifiable(_rows.values);

  /// Seeds the counts [watchList] returns for [id]. Tests that care
  /// about the landing row call this instead of opening a database.
  void seedCounts(
    String id, {
    int recordCount = 0,
    int unprocessedCount = 0,
    DateTime? lastWorkedAt,
  }) {
    _counts[id] = (
      recordCount: recordCount,
      unprocessedCount: unprocessedCount,
      lastWorkedAt: lastWorkedAt,
    );
    _emit();
  }

  /// Seeds the file count [ownedCounts] returns for [id].
  void seedFiles(String id, {int files = 0}) {
    _files[id] = files;
  }

  final Map<String, List<ProjectRecordRow>> _records =
      <String, List<ProjectRecordRow>>{};

  /// Seeds rows [watchRecords] returns for [id].
  void seedRecords(String id, List<ProjectRecordRow> rows) {
    _records[id] = List<ProjectRecordRow>.of(rows);
    _emit();
  }

  void seedHomeCounts(
    String id, {
    int review = 0,
    int process = 0,
    int toExport = 0,
    int toShare = 0,
  }) {
    _home[id] = (
      review: review,
      process: process,
      toExport: toExport,
      toShare: toShare,
    );
    _emit();
  }

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<Project>> watchAll({bool includeArchived = false}) {
    return _watch(() => _visible(includeArchived));
  }

  @override
  Stream<List<ProjectListRow>> watchList({bool includeArchived = false}) {
    return _watch(() => _listSnapshot(includeArchived));
  }

  @override
  Stream<ProjectHomeCounts> watchHome(String projectId) {
    return _watch(() => _home[projectId] ?? emptyProjectHomeCounts);
  }

  @override
  Stream<List<ProjectRecordRow>> watchRecords(
    String projectId, {
    required List<String> statuses,
  }) {
    return _watch(() {
      final List<ProjectRecordRow> rows =
          _records[projectId] ?? const <ProjectRecordRow>[];
      if (statuses.isEmpty) {
        return const <ProjectRecordRow>[];
      }
      return <ProjectRecordRow>[
        for (final ProjectRecordRow row in rows)
          if (statuses.contains(row.status)) row,
      ];
    });
  }

  @override
  Future<Result<void>> archiveRecord(String recordId) async {
    for (final MapEntry<String, List<ProjectRecordRow>> entry
        in _records.entries) {
      final int index = entry.value.indexWhere(
        (ProjectRecordRow row) => row.id == recordId,
      );
      if (index < 0) {
        continue;
      }
      final ProjectRecordRow current = entry.value[index];
      entry.value[index] = (
        id: current.id,
        templateId: current.templateId,
        status: 'archived',
        photoCount: current.photoCount,
        thumbPath: current.thumbPath,
        fields: current.fields,
      );
      _emit();
      return const Success<void>(null);
    }
    return const FailureResult<void>(
      StorageFailure(
        message: 'That record is not on this device.',
        recoveryAction: 'Go back and try again.',
      ),
    );
  }

  @override
  Future<Result<void>> refineRecordField({
    required String recordId,
    required String fieldKey,
    required String value,
  }) async {
    final Failure? failure = fieldWriteFailure;
    if (failure != null) {
      return FailureResult<void>(failure);
    }
    for (final List<ProjectRecordRow> rows in _records.values) {
      final int index = rows.indexWhere(
        (ProjectRecordRow row) => row.id == recordId,
      );
      if (index < 0) {
        continue;
      }
      final ProjectRecordRow current = rows[index];
      rows[index] = (
        id: current.id,
        templateId: current.templateId,
        status: current.status,
        photoCount: current.photoCount,
        thumbPath: current.thumbPath,
        fields: <ProjectRecordFieldValue>[
          for (final ProjectRecordFieldValue field in current.fields)
            if (field.fieldKey == fieldKey)
              (
                fieldKey: field.fieldKey,
                raw: field.raw,
                refined: value,
                approved: field.approved,
              )
            else
              field,
        ],
      );
      _emit();
      return const Success<void>(null);
    }
    return const FailureResult<void>(
      StorageFailure(
        message: 'That record is not on this device.',
        recoveryAction: 'Go back and try again.',
      ),
    );
  }

  /// Fields [addRecordField] stored, keyed `recordId/fieldKey`.
  final Map<String, String> addedFields = <String, String>{};

  /// When set, [addRecordField] and [refineRecordField] fail with it.
  Failure? fieldWriteFailure;

  @override
  Future<Result<void>> addRecordField({
    required String recordId,
    required String fieldKey,
    required String value,
  }) async {
    final Failure? failure = fieldWriteFailure;
    if (failure != null) {
      return FailureResult<void>(failure);
    }
    for (final List<ProjectRecordRow> rows in _records.values) {
      final int index = rows.indexWhere(
        (ProjectRecordRow row) => row.id == recordId,
      );
      if (index < 0) {
        continue;
      }
      final ProjectRecordRow current = rows[index];
      addedFields['$recordId/$fieldKey'] = value;
      rows[index] = (
        id: current.id,
        templateId: current.templateId,
        status: current.status,
        photoCount: current.photoCount,
        thumbPath: current.thumbPath,
        fields: <ProjectRecordFieldValue>[
          ...current.fields,
          (fieldKey: fieldKey, raw: value, refined: '', approved: ''),
        ],
      );
      _emit();
      return const Success<void>(null);
    }
    return const FailureResult<void>(
      StorageFailure(
        message: 'That record is not on this device.',
        recoveryAction: 'Go back and try again.',
      ),
    );
  }

  List<ProjectListRow> _listSnapshot(bool includeArchived) {
    final List<ProjectListRow> rows = <ProjectListRow>[
      for (final Project project in _visible(includeArchived))
        (
          project: project,
          recordCount: _counts[project.id]?.recordCount ?? 0,
          unprocessedCount: _counts[project.id]?.unprocessedCount ?? 0,
          lastWorkedAt: _counts[project.id]?.lastWorkedAt ?? project.updatedAt,
        ),
    ];
    return rows;
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
  Future<Result<Project>> createReady({
    required String name,
    String? description,
    String? organisation,
    String? sourceId,
  }) async {
    final Failure? forced = createFailure;
    if (forced != null) {
      return FailureResult<Project>(forced);
    }
    final ValidationFailure? invalid = _validateName(name);
    if (invalid != null) {
      return FailureResult<Project>(invalid);
    }
    ProjectSettings settings = const ProjectSettings();
    if (sourceId != null && sourceId.isNotEmpty) {
      final Project? source = _rows[sourceId];
      if (source == null) {
        return const FailureResult<Project>(_missing);
      }
      settings = source.settings;
    }
    _created += 1;
    final DateTime at = DateTime.utc(2026, 9, 17, 8);
    final Project project = Project(
      id: 'created-$_created',
      name: name.trim(),
      status: ProjectStatus.active,
      folderName: 'created-$_created',
      settings: settings,
      createdAt: at,
      updatedAt: at,
      description: _optionalText(description),
      organisation: _optionalText(organisation),
    );
    _rows[project.id] = project;
    _emit();
    return Success<Project>(project);
  }

  @override
  Future<Result<void>> update(Project project) async {
    final Failure? forced = updateFailure;
    if (forced != null) {
      return FailureResult<void>(forced);
    }
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
      pinnedAt: current.pinnedAt,
    );
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<ProjectOwnedCounts>> ownedCounts(String id) async {
    if (!_rows.containsKey(id)) {
      return const FailureResult<ProjectOwnedCounts>(_missing);
    }
    return Success<ProjectOwnedCounts>((
      records: _counts[id]?.recordCount ?? 0,
      files: _files[id] ?? 0,
    ));
  }

  @override
  Future<Result<void>> delete(String id) async {
    final Project? current = _rows[id];
    if (current == null) {
      return const FailureResult<void>(_missing);
    }
    tombstones.add((entityType: 'projects', entityId: id));
    recycled.add(current.folderName);
    _rows[id] = current.copyWith(status: ProjectStatus.deleted);
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

  @override
  Future<Result<void>> setPinned(String id, bool pinned) async {
    final Project? current = _rows[id];
    if (current == null) {
      return const FailureResult<void>(_missing);
    }
    _rows[id] = Project(
      id: current.id,
      name: current.name,
      status: current.status,
      folderName: current.folderName,
      settings: current.settings,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      description: current.description,
      organisation: current.organisation,
      startsOn: current.startsOn,
      endsOn: current.endsOn,
      pinnedAt: pinned ? DateTime.utc(2026, 9, 17, 12) : null,
    );
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
    rows.sort(_byPinThenNewest);
    return rows;
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Stream<T> _watch<T>(T Function() snapshot) {
    return Stream<T>.multi((MultiStreamController<T> listener) {
      listener.add(snapshot());
      final StreamSubscription<void> sub = _changes.stream.listen((_) {
        listener.add(snapshot());
      });
      listener.onCancel = sub.cancel;
    });
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

typedef _ListCounts = ({
  int recordCount,
  int unprocessedCount,
  DateTime? lastWorkedAt,
});

int _byPinThenNewest(Project a, Project b) {
  final bool aPinned = a.pinnedAt != null;
  final bool bPinned = b.pinnedAt != null;
  if (aPinned != bPinned) {
    return aPinned ? -1 : 1;
  }
  final int byUpdated = b.updatedAt.compareTo(a.updatedAt);
  if (byUpdated != 0) {
    return byUpdated;
  }
  return a.id.compareTo(b.id);
}

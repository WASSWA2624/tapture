import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';

/// In-memory [ExportRepository] for feature tests that must not open a database.
final class FakeExportRepository implements ExportRepository {
  final Map<String, ExportEntry> _rows = <String, ExportEntry>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<ExportEntry>> watchByProject(String projectId) {
    return _watch(() => _ownedBy(projectId));
  }

  @override
  Future<Result<ExportEntry?>> byId(String id) async {
    return Success<ExportEntry?>(_rows[id]);
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
    final String id = entry.id.isEmpty ? 'export-${_next++}' : entry.id;
    final ExportEntry stored = (
      id: id,
      projectId: entry.projectId,
      version: entry.version,
      status: entry.status,
    );
    _rows[id] = stored;
    _emit();
    return Success<ExportEntry>(stored);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    if (id.isEmpty) {
      return const FailureResult<void>(_missing);
    }
    if (reason.isEmpty) {
      return const FailureResult<void>(_needsReason);
    }
    if (!_rows.containsKey(id)) {
      return const FailureResult<void>(_missing);
    }
    _rows.remove(id);
    _emit();
    return const Success<void>(null);
  }

  List<ExportEntry> _ownedBy(String projectId) {
    return _rows.values
        .where((ExportEntry row) => row.projectId == projectId)
        .toList();
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

const StorageFailure _missing = StorageFailure(
  message: 'That row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _needsReason = StorageFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why this row should be removed, then try again.',
);

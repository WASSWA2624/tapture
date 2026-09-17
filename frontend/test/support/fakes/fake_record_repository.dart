import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/records/domain/record_repository.dart';

/// In-memory [RecordRepository] for feature tests that must not open a database.
final class FakeRecordRepository implements RecordRepository {
  final Map<String, RecordDetail> _rows = <String, RecordDetail>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<RecordSummary>> watchByProject(
    String projectId,
    RecordFilter filter,
  ) {
    return _watch(() => _summaries(projectId, filter));
  }

  @override
  Future<Result<RecordDetail?>> byId(String id) async {
    return Success<RecordDetail?>(_rows[id]);
  }

  @override
  Future<Result<RecordDetail>> save(RecordDraft draft) async {
    if (draft.projectId.isEmpty || draft.templateId.isEmpty) {
      return const FailureResult<RecordDetail>(
        ValidationFailure(
          message: 'A record needs a project and a template.',
          recoveryAction: 'Choose a project and template, then save again.',
        ),
      );
    }
    final String? draftId = draft.id;
    final String id = draftId == null || draftId.isEmpty
        ? 'record-${_next++}'
        : draftId;
    final RecordDetail? existing = _rows[id];
    final RecordDetail stored = (
      id: id,
      projectId: draft.projectId,
      templateId: draft.templateId,
      status: existing?.status ?? 'captured',
      fields: Map<String, String>.of(draft.fields),
    );
    _rows[id] = stored;
    _emit();
    return Success<RecordDetail>(stored);
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

  List<RecordSummary> _summaries(String projectId, RecordFilter filter) {
    return _rows.values
        .where((RecordDetail row) {
          if (row.projectId != projectId) {
            return false;
          }
          final String? status = filter.status;
          return status == null || row.status == status;
        })
        .map(
          (RecordDetail row) =>
              (id: row.id, projectId: row.projectId, status: row.status),
        )
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

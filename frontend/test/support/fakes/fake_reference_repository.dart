import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/reference/domain/reference_repository.dart';

/// In-memory [ReferenceRepository] for feature tests that must not open a
/// database.
final class FakeReferenceRepository implements ReferenceRepository {
  final Map<String, ReferenceDataset> _rows = <String, ReferenceDataset>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<ReferenceDataset>> watchAll() {
    return _watch(() => _rows.values.toList());
  }

  @override
  Future<Result<ReferenceDataset?>> byId(String id) async {
    return Success<ReferenceDataset?>(_rows[id]);
  }

  @override
  Future<Result<ReferenceDataset>> save(ReferenceDataset dataset) async {
    if (dataset.name.isEmpty || dataset.keyColumn.isEmpty) {
      return const FailureResult<ReferenceDataset>(
        ValidationFailure(
          message: 'A dataset needs a name and a key column.',
          recoveryAction: 'Fill those fields and save again.',
        ),
      );
    }
    final String id = dataset.id.isEmpty ? 'dataset-${_next++}' : dataset.id;
    final ReferenceDataset stored = (
      id: id,
      name: dataset.name,
      keyColumn: dataset.keyColumn,
      rowCount: dataset.rowCount,
    );
    _rows[id] = stored;
    _emit();
    return Success<ReferenceDataset>(stored);
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

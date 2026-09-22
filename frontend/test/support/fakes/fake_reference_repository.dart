import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/reference/domain/reference_dataset.dart';
import 'package:tapture/features/reference/domain/reference_repository.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';

/// In-memory [ReferenceRepository] for feature tests that must not open a
/// database.
final class FakeReferenceRepository implements ReferenceRepository {
  final Map<String, ReferenceDataset> _datasets = <String, ReferenceDataset>{};
  final Map<String, ReferenceRow> _rows = <String, ReferenceRow>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<ReferenceDataset>> watchAll() {
    return _watch(() => _datasets.values.toList());
  }

  @override
  Stream<List<ReferenceDataset>> watchByProject(String projectId) {
    return _watch(() {
      return <ReferenceDataset>[
        for (final ReferenceDataset dataset in _datasets.values)
          if (dataset.projectId == null ||
              dataset.projectId!.isEmpty ||
              dataset.projectId == projectId)
            dataset,
      ];
    });
  }

  @override
  Future<Result<ReferenceDataset?>> byId(String id) async {
    return Success<ReferenceDataset?>(_datasets[id]);
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
    final ReferenceDataset stored = dataset.copyWith(id: id);
    _datasets[id] = stored;
    _emit();
    return Success<ReferenceDataset>(stored);
  }

  @override
  Future<Result<ReferenceDataset>> importDataset({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  }) async {
    if (!dataset.duplicatesAllowed) {
      final Set<String> seen = <String>{};
      for (final ReferenceRow row in rows) {
        if (!seen.add(row.key)) {
          return const FailureResult<ReferenceDataset>(
            ValidationFailure(
              message: 'That key column has duplicate values.',
              recoveryAction:
                  'Pick another key column, or confirm duplicates are expected.',
            ),
          );
        }
      }
    }
    final Result<ReferenceDataset> header = await save(
      dataset.copyWith(rowCount: rows.length),
    );
    switch (header) {
      case FailureResult<ReferenceDataset>(:final Failure failure):
        return FailureResult<ReferenceDataset>(failure);
      case Success<ReferenceDataset>(:final ReferenceDataset value):
        _rows.removeWhere((_, ReferenceRow row) => row.datasetId == value.id);
        for (final ReferenceRow row in rows) {
          final String id = row.id.isEmpty ? 'row-${_next++}' : row.id;
          _rows[id] = row.copyWith(id: id, datasetId: value.id);
        }
        _emit();
        return Success<ReferenceDataset>(value);
    }
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    if (id.isEmpty) {
      return const FailureResult<void>(_missing);
    }
    if (reason.isEmpty) {
      return const FailureResult<void>(_needsReason);
    }
    if (!_datasets.containsKey(id)) {
      return const FailureResult<void>(_missing);
    }
    _datasets.remove(id);
    _rows.removeWhere((_, ReferenceRow row) => row.datasetId == id);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<List<ReferenceRow>>> pageRows({
    required String datasetId,
    required int offset,
    required int limit,
    String query = '',
  }) async {
    final String needle = query.trim().toLowerCase();
    final List<ReferenceRow> rows = <ReferenceRow>[
      for (final ReferenceRow row in _rows.values)
        if (row.datasetId == datasetId &&
            (needle.isEmpty ||
                row.key.toLowerCase().contains(needle) ||
                row.values.values.any(
                  (String v) => v.toLowerCase().contains(needle),
                )))
          row,
    ]..sort((ReferenceRow a, ReferenceRow b) => a.key.compareTo(b.key));
    final int start = offset < 0 ? 0 : offset;
    if (start >= rows.length) {
      return const Success<List<ReferenceRow>>(<ReferenceRow>[]);
    }
    final int end = start + limit > rows.length ? rows.length : start + limit;
    return Success<List<ReferenceRow>>(rows.sublist(start, end));
  }

  @override
  Future<Result<ReferenceRow?>> rowById(String id) async {
    return Success<ReferenceRow?>(_rows[id]);
  }

  @override
  Future<Result<ReferenceRow>> saveRow(
    ReferenceRow row, {
    Map<String, String>? previousValues,
  }) async {
    if (row.datasetId.isEmpty || row.key.trim().isEmpty) {
      return const FailureResult<ReferenceRow>(
        ValidationFailure(
          message: 'A row needs a dataset and a key.',
          recoveryAction: 'Fill those fields and save again.',
        ),
      );
    }
    final String id = row.id.isEmpty ? 'row-${_next++}' : row.id;
    final ReferenceRow stored = row.copyWith(id: id);
    _rows[id] = stored;
    final ReferenceDataset? dataset = _datasets[row.datasetId];
    if (dataset != null) {
      final int count = _rows.values
          .where((ReferenceRow r) => r.datasetId == row.datasetId)
          .length;
      _datasets[row.datasetId] = dataset.copyWith(rowCount: count);
    }
    _emit();
    return Success<ReferenceRow>(stored);
  }

  @override
  Future<Result<ReferenceRow?>> lookupByKey({
    required String datasetId,
    required String keyValue,
  }) async {
    for (final ReferenceRow row in _rows.values) {
      if (row.datasetId == datasetId && row.key == keyValue) {
        return Success<ReferenceRow?>(row);
      }
    }
    return const Success<ReferenceRow?>(null);
  }

  @override
  Future<Result<List<ReferenceRow>>> lookupByNormalised({
    required String datasetId,
    required String query,
  }) async {
    final String folded = query.trim().toLowerCase();
    return Success<List<ReferenceRow>>(<ReferenceRow>[
      for (final ReferenceRow row in _rows.values)
        if (row.datasetId == datasetId &&
            row.key.trim().toLowerCase() == folded)
          row,
    ]);
  }

  @override
  Future<Result<List<ReferenceRow>>> allRows(String datasetId) {
    return pageRows(datasetId: datasetId, offset: 0, limit: 1 << 20);
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

import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';

/// In-memory [ProcessingRepository] for feature tests that must not open a
/// database.
final class FakeProcessingRepository implements ProcessingRepository {
  final Map<String, ProcessingJob> _rows = <String, ProcessingJob>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<ProcessingJob>> watchAll() {
    return _watch(() => _rows.values.toList());
  }

  @override
  Future<Result<ProcessingJob?>> byId(String id) async {
    return Success<ProcessingJob?>(_rows[id]);
  }

  @override
  Future<Result<ProcessingJob>> save(ProcessingJob job) async {
    if (job.recordId.isEmpty) {
      return const FailureResult<ProcessingJob>(
        ValidationFailure(
          message: 'A job needs a record.',
          recoveryAction: 'Open a record and queue it again.',
        ),
      );
    }
    final String id = job.id.isEmpty ? 'job-${_next++}' : job.id;
    final ProcessingJob stored = (
      id: id,
      recordId: job.recordId,
      stage: job.stage,
      attemptCount: job.attemptCount,
    );
    _rows[id] = stored;
    _emit();
    return Success<ProcessingJob>(stored);
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

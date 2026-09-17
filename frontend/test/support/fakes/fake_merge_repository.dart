import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/merge/domain/merge_repository.dart';

/// In-memory [MergeRepository] for feature tests that must not open a database.
final class FakeMergeRepository implements MergeRepository {
  final Map<String, MergeSession> _rows = <String, MergeSession>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<MergeSession>> watchAll() {
    return _watch(() => _rows.values.toList());
  }

  @override
  Future<Result<MergeSession?>> byId(String id) async {
    return Success<MergeSession?>(_rows[id]);
  }

  @override
  Future<Result<MergeSession>> save(MergeSession session) async {
    if (session.bundleName.isEmpty) {
      return const FailureResult<MergeSession>(
        ValidationFailure(
          message: 'A merge needs a bundle name.',
          recoveryAction: 'Choose a bundle and start again.',
        ),
      );
    }
    final String id = session.id.isEmpty ? 'merge-${_next++}' : session.id;
    final MergeSession stored = (
      id: id,
      bundleName: session.bundleName,
      status: session.status,
    );
    _rows[id] = stored;
    _emit();
    return Success<MergeSession>(stored);
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

import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

/// In-memory [PhotoRepository] for feature tests that must not open a database.
final class FakePhotoRepository implements PhotoRepository {
  final Map<String, PhotoAsset> _rows = <String, PhotoAsset>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<PhotoAsset>> watchByRecord(String recordId) {
    return _watch(() => _filedOn(recordId));
  }

  @override
  Future<Result<PhotoAsset?>> byId(String id) async {
    return Success<PhotoAsset?>(_rows[id]);
  }

  @override
  Future<Result<PhotoAsset>> save(PhotoAsset photo) async {
    if (photo.projectId.isEmpty || photo.relativePath.isEmpty) {
      return const FailureResult<PhotoAsset>(
        ValidationFailure(
          message: 'A photo needs a project and a path inside it.',
          recoveryAction:
              'Save the file under the project folder and try again.',
        ),
      );
    }
    final String id = photo.id.isEmpty ? 'photo-${_next++}' : photo.id;
    final PhotoAsset stored = (
      id: id,
      projectId: photo.projectId,
      recordId: photo.recordId,
      relativePath: photo.relativePath,
      sha256: photo.sha256,
    );
    _rows[id] = stored;
    _emit();
    return Success<PhotoAsset>(stored);
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

  List<PhotoAsset> _filedOn(String recordId) {
    return _rows.values
        .where((PhotoAsset row) => row.recordId == recordId)
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

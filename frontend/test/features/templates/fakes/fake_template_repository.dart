import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

/// In-memory [TemplateRepository] for feature tests that must not open a
/// database (FE-STATE-10).
final class FakeTemplateRepository implements TemplateRepository {
  final Map<String, TemplateDef> _rows = <String, TemplateDef>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// When set, [save] returns this instead of writing.
  Failure? saveFailure;

  /// How many templates the fake currently holds.
  int get count => _rows.length;

  /// Releases the watch stream. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<List<TemplateDef>> watchByProject(String projectId) {
    return _watch(() => _ownedBy(projectId));
  }

  @override
  Future<Result<TemplateDef?>> byId(String id) async {
    return Success<TemplateDef?>(_rows[id]);
  }

  @override
  Future<Result<TemplateDef>> save(TemplateDef template) async {
    final Failure? forced = saveFailure;
    if (forced != null) {
      return FailureResult<TemplateDef>(forced);
    }
    if (template.name.trim().isEmpty) {
      return const FailureResult<TemplateDef>(
        ValidationFailure(
          message: 'A template needs a name.',
          recoveryAction: 'Enter a name and save again.',
        ),
      );
    }
    final String id = template.id.isEmpty ? 'template-${_next++}' : template.id;
    final TemplateDef? existing = _rows[id];
    final TemplateDef stored = template.copyWith(
      id: id,
      version: existing == null
          ? (template.version < 1 ? 1 : template.version)
          : existing.version + 1,
    );
    _rows[id] = stored;
    _emit();
    return Success<TemplateDef>(stored);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    if (id.isEmpty) {
      return const FailureResult<void>(_missing);
    }
    if (reason.trim().isEmpty) {
      return const FailureResult<void>(_needsReason);
    }
    if (!_rows.containsKey(id)) {
      return const FailureResult<void>(_missing);
    }
    _rows.remove(id);
    _emit();
    return const Success<void>(null);
  }

  List<TemplateDef> _ownedBy(String projectId) {
    return _rows.values
        .where((TemplateDef row) => row.projectId == projectId)
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

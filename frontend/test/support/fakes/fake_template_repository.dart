import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

/// In-memory [TemplateRepository] for feature tests that must not open a database.
final class FakeTemplateRepository implements TemplateRepository {
  final Map<String, TemplateDef> _rows = <String, TemplateDef>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

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
    if (template.name.isEmpty) {
      return const FailureResult<TemplateDef>(
        ValidationFailure(
          message: 'A template needs a name.',
          recoveryAction: 'Enter a name and save again.',
        ),
      );
    }
    final String id = template.id.isEmpty ? 'template-${_next++}' : template.id;
    final TemplateDef stored = (
      id: id,
      projectId: template.projectId,
      name: template.name,
      version: template.version,
    );
    _rows[id] = stored;
    _emit();
    return Success<TemplateDef>(stored);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    final Result<void> refused = _refuseDelete(id, reason);
    switch (refused) {
      case FailureResult<void>():
        return refused;
      case Success<void>():
        break;
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

Result<void> _refuseDelete(String id, String reason) {
  if (id.isEmpty) {
    return const FailureResult<void>(_missing);
  }
  if (reason.isEmpty) {
    return const FailureResult<void>(_needsReason);
  }
  return const Success<void>(null);
}

const StorageFailure _missing = StorageFailure(
  message: 'That row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _needsReason = StorageFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why this row should be removed, then try again.',
);

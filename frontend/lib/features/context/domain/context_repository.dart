import 'dart:async';

import 'package:tapture/core/errors/result.dart';

import 'context_state.dart';

/// Persistence port for project context. Drift types stop at the data layer.
abstract interface class ContextRepository {
  /// Live context for [projectId], including empty when no levels exist.
  Stream<ContextState> watch(String projectId);

  /// Loads the stored context once (e.g. on project open).
  Future<Result<ContextState>> load(String projectId);

  /// Replaces the hierarchy definition and persists immediately.
  Future<Result<ContextState>> saveHierarchy(
    String projectId,
    List<ContextLevel> levels,
  );

  /// Sets a level value. When [clearBelow] is true, lower levels are cleared.
  Future<Result<ContextState>> setLevelValue({
    required String projectId,
    required String fieldKey,
    required String value,
    bool clearBelow = true,
  });

  /// Replaces pinned (non-hierarchy) values.
  Future<Result<ContextState>> savePinned(
    String projectId,
    Map<String, String> pinned,
  );

  /// Applies a preset in one write without cascade confirmation.
  Future<Result<ContextState>> applyPreset(
    String projectId,
    ContextPreset preset,
  );

  /// Live presets for [projectId], most recently used first.
  Stream<List<ContextPreset>> watchPresets(String projectId);

  /// Saves a preset. [overwrite] replaces an existing name.
  Future<Result<ContextPreset>> savePreset({
    required String projectId,
    required String name,
    required Map<String, String> values,
    required Map<String, String> pinned,
    bool overwrite = false,
  });

  /// Deletes a preset by id.
  Future<Result<void>> deletePreset(String id, {required String reason});

  /// Recent values for [fieldKey], newest first.
  Future<Result<List<String>>> recentValues({
    required String projectId,
    required String fieldKey,
  });
}

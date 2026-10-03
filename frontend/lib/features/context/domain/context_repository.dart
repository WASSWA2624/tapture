import 'dart:async';

import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'context_state.dart';

/// What [ContextRepository.savePreset] returns for a name the project already
/// uses when overwrite was not asked for. Callers compare by identity, never
/// by message text.
final ValidationFailure presetNameTaken = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureAPresetWithThatNameAlreadyExists,
  localizedRecovery:
      DomainCopy.messages.failureChooseAnotherNameOrConfirmOverwrite,
);

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

  /// Saves a preset. A name already in use fails with [presetNameTaken]
  /// unless [overwrite] is true, which replaces that preset's values.
  Future<Result<ContextPreset>> savePreset({
    required String projectId,
    required String name,
    required Map<String, String> values,
    required Map<String, String> pinned,
    bool overwrite = false,
  });

  /// Deletes a preset by id.
  Future<Result<void>> deletePreset(String id, {required String reason});

  /// Recent values for a level or pin [fieldKey], newest first. They
  /// survive an app restart.
  Future<Result<List<String>>> recentValues({
    required String projectId,
    required String fieldKey,
  });
}

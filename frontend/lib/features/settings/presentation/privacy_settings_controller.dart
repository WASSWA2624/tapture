import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/projects.dart';

import '../settings.dart';

/// Coordinates durable preferences and project-scoped location removal.
final class PrivacySettingsController extends Notifier<PrivacySettingsState> {
  @override
  PrivacySettingsState build() {
    final subscription = ref
        .watch(projectSettingsStoreProvider)
        .changes()
        .listen((_) {
          if (ref.mounted) {
            state = (
              revision: state.revision + 1,
              removing: state.removing,
              removed: state.removed,
              project: state.project,
            );
          }
        });
    ref.onDispose(subscription.cancel);
    return (revision: 0, removing: false, removed: null, project: null);
  }

  /// Persists a preference before the screen confirms it.
  Future<Result<void>> write<T>(SettingKey<T> key, T value) =>
      ref.read(projectSettingsStoreProvider).write(key, value);

  /// Updates the open project's capture policy or the global default.
  Future<Result<void>> gps(Project? project, bool on) {
    if (project == null) return write(SettingKeys.gpsEnabled, on);
    return ref
        .read(projectRepositoryProvider)
        .update(
          project.copyWith(settings: project.settings.copyWith(gpsEnabled: on)),
        );
  }

  /// Removes one confirmed project's saved location data atomically.
  Future<Result<int>> remove(String project) async {
    if (state.removing) return const Success<int>(0);
    state = (
      revision: state.revision,
      removing: true,
      removed: state.removed,
      project: state.project,
    );
    final Result<int> result = await ref
        .read(coordinatePrivacyRepositoryProvider)
        .removeFromProject(project);
    if (ref.mounted) {
      state = (
        revision: state.revision,
        removing: false,
        removed: result is Success<int> ? result.value : state.removed,
        project: result is Success<int> ? project : state.project,
      );
    }
    return result;
  }
}

/// Saved preference revision and the last successful project's removal count.
typedef PrivacySettingsState = ({
  int revision,
  bool removing,
  int? removed,
  String? project,
});

/// Ephemeral privacy screen state, disposed with the screen.
final privacySettingsControllerProvider =
    NotifierProvider.autoDispose<
      PrivacySettingsController,
      PrivacySettingsState
    >(PrivacySettingsController.new);

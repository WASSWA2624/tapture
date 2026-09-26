import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/projects/projects.dart' show ProjectSettings;
import 'package:tapture/features/settings/settings.dart';

/// The one place processing learns which provider and model serve a project
/// and an operation.
///
/// The project's own choice wins, then the app's per-operation choice, then
/// the app-wide provider and model. The registry validates the result, so an
/// unknown or unavailable choice falls back to the keyless backend. Callers
/// get a service and ids, and never branch on where the key lives.
final class ProviderSelection {
  /// Creates the resolver over the app [settings] and the [providers].
  const ProviderSelection({required this._settings, required this._providers});

  final SettingsStore _settings;
  final ProviderRegistry _providers;

  /// The provider and model [project] uses for [operation].
  ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack}) resolve(
    Project project,
    AiOperation operation,
  ) {
    final OperationChoice? choice =
        ProjectSettings.decode(
          project.settings,
        ).providerSelection?[operation.name] ??
        OperationSelection.decode(
          _settings.read(SettingKeys.aiProviderSelection),
        )[operation.name];
    return _providers.validateSelection(
      providerId: choice?.provider ?? _settings.read(SettingKeys.aiProvider),
      modelId: choice?.model ?? _settings.read(SettingKeys.aiModel),
      operation: operation,
    );
  }
}

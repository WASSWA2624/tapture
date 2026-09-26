import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettings, ProjectSettingsResolved, appProjectSettingsDefaults;
import 'package:tapture/features/settings/settings.dart';

import 'record_bundle.dart';

/// The app settings, project settings and provider choice a stage reads.
final class StageSettings {
  /// Creates the reader over [settings] and [providers].
  const StageSettings({required this._settings, required this._providers});

  final SettingsStore _settings;
  final ProviderRegistry _providers;

  /// The app-wide value stored for [key].
  T read<T>(SettingKey<T> key) => _settings.read(key);

  /// The bundle's project settings resolved against the app defaults.
  ProjectSettingsResolved project(RecordBundle bundle) {
    return ProjectSettings.decode(
      bundle.project.settings,
    ).resolve(appProjectSettingsDefaults(_settings));
  }

  /// The provider and model selected for [operation].
  ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
  selection(AiOperation operation) {
    return _providers.validateSelection(
      providerId: _settings.read(SettingKeys.aiProvider),
      modelId: _settings.read(SettingKeys.aiModel),
      operation: operation,
    );
  }
}

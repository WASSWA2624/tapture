import 'dart:convert';

import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettings, ProjectSettingsResolved, appProjectSettingsDefaults;
import 'package:tapture/features/settings/settings.dart';

import 'provider_selection.dart';
import 'record_bundle.dart';

/// The app settings, project settings and provider choice a stage reads.
final class StageSettings {
  /// Creates the reader over [settings] and [providers].
  const StageSettings({required this._settings, required this._providers});

  final SettingsStore _settings;
  final ProviderRegistry _providers;

  /// The shared settings store for durable usage accounting.
  SettingsStore get store => _settings;

  /// The app-wide value stored for [key].
  T read<T>(SettingKey<T> key) => _settings.read(key);

  /// Provider, account, model and limits covered by the current egress preview.
  String egressScope(RecordBundle bundle) => jsonEncode(<String, Object?>{
    'projectId': bundle.project.id,
    'doNotSendImages': project(bundle).doNotSendImages,
    'maxCost': read(SettingKeys.aiRequestMaxCost),
    'selections': <Map<String, Object?>>[
      for (final AiOperation operation in <AiOperation>[
        AiOperation.extractFields,
        AiOperation.transcribe,
        AiOperation.refineText,
      ])
        _scopeSelection(bundle, operation),
    ],
  });

  Map<String, Object?> _scopeSelection(
    RecordBundle bundle,
    AiOperation operation,
  ) {
    final choice = selection(bundle, operation);
    return <String, Object?>{
      'operation': operation.name,
      'providerId': choice.provider.id,
      'provider': choice.provider.label,
      'modelId': choice.model.id,
      'model': choice.model.label,
      'personal': choice.provider.serverCredentialProvider != null,
      'available': choice.provider.available,
    };
  }

  /// The bundle's project settings resolved against the app defaults.
  ProjectSettingsResolved project(RecordBundle bundle) {
    return ProjectSettings.decode(
      bundle.project.settings,
    ).resolve(appProjectSettingsDefaults(_settings));
  }

  /// The provider and model the bundle's project uses for [operation],
  /// resolved by [ProviderSelection].
  ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
  selection(RecordBundle bundle, AiOperation operation) {
    return ProviderSelection(
      settings: _settings,
      providers: _providers,
    ).resolve(bundle.project, operation);
  }
}

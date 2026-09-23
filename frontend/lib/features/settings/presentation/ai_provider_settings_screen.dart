import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart';

import 'provider_test_action.dart';

/// Registry-driven provider and model settings. No provider id is hardcoded in
/// presentation code; adding a descriptor updates this screen automatically.
final class AiProviderSettingsScreen extends ConsumerStatefulWidget {
  /// Creates the screen. Tests may inject all boundaries.
  const AiProviderSettingsScreen({
    super.key,
    this.registry,
    this.settings,
    this.storage,
  });

  /// Provider catalogue and services.
  final ProviderRegistry? registry;

  /// Typed non-secret settings.
  final SettingsStore? settings;

  /// Device keystore for an explicitly enabled device credential.
  final SecureStorage? storage;

  @override
  ConsumerState<AiProviderSettingsScreen> createState() =>
      _AiProviderSettingsScreenState();
}

class _AiProviderSettingsScreenState
    extends ConsumerState<AiProviderSettingsScreen> {
  final TextEditingController _credential = TextEditingController();
  AiOperation _operation = AiOperation.extractFields;
  String _providerId = ProviderRegistry.backendId;
  String _modelId = 'default';
  ProviderTestView _test = ProviderTestView.empty;
  Failure? _failure;
  bool _busy = false;
  bool _fellBack = false;

  ProviderRegistry get _registry =>
      widget.registry ?? ref.read(providerRegistryProvider);

  SettingsStore get _settings =>
      widget.settings ?? ref.read(projectSettingsStoreProvider);

  SecureStorage get _storage => widget.storage ?? SecureStorage();

  @override
  void initState() {
    super.initState();
    _providerId = _settings.read(SettingKeys.aiProvider);
    _modelId = _settings.read(SettingKeys.aiModel);
    _normalise(markFallback: true);
  }

  @override
  void dispose() {
    _credential.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProviderDescriptor provider = _selectedProvider;
    final List<ProviderDescriptor> providers = _registry.catalog
        .where(
          (ProviderDescriptor value) => value.operations.contains(_operation),
        )
        .toList(growable: false);
    final List<ModelDescriptor> models = provider.models
        .where((ModelDescriptor value) => value.operations.contains(_operation))
        .toList(growable: false);
    return AppPage(
      title: Copy.settingsAiTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppChoiceField<AiOperation>(
            label: Copy.aiOperation,
            value: _operation,
            options: <Choice<AiOperation>>[
              for (final AiOperation value in AiOperation.values)
                Choice<AiOperation>(value, Copy.aiOperationLabel(value.name)),
            ],
            onChanged: (AiOperation? value) {
              if (value == null) return;
              setState(() {
                _operation = value;
                _normalise(markFallback: true);
              });
            },
          ),
          const SizedBox(height: Space.x3),
          AppChoiceField<String>(
            label: Copy.aiProvider,
            value: provider.id,
            options: <Choice<String>>[
              for (final ProviderDescriptor value in providers)
                Choice<String>(value.id, value.label),
            ],
            onChanged: (String? value) {
              if (value == null) return;
              setState(() {
                _providerId = value;
                _modelId = '';
                _normalise();
                _fellBack = false;
              });
            },
          ),
          const SizedBox(height: Space.x3),
          AppChoiceField<String>(
            label: Copy.aiModel,
            value: _selectedModel(models).id,
            options: <Choice<String>>[
              for (final ModelDescriptor value in models)
                Choice<String>(value.id, value.label),
            ],
            onChanged: (String? value) {
              if (value != null) setState(() => _modelId = value);
            },
          ),
          const SizedBox(height: Space.x3),
          Text(Copy.aiCustody(provider.keyCustody.name, provider.available)),
          if (_fellBack) const Text(Copy.aiSelectionFallback),
          if (provider.deviceKeyAllowed &&
              provider.keyCustody == ProviderKeyCustody.device) ...<Widget>[
            const SizedBox(height: Space.x3),
            AppTextField(
              label: Copy.apiKeyLabel,
              controller: _credential,
              obscureText: true,
              dictation: false,
            ),
            AppButton(
              label: Copy.apiKeyRemove,
              variant: AppButtonVariant.secondary,
              onPressed: _busy ? null : _removeCredential,
            ),
          ],
          if (_failure case final Failure failure)
            AppErrorState(failure: failure, onRetry: _save),
          const SizedBox(height: Space.x3),
          AppButton(
            label: Copy.save,
            busy: _busy,
            onPressed: _busy ? null : _save,
          ),
          ProviderTestAction(
            view: provider.available ? _test : ProviderTestView.unavailable,
            onTest: provider.available ? _testConnection : null,
          ),
        ],
      ),
    );
  }

  ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
  get _selection => _registry.validateSelection(
    providerId: _providerId,
    modelId: _modelId,
    operation: _operation,
  );

  ProviderDescriptor get _selectedProvider => _selection.provider;

  ModelDescriptor _selectedModel(List<ModelDescriptor> models) {
    return models.firstWhere(
      (ModelDescriptor value) => value.id == _modelId,
      orElse: () => models.first,
    );
  }

  void _normalise({bool markFallback = false}) {
    final selection = _selection;
    if (markFallback) {
      _fellBack = selection.fellBack;
    }
    _providerId = selection.provider.id;
    _modelId = selection.model.id;
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    final ProviderDescriptor provider = _selectedProvider;
    if (provider.deviceKeyAllowed && _credential.text.trim().isNotEmpty) {
      final Result<void> secret = await _storage.putSecret(
        SecretKey.providerCredential,
        _credential.text.trim(),
      );
      if (secret case FailureResult<void>(:final Failure failure)) {
        _finishFailure(failure);
        return;
      }
    }
    final Result<void> providerSaved = await _settings.write(
      SettingKeys.aiProvider,
      provider.id,
    );
    if (providerSaved case FailureResult<void>(:final Failure failure)) {
      _finishFailure(failure);
      return;
    }
    final Result<void> modelSaved = await _settings.write(
      SettingKeys.aiModel,
      _modelId,
    );
    if (modelSaved case FailureResult<void>(:final Failure failure)) {
      _finishFailure(failure);
      return;
    }
    if (!mounted) return;
    _credential.clear();
    setState(() => _busy = false);
  }

  Future<void> _removeCredential() async {
    final Result<void> result = await _storage.deleteSecret(
      SecretKey.providerCredential,
    );
    if (result case FailureResult<void>(:final Failure failure)) {
      _finishFailure(failure);
    }
  }

  Future<void> _testConnection() async {
    final ProviderTestOutcome outcome = await _registry.testConnection(
      _selectedProvider.service,
    );
    if (!mounted) return;
    setState(() {
      _test = switch (outcome) {
        ProviderTestOutcome.success => ProviderTestView.success,
        ProviderTestOutcome.authentication => ProviderTestView.authentication,
        ProviderTestOutcome.network => ProviderTestView.network,
        ProviderTestOutcome.unavailable => ProviderTestView.unavailable,
        ProviderTestOutcome.validation => ProviderTestView.validation,
      };
    });
  }

  void _finishFailure(Failure failure) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }
}

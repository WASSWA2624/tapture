import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart';

import 'provider_test_action.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Registry-driven provider and model settings. No provider id is hardcoded in
/// presentation code; adding a descriptor updates this screen automatically.
///
/// The screen owns only the key field's controller; the choice, the saved-key
/// flag and every outcome live in [aiProviderSettingsProvider].
final class AiProviderSettingsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AiProviderSettingsScreen({super.key});

  @override
  ConsumerState<AiProviderSettingsScreen> createState() =>
      _AiProviderSettingsScreenState();
}

class _AiProviderSettingsScreenState
    extends ConsumerState<AiProviderSettingsScreen> {
  final TextEditingController _credential = TextEditingController();

  @override
  void dispose() {
    _credential.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final _AiView view = ref.watch(aiProviderSettingsProvider);
    final _AiSettings controller = ref.read(
      aiProviderSettingsProvider.notifier,
    );
    final ProviderDescriptor provider = controller.provider;
    final List<ModelDescriptor> models = controller.models;
    return AppPage(
      title: localCopy.settingsAiTitle,
      footer: AppPrimaryAction(
        key: const ValueKey<String>('ai-save'),
        label: localCopy.save,
        busy: view.busy,
        onPressed: view.busy ? null : () => unawaited(_save()),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppChoiceField<String>(
            label: localCopy.aiProvider,
            value: provider.id,
            options: <Choice<String>>[
              for (final ProviderDescriptor value in controller.providers)
                Choice<String>(value.id, value.label),
            ],
            onChanged: (String? value) {
              if (value != null) controller.selectProvider(value);
            },
          ),
          const SizedBox(height: Space.x3),
          AppChoiceField<String>(
            label: localCopy.aiModel,
            value: controller.model.id,
            options: <Choice<String>>[
              for (final ModelDescriptor value in models)
                Choice<String>(value.id, value.label),
            ],
            onChanged: (String? value) {
              if (value != null) controller.selectModel(value);
            },
          ),
          const SizedBox(height: Space.x3),
          AppBanner(
            key: const ValueKey<String>('ai-custody'),
            message: localCopy.aiCustody(
              provider.keyCustody.name,
              provider.available,
            ),
            icon: provider.available ? AppIcons.key : AppIcons.warning,
            tone: provider.available ? SnackTone.info : SnackTone.warning,
          ),
          if (view.fellBack) ...<Widget>[
            const SizedBox(height: Space.x2),
            AppBanner(
              key: const ValueKey<String>('ai-fell-back'),
              message: localCopy.aiSelectionFallback,
              icon: AppIcons.warning,
              tone: SnackTone.warning,
            ),
          ],
          if (provider.deviceKeyAllowed &&
              provider.keyCustody == ProviderKeyCustody.device) ...<Widget>[
            const SizedBox(height: Space.x3),
            AppTextField(
              label: localCopy.apiKeyLabel,
              helper: view.keyStored ? localCopy.apiKeySaved : null,
              controller: _credential,
              obscureText: true,
              dictation: false,
            ),
            if (view.keyStored) ...<Widget>[
              const SizedBox(height: Space.x2),
              AppButton(
                key: const ValueKey<String>('ai-remove-key'),
                label: localCopy.apiKeyRemove,
                variant: AppButtonVariant.destructive,
                onPressed: view.busy
                    ? null
                    : () => unawaited(_confirmRemoveCredential()),
              ),
            ],
          ],
          if (view.failure case final Failure failure)
            AppErrorState(failure: failure, onRetry: () => unawaited(_save())),
          const SizedBox(height: Space.x3),
          ProviderTestAction(
            view: provider.available ? view.test : ProviderTestView.unavailable,
            onTest: provider.available
                ? () => unawaited(controller.testConnection())
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final bool saved = await ref
        .read(aiProviderSettingsProvider.notifier)
        .save(_credential.text);
    if (saved && mounted) {
      _credential.clear();
    }
  }

  /// Asks first, then removes the key and the selection that needed it in
  /// one action, so nothing is left pointing at a key that is gone.
  Future<void> _confirmRemoveCredential() async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.apiKeyRemoveTitle,
      message: localCopy.apiKeyRemoveMessage,
      confirmLabel: localCopy.apiKeyRemove,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await ref.read(aiProviderSettingsProvider.notifier).removeCredential();
  }
}

/// Where a device-held provider key is kept. Tests pass a fake.
final Provider<SecureStorage> providerKeyStorageProvider =
    Provider<SecureStorage>((Ref _) => SecureStorage());

/// Injects the catalogue, the settings and the keystore so tests never
/// touch the platform (FE-TEST-03).
List<Override> aiProviderSettingsOverrides({
  required ProviderRegistry registry,
  required SettingsStore settings,
  required SecureStorage storage,
}) {
  return <Override>[
    providerRegistryProvider.overrideWithValue(registry),
    projectSettingsStoreProvider.overrideWithValue(settings),
    providerKeyStorageProvider.overrideWithValue(storage),
  ];
}

/// The screen's choice and outcomes. Leaving the page drops the unsaved
/// choice.
final NotifierProvider<_AiSettings, _AiView> aiProviderSettingsProvider =
    NotifierProvider.autoDispose<_AiSettings, _AiView>(_AiSettings.new);

typedef _AiView = ({
  String providerId,
  String modelId,
  ProviderTestView test,
  Failure? failure,
  bool busy,
  bool fellBack,
  bool keyStored,
});

class _AiSettings extends Notifier<_AiView> {
  /// Providers and models are chosen for extraction, the step every
  /// record goes through; the pipeline's other steps follow the same
  /// choice. No internal step picker is shown (FE-SIMP-10).
  static const AiOperation _operation = AiOperation.extractFields;

  ProviderRegistry get _registry => ref.read(providerRegistryProvider);

  SettingsStore get _settings => ref.read(projectSettingsStoreProvider);

  SecureStorage get _storage => ref.read(providerKeyStorageProvider);

  @override
  _AiView build() {
    final ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
    selection = _validate(
      _settings.read(SettingKeys.aiProvider),
      _settings.read(SettingKeys.aiModel),
    );
    unawaited(_readKeyStored());
    return (
      providerId: selection.provider.id,
      modelId: selection.model.id,
      test: ProviderTestView.empty,
      failure: null,
      busy: false,
      fellBack: selection.fellBack,
      keyStored: false,
    );
  }

  /// Every provider that can run the operation.
  List<ProviderDescriptor> get providers => _registry.catalog
      .where(
        (ProviderDescriptor value) => value.operations.contains(_operation),
      )
      .toList(growable: false);

  /// The chosen provider, valid for the operation.
  ProviderDescriptor get provider =>
      _validate(state.providerId, state.modelId).provider;

  /// The chosen provider's models for the operation.
  List<ModelDescriptor> get models => provider.models
      .where((ModelDescriptor value) => value.operations.contains(_operation))
      .toList(growable: false);

  /// The chosen model, or the provider's first when none is chosen.
  ModelDescriptor get model {
    final List<ModelDescriptor> available = models;
    return available.firstWhere(
      (ModelDescriptor value) => value.id == state.modelId,
      orElse: () => available.first,
    );
  }

  /// Chooses [providerId] and its default model.
  void selectProvider(String providerId) {
    final ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
    selection = _validate(providerId, '');
    state = _with(
      providerId: selection.provider.id,
      modelId: selection.model.id,
      fellBack: false,
    );
  }

  /// Chooses [modelId] on the current provider.
  void selectModel(String modelId) {
    state = _with(modelId: modelId);
  }

  /// Saves the choice, and [credential] when the provider keeps a device
  /// key and one was typed. True when a key was saved.
  Future<bool> save(String credential) async {
    state = _with(busy: true, clearFailure: true);
    final ProviderDescriptor chosen = provider;
    final String key = credential.trim();
    final bool savesKey = chosen.deviceKeyAllowed && key.isNotEmpty;
    if (savesKey) {
      final Result<void> secret = await _storage.putSecret(
        SecretKey.providerCredential,
        key,
      );
      if (secret case FailureResult<void>(:final Failure failure)) {
        _fail(failure);
        return false;
      }
    }
    for (final Future<Result<void>> Function() write
        in <Future<Result<void>> Function()>[
          () => _settings.write(SettingKeys.aiProvider, chosen.id),
          () => _settings.write(SettingKeys.aiModel, state.modelId),
        ]) {
      final Result<void> written = await write();
      if (written case FailureResult<void>(:final Failure failure)) {
        _fail(failure);
        return false;
      }
    }
    if (!ref.mounted) {
      return savesKey;
    }
    state = _with(busy: false, keyStored: state.keyStored || savesKey);
    return savesKey;
  }

  /// Removes the device key and returns the selection to the keyless
  /// organisation provider in one action.
  Future<void> removeCredential() async {
    state = _with(busy: true, clearFailure: true);
    final Result<void> removed = await _storage.deleteSecret(
      SecretKey.providerCredential,
    );
    if (removed case FailureResult<void>(:final Failure failure)) {
      _fail(failure);
      return;
    }
    // The whole selection goes with the key: the provider, its model and
    // any per-operation choice that could still name the keyed provider.
    for (final Future<Result<void>> Function() write
        in <Future<Result<void>> Function()>[
          () => _settings.write(
            SettingKeys.aiProvider,
            ProviderRegistry.backendId,
          ),
          () => _settings.write(
            SettingKeys.aiModel,
            SettingKeys.aiModel.defaultValue,
          ),
          () => _settings.write(
            SettingKeys.aiProviderSelection,
            SettingKeys.aiProviderSelection.defaultValue,
          ),
        ]) {
      final Result<void> reset = await write();
      if (reset case FailureResult<void>(:final Failure failure)) {
        _fail(failure);
        return;
      }
    }
    if (!ref.mounted) {
      return;
    }
    final ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
    selection = _validate(ProviderRegistry.backendId, '');
    state = _with(
      providerId: selection.provider.id,
      modelId: selection.model.id,
      busy: false,
      keyStored: false,
    );
  }

  /// Runs the smallest request through the chosen provider.
  Future<void> testConnection() async {
    final ProviderTestOutcome outcome = await _registry.testConnection(
      provider.service,
    );
    if (!ref.mounted) {
      return;
    }
    state = _with(
      test: switch (outcome) {
        ProviderTestOutcome.success => ProviderTestView.success,
        ProviderTestOutcome.authentication => ProviderTestView.authentication,
        ProviderTestOutcome.network => ProviderTestView.network,
        ProviderTestOutcome.unavailable => ProviderTestView.unavailable,
        ProviderTestOutcome.validation => ProviderTestView.validation,
        ProviderTestOutcome.failed => ProviderTestView.failed,
      },
    );
  }

  /// Whether a device key is already saved, so the screen can say so and
  /// offer Remove only then. The key itself is never read into state.
  Future<void> _readKeyStored() async {
    final Result<String?> stored = await _storage.readSecret(
      SecretKey.providerCredential,
    );
    final bool present = switch (stored) {
      Success<String?>(:final String? value) =>
        value != null && value.isNotEmpty,
      FailureResult<String?>() => false,
    };
    if (ref.mounted && present != state.keyStored) {
      state = _with(keyStored: present);
    }
  }

  ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
  _validate(String providerId, String modelId) {
    return _registry.validateSelection(
      providerId: providerId,
      modelId: modelId,
      operation: _operation,
    );
  }

  void _fail(Failure failure) {
    if (ref.mounted) {
      state = _with(busy: false, failure: failure);
    }
  }

  _AiView _with({
    String? providerId,
    String? modelId,
    ProviderTestView? test,
    Failure? failure,
    bool clearFailure = false,
    bool? busy,
    bool? fellBack,
    bool? keyStored,
  }) {
    return (
      providerId: providerId ?? state.providerId,
      modelId: modelId ?? state.modelId,
      test: test ?? state.test,
      failure: clearFailure ? null : failure ?? state.failure,
      busy: busy ?? state.busy,
      fellBack: fellBack ?? state.fellBack,
      keyStored: keyStored ?? state.keyStored,
    );
  }
}

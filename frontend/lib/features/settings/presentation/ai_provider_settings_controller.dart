part of 'ai_provider_settings_screen.dart';

// The notifier remains private; injection exposes only its provider handle.
// ignore_for_file: library_private_types_in_public_api

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
  bool _isTesting = false;
  int _credentialStatusEpoch = 0;

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
    ref.listen(providerRegistryProvider, (previous, _) {
      final selection = _validate(state.providerId, state.modelId);
      state = _with(fellBack: selection.fellBack);
      final String? priorCredential = previous?.catalog
          .where((value) => value.id == state.providerId)
          .firstOrNull
          ?.serverCredentialProvider;
      if (selection.provider.serverCredentialProvider != null &&
          selection.provider.serverCredentialProvider != priorCredential) {
        unawaited(_readKeyStored());
      }
    });
    unawaited(_readKeyStored());
    unawaited(_refreshCatalogue());
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
  List<ProviderDescriptor> get providers => <ProviderDescriptor>[
    if (!_registry.catalog.any(
      (ProviderDescriptor value) =>
          value.id == state.providerId && value.operations.contains(_operation),
    ))
      provider,
    ..._registry.catalog.where(
      (ProviderDescriptor value) => value.operations.contains(_operation),
    ),
  ];

  /// The chosen provider, valid for the operation.
  ProviderDescriptor get provider =>
      _validate(state.providerId, state.modelId).provider;

  /// The chosen provider's models for the operation.
  List<ModelDescriptor> get models => <ModelDescriptor>[
    if (!provider.models.any(
      (ModelDescriptor value) =>
          value.id == state.modelId && value.operations.contains(_operation),
    ))
      model,
    ...provider.models.where(
      (ModelDescriptor value) => value.operations.contains(_operation),
    ),
  ];

  /// The chosen model, or the provider's first when none is chosen.
  ModelDescriptor get model => _validate(state.providerId, state.modelId).model;

  /// Chooses [providerId] and its default model.
  void selectProvider(String providerId) {
    final ProviderDescriptor? chosen = providers
        .where((ProviderDescriptor provider) => provider.id == providerId)
        .firstOrNull;
    if (chosen == null) return;
    final ModelDescriptor? defaultModel = chosen.models
        .where((ModelDescriptor model) => model.operations.contains(_operation))
        .firstOrNull;
    if (defaultModel == null) return;
    final ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
    selection = _validate(providerId, defaultModel.id);
    state = _with(
      providerId: selection.provider.id,
      modelId: selection.model.id,
      fellBack: selection.fellBack,
      clearFailure: true,
      test: ProviderTestView.empty,
      keyStored: false,
    );
    unawaited(_readKeyStored());
  }

  /// Chooses [modelId] on the current provider.
  void selectModel(String modelId) {
    final selection = _validate(state.providerId, modelId);
    state = _with(
      modelId: selection.model.id,
      fellBack: selection.fellBack,
      test: ProviderTestView.empty,
    );
  }

  /// Saves the choice, and [credential] when the provider keeps a device
  /// key and one was typed. True when a key was saved.
  Future<bool> save(String credential, {String? approvedCost}) async {
    _credentialStatusEpoch++;
    state = _with(busy: true, clearFailure: true);
    final ProviderDescriptor chosen = provider;
    final String key = credential.trim();
    final double? cost = approvedCost == null
        ? _settings.read(SettingKeys.aiRequestMaxCost)
        : approvedCost.trim().isEmpty
        ? 0
        : double.tryParse(approvedCost.trim());
    if (cost == null || !cost.isFinite || cost < 0) {
      _fail(
        const ValidationFailure(
          message: 'Enter a non-negative spending limit.',
        ),
      );
      return false;
    }
    final String? serverProvider = chosen.serverCredentialProvider;
    final bool savesKey =
        (chosen.deviceKeyAllowed || serverProvider != null) && key.isNotEmpty;
    if (savesKey) {
      final Result<void> secret = serverProvider != null
          ? await ref
                .read(serverCredentialClientProvider)
                .save(serverProvider, key)
          : await _storage.putSecret(SecretKey.providerCredential, key);
      if (secret case FailureResult<void>(:final Failure failure)) {
        _fail(failure);
        return false;
      }
    }
    for (final Future<Result<void>> Function() write
        in <Future<Result<void>> Function()>[
          () => _settings.write(SettingKeys.aiProvider, chosen.id),
          () => _settings.write(SettingKeys.aiModel, state.modelId),
          () => _settings.write(SettingKeys.aiRequestMaxCost, cost),
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
    if (provider.serverCredentialProvider == null &&
        !provider.deviceKeyAllowed) {
      return;
    }
    _credentialStatusEpoch++;
    state = _with(busy: true, clearFailure: true);
    final String? serverProvider = provider.serverCredentialProvider;
    if (serverProvider != null) {
      final Result<void> removed = await ref
          .read(serverCredentialClientProvider)
          .remove(serverProvider);
      if (removed case FailureResult<void>(:final Failure failure)) {
        _fail(failure);
      } else if (ref.mounted) {
        state = _with(busy: false, keyStored: false);
      }
      return;
    }
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
    if (_isTesting || state.busy) return;
    _isTesting = true;
    final ProviderRegistry registry = _registry;
    final String providerId = state.providerId;
    final String modelId = state.modelId;
    final service = provider.service;
    final ProviderTestOutcome outcome;
    try {
      outcome = await registry.testConnection(
        service is ProxyAiService
            ? service.forProject(service.projectId, model: modelId)
            : service,
        operation: _operation,
      );
    } finally {
      _isTesting = false;
    }
    if (!ref.mounted ||
        state.providerId != providerId ||
        state.modelId != modelId ||
        !identical(registry, _registry)) {
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
    // Build schedules this read after its initial view exists. A provider
    // change cannot apply an older account's status to the new selection.
    await Future<void>.value();
    if (!ref.mounted) return;
    final int epoch = ++_credentialStatusEpoch;
    final String providerId = state.providerId;
    final String? serverProvider = provider.serverCredentialProvider;
    if (serverProvider != null) {
      final Result<bool> status = await ref
          .read(serverCredentialClientProvider)
          .configured(serverProvider);
      if (ref.mounted &&
          epoch == _credentialStatusEpoch &&
          state.providerId == providerId) {
        switch (status) {
          case Success<bool>(:final bool value):
            state = _with(keyStored: value);
          case FailureResult<bool>(:final Failure failure):
            state = _with(failure: failure);
        }
      }
      return;
    }
    if (!provider.deviceKeyAllowed) return;
    final Result<String?> stored = await _storage.readSecret(
      SecretKey.providerCredential,
    );
    final bool present = switch (stored) {
      Success<String?>(:final String? value) =>
        value != null && value.isNotEmpty,
      FailureResult<String?>() => false,
    };
    if (ref.mounted &&
        epoch == _credentialStatusEpoch &&
        state.providerId == providerId &&
        present != state.keyStored) {
      state = _with(keyStored: present);
    }
  }

  Future<void> retryStatus() async {
    state = _with(clearFailure: true);
    await _readKeyStored();
    await _refreshCatalogue();
  }

  Future<void> _refreshCatalogue() async {
    final Result<void> refreshed = await ref
        .read(serverAiCatalogueProvider)
        .refresh();
    if (ref.mounted && refreshed is Success<void>) {
      state = _with(
        fellBack: _validate(state.providerId, state.modelId).fellBack,
      );
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

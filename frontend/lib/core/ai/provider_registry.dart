import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/ai/ai_operation.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/model_descriptor.dart';
import 'package:tapture/core/ai/provider_descriptor.dart';
import 'package:tapture/core/ai/provider_key_custody.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

export 'ai_operation.dart';
export 'model_descriptor.dart';
export 'operation_selection.dart';
export 'provider_descriptor.dart';
export 'provider_key_custody.dart';

/// Chooses an [AiService] per project and per operation.
///
/// An entry records where its key lives. It never holds the key. The default
/// entry is the organisation's backend proxy, which holds none.
final class ProviderRegistry {
  /// Creates a registry from typed [descriptors]. [entries] remains as a
  /// compatibility seam for small domain tests.
  ///
  /// [allows] is read before every resolution: an operation switched off on
  /// the privacy page resolves to an unavailable service, so no caller can
  /// compose a request for it (FE-SEC-03). Omitted, every operation may send.
  ProviderRegistry({
    Map<String, RegistryEntry>? entries,
    List<ProviderDescriptor>? descriptors,
    Map<String, Map<AiOperation, String>>? selection,
    bool Function(AiOperation operation)? allows,
  }) : _entries = Map<String, RegistryEntry>.unmodifiable(
         entries ?? _entriesFrom(descriptors ?? const []),
       ),
       _catalog = _catalogFrom(entries, descriptors),
       _selection = _freezeSelection(selection),
       _allows = allows ?? _allowAll {
    if (!_entries.containsKey(backendId)) {
      throw ArgumentError.value(
        _entries.keys,
        'entries',
        'The keyless backend provider is required.',
      );
    }
    final Set<String> ids = <String>{};
    for (final ProviderDescriptor descriptor in _catalog) {
      if (!ids.add(descriptor.id)) {
        throw ArgumentError.value(descriptor.id, 'descriptors', 'Duplicate id');
      }
      final Set<String> models = <String>{};
      for (final ModelDescriptor model in descriptor.models) {
        if (!models.add(model.id)) {
          throw ArgumentError.value(model.id, 'models', 'Duplicate model id');
        }
      }
      for (final AiOperation operation in descriptor.operations) {
        if (!descriptor.models.any(
          (ModelDescriptor model) => model.operations.contains(operation),
        )) {
          throw ArgumentError.value(
            operation,
            'models',
            'Every provider operation needs a model',
          );
        }
      }
      if (descriptor.keyCustody == ProviderKeyCustody.backend &&
          descriptor.deviceKeyAllowed) {
        throw ArgumentError.value(
          descriptor.id,
          'deviceKeyAllowed',
          'Backend-held providers cannot accept a device credential',
        );
      }
    }
  }

  /// Id of the keyless organisation proxy.
  static const String backendId = 'backend';

  final Map<String, RegistryEntry> _entries;
  final List<ProviderDescriptor> _catalog;
  final Map<String, Map<AiOperation, String>> _selection;
  final bool Function(AiOperation operation) _allows;

  /// A registry whose only entry is the keyless proxy. [allows] is as for
  /// the unnamed constructor.
  factory ProviderRegistry.keyless({
    AiService? proxy,
    bool Function(AiOperation operation)? allows,
  }) {
    final AiService service = proxy ?? ProxyAiService.unconfigured();
    return ProviderRegistry(
      allows: allows,
      descriptors: <ProviderDescriptor>[
        ProviderDescriptor(
          id: backendId,
          label: 'Organisation backend',
          operations: AiOperation.values.toSet(),
          keyCustody: ProviderKeyCustody.backend,
          deviceKeyAllowed: false,
          available: service.isAvailable,
          service: service,
          models: <ModelDescriptor>[
            ModelDescriptor(
              id: 'default',
              label: 'Organisation default',
              operations: AiOperation.values.toSet(),
            ),
          ],
        ),
      ],
    );
  }

  /// Ordered, immutable presentation catalogue.
  List<ProviderDescriptor> get catalog => _catalog;

  /// The implementation for [projectId] and [operation].
  ///
  /// Callers receive an [AiService] and nothing about key custody.
  AiService resolve({
    required String projectId,
    required AiOperation operation,
    String? providerId,
  }) {
    if (!_allows(operation)) {
      return const AiService.unavailable();
    }
    final String id =
        providerId ?? _selection[projectId]?[operation] ?? backendId;
    final AiService service =
        _entries[id]?.service ?? const AiService.unavailable();
    return service is ProxyAiService ? service.forProject(projectId) : service;
  }

  /// Keeps the explicit billing/provider choice, refusing unavailable IDs.
  ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
  validateSelection({
    required String providerId,
    required String modelId,
    required AiOperation operation,
    String? projectId,
  }) {
    ProviderDescriptor? saved;
    for (final ProviderDescriptor candidate in _catalog) {
      if (candidate.id == providerId) saved = candidate;
    }
    ModelDescriptor? selectedModel;
    for (final ModelDescriptor candidate
        in saved?.models ?? const <ModelDescriptor>[]) {
      if ((candidate.id == modelId ||
              (modelId.isEmpty && candidate.id == 'default')) &&
          candidate.operations.contains(operation)) {
        selectedModel = candidate;
      }
    }
    final ModelDescriptor model =
        selectedModel ??
        ModelDescriptor(
          id: modelId,
          label: modelId,
          operations: <AiOperation>{operation},
        );
    ProviderDescriptor provider =
        saved ??
        ProviderDescriptor(
          id: providerId,
          label: providerId,
          operations: <AiOperation>{operation},
          keyCustody: ProviderKeyCustody.backend,
          deviceKeyAllowed: false,
          available: false,
          service: const AiService.unavailable(),
          models: <ModelDescriptor>[model],
        );
    if (projectId != null && provider.service is ProxyAiService) {
      final ProxyAiService scoped = (provider.service as ProxyAiService)
          .forProject(projectId, model: model.id);
      provider = ProviderDescriptor(
        id: provider.id,
        label: provider.label,
        operations: provider.operations,
        keyCustody: provider.keyCustody,
        deviceKeyAllowed: provider.deviceKeyAllowed,
        available: scoped.isAvailable,
        service: scoped,
        models: provider.models,
        serverCredentialProvider: provider.serverCredentialProvider,
        serverProvider: provider.serverProvider,
      );
    }
    final bool invalid =
        saved == null ||
        selectedModel == null ||
        !provider.operations.contains(operation) ||
        !provider.available ||
        !provider.service.isAvailable;
    if (!_allows(operation) || invalid) {
      // Switched off on the privacy page: the choice is kept, and nothing
      // can be sent through it.
      return (
        provider: ProviderDescriptor(
          id: provider.id,
          label: provider.label,
          operations: provider.operations,
          keyCustody: provider.keyCustody,
          deviceKeyAllowed: provider.deviceKeyAllowed,
          available: false,
          service: const AiService.unavailable(),
          models: provider.models,
          serverCredentialProvider: provider.serverCredentialProvider,
          serverProvider: provider.serverProvider,
        ),
        model: model,
        fellBack: invalid,
      );
    }
    return (provider: provider, model: model, fellBack: false);
  }

  /// Whether [id] keeps its key on the backend. Missing entries do.
  bool keyHeldByBackend(String id) {
    return _entries[id]?.keyHeldByBackend ?? true;
  }

  /// Smallest call the test action may make. The outcome is decided from the
  /// failure's type and [ProviderFailure.kind], never from its message.
  Future<ProviderTestOutcome> testConnection(AiService service) async {
    if (!service.isAvailable) {
      return ProviderTestOutcome.unavailable;
    }
    final Result<ReadTextResult> result = await service.readText(
      const ReadTextRequest(imagePaths: <String>[]),
    );
    return result.fold(_outcome, (_) => ProviderTestOutcome.success);
  }
}

bool _allowAll(AiOperation _) => true;

/// Application provider/model catalogue. Bootstrap replaces the unavailable
/// keyless stand-in with the same registry used by processing.
final Provider<ProviderRegistry> providerRegistryProvider =
    Provider<ProviderRegistry>((Ref _) => ProviderRegistry.keyless());

/// Where an entry's key lives, and the service it resolves to.
typedef RegistryEntry = ({String id, bool keyHeldByBackend, AiService service});

/// What a test connection is allowed to say.
enum ProviderTestOutcome {
  /// The smallest call succeeded.
  success,

  /// The key was rejected.
  authentication,

  /// The network failed.
  network,

  /// The descriptor is registered but not currently available.
  unavailable,

  /// Provider or model selection is invalid.
  validation,

  /// The provider answered with an error that is neither a rejected key nor
  /// a network fault.
  failed,
}

ProviderTestOutcome _outcome(Failure failure) {
  return switch (failure) {
    NetworkFailure() => ProviderTestOutcome.network,
    ProviderFailure(:final ProviderFailureKind kind) => switch (kind) {
      ProviderFailureKind.authentication => ProviderTestOutcome.authentication,
      ProviderFailureKind.unavailable => ProviderTestOutcome.network,
      ProviderFailureKind.rateLimited ||
      ProviderFailureKind.unsupportedMedia ||
      ProviderFailureKind.malformed ||
      ProviderFailureKind.unknown => ProviderTestOutcome.failed,
    },
    ValidationFailure() => ProviderTestOutcome.validation,
    CancelledFailure() ||
    CorruptionFailure() ||
    PermissionFailure() ||
    StorageFailure() => ProviderTestOutcome.failed,
  };
}

Map<String, RegistryEntry> _entriesFrom(List<ProviderDescriptor> descriptors) {
  return <String, RegistryEntry>{
    for (final ProviderDescriptor descriptor in descriptors)
      descriptor.id: (
        id: descriptor.id,
        keyHeldByBackend: descriptor.keyCustody == ProviderKeyCustody.backend,
        service: descriptor.service,
      ),
  };
}

List<ProviderDescriptor> _catalogFrom(
  Map<String, RegistryEntry>? entries,
  List<ProviderDescriptor>? descriptors,
) {
  if (descriptors != null) {
    return List<ProviderDescriptor>.unmodifiable(descriptors);
  }
  return List<ProviderDescriptor>.unmodifiable(<ProviderDescriptor>[
    for (final RegistryEntry entry in entries?.values ?? const [])
      ProviderDescriptor(
        id: entry.id,
        label: entry.id,
        operations: AiOperation.values.toSet(),
        keyCustody: entry.keyHeldByBackend
            ? ProviderKeyCustody.backend
            : ProviderKeyCustody.device,
        deviceKeyAllowed: !entry.keyHeldByBackend,
        available: entry.service.isAvailable,
        service: entry.service,
        models: <ModelDescriptor>[
          ModelDescriptor(
            id: 'default',
            label: 'Default',
            operations: AiOperation.values.toSet(),
          ),
        ],
      ),
  ]);
}

Map<String, Map<AiOperation, String>> _freezeSelection(
  Map<String, Map<AiOperation, String>>? selection,
) {
  if (selection == null) {
    return const <String, Map<AiOperation, String>>{};
  }
  return Map<String, Map<AiOperation, String>>.unmodifiable(
    <String, Map<AiOperation, String>>{
      for (final MapEntry<String, Map<AiOperation, String>> entry
          in selection.entries)
        entry.key: Map<AiOperation, String>.unmodifiable(entry.value),
    },
  );
}

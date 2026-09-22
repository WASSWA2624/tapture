import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Chooses an [AiService] per project and per operation.
///
/// An entry records where its key lives. It never holds the key. The default
/// entry is the organisation's backend proxy, which holds none.
final class ProviderRegistry {
  /// Creates a registry. [entries] must include [backendId].
  ProviderRegistry({
    required this._entries,
    Map<String, Map<AiOperation, String>>? selection,
  }) : _selection = selection ?? const <String, Map<AiOperation, String>>{};

  /// Id of the keyless organisation proxy.
  static const String backendId = 'backend';

  final Map<String, RegistryEntry> _entries;
  final Map<String, Map<AiOperation, String>> _selection;

  /// A registry whose only entry is the keyless proxy.
  factory ProviderRegistry.keyless({AiService? proxy}) {
    final AiService service = proxy ?? const AiService.unavailable();
    return ProviderRegistry(
      entries: <String, RegistryEntry>{
        backendId: (id: backendId, keyHeldByBackend: true, service: service),
      },
    );
  }

  /// The implementation for [projectId] and [operation].
  ///
  /// Callers receive an [AiService] and nothing about key custody.
  AiService resolve({
    required String projectId,
    required AiOperation operation,
  }) {
    final String id =
        _selection[projectId]?[operation] ??
        _selection[projectId]?.values.firstOrNull ??
        backendId;
    return (_entries[id] ?? _entries[backendId])!.service;
  }

  /// Whether [id] keeps its key on the backend. Missing entries do.
  bool keyHeldByBackend(String id) {
    return _entries[id]?.keyHeldByBackend ?? true;
  }

  /// Smallest call the test action may make. Reports the three outcomes.
  Future<ProviderTestOutcome> testConnection(AiService service) async {
    final Result<ReadTextResult> result = await service.readText(
      const ReadTextRequest(imagePaths: <String>[]),
    );
    return result.fold(_outcome, (_) => ProviderTestOutcome.success);
  }
}

/// Which operation a project is selecting a provider for.
enum AiOperation {
  /// Image text.
  readText,

  /// Field extraction.
  extractFields,

  /// Caption refinement.
  refineText,

  /// Speech.
  transcribe,
}

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
}

ProviderTestOutcome _outcome(Failure failure) {
  if (failure is NetworkFailure) {
    return ProviderTestOutcome.network;
  }
  return ProviderTestOutcome.authentication;
}

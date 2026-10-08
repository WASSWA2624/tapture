import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test(
    'availability binds the saved proxy to its authorized project first',
    () {
      final ProxyAiService proxy = ProxyAiService(
        baseUrl: 'https://example.test',
        send:
            ({
              required String path,
              required Map<String, Object?> json,
            }) async => (status: 200, body: '{}'),
        projectAllowed: (String project) => project == 'allowed',
      );
      expect(proxy.isAvailable, isFalse);
      final ProviderRegistry registry = ProviderRegistry.keyless(proxy: proxy);
      final allowed = registry.validateSelection(
        providerId: 'backend',
        modelId: '',
        operation: AiOperation.extractFields,
        projectId: 'allowed',
      );
      expect(allowed.model.id, 'default');
      expect(allowed.provider.service.isAvailable, isTrue);
      expect(allowed.fellBack, isFalse);
      final denied = registry.validateSelection(
        providerId: 'backend',
        modelId: 'default',
        operation: AiOperation.extractFields,
        projectId: 'denied',
      );
      expect(denied.provider.service.isAvailable, isFalse);
    },
  );
  test('the keyless backend is the default immutable catalogue entry', () {
    final ProviderRegistry registry = ProviderRegistry.keyless();

    expect(registry.catalog, hasLength(1));
    expect(registry.catalog.single.id, ProviderRegistry.backendId);
    expect(registry.catalog.single.keyCustody, ProviderKeyCustody.backend);
    expect(registry.catalog.single.deviceKeyAllowed, isFalse);
    expect(
      () => registry.catalog.add(registry.catalog.single),
      throwsUnsupportedError,
    );
    expect(
      () => registry.catalog.single.operations.add(AiOperation.transcribe),
      throwsUnsupportedError,
    );
    expect(
      () => registry.catalog.single.models.add(
        ModelDescriptor(
          id: 'extra',
          label: 'Extra',
          operations: const <AiOperation>{AiOperation.extractFields},
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test(
    'validates and resolves an injected provider without feature branches',
    () {
      final _TestAiService backend = _TestAiService();
      final _TestAiService device = _TestAiService();
      final ProviderRegistry registry = _registry(
        backend: backend,
        device: device,
      );

      final selection = registry.validateSelection(
        providerId: 'device',
        modelId: 'field-model',
        operation: AiOperation.extractFields,
      );

      expect(selection.provider.id, 'device');
      expect(selection.model.id, 'field-model');
      expect(selection.fellBack, isFalse);
      expect(
        registry.resolve(
          projectId: 'p1',
          operation: AiOperation.extractFields,
          providerId: 'device',
        ),
        same(device),
      );
    },
  );

  test('unavailable saved ids never change provider or billing account', () {
    final ProviderRegistry registry = _registry(
      backend: _TestAiService(),
      device: const AiService.unavailable(),
      deviceAvailable: false,
    );

    final saved = <String, String>{
      'provider': 'device',
      'model': 'field-model',
    };
    final selection = registry.validateSelection(
      providerId: saved['provider']!,
      modelId: saved['model']!,
      operation: AiOperation.extractFields,
    );

    expect(selection.provider.id, 'device');
    expect(selection.provider.service.isAvailable, isFalse);
    expect(selection.model.id, 'field-model');
    expect(selection.fellBack, isTrue);
    expect(saved, <String, String>{
      'provider': 'device',
      'model': 'field-model',
    });
  });

  test(
    'missing provider and model are recoverable without a fallback call',
    () {
      final ProviderRegistry registry = _registry(
        backend: _TestAiService(),
        device: _TestAiService(),
      );
      final unknown = registry.validateSelection(
        providerId: 'removed',
        modelId: 'paid-model',
        operation: AiOperation.extractFields,
      );
      expect(unknown.provider.id, 'removed');
      expect(unknown.model.id, 'paid-model');
      expect(unknown.provider.service.isAvailable, isFalse);
      expect(
        registry
            .resolve(
              projectId: 'p1',
              operation: AiOperation.extractFields,
              providerId: 'removed',
            )
            .isAvailable,
        isFalse,
      );
      final missingModel = registry.validateSelection(
        providerId: 'device',
        modelId: 'paid-model',
        operation: AiOperation.extractFields,
      );
      expect(missingModel.provider.id, 'device');
      expect(missingModel.model.id, 'paid-model');
      expect(missingModel.provider.service.isAvailable, isFalse);
    },
  );

  test('rejects duplicate ids and invalid custody/model declarations', () {
    final ProviderDescriptor backend = _backend(_TestAiService());

    expect(
      () =>
          ProviderRegistry(descriptors: <ProviderDescriptor>[backend, backend]),
      throwsArgumentError,
    );
    expect(
      () => ProviderRegistry(
        descriptors: <ProviderDescriptor>[
          ProviderDescriptor(
            id: ProviderRegistry.backendId,
            label: 'Backend',
            operations: const <AiOperation>{AiOperation.extractFields},
            keyCustody: ProviderKeyCustody.backend,
            deviceKeyAllowed: true,
            available: true,
            service: _TestAiService(),
            models: <ModelDescriptor>[
              ModelDescriptor(
                id: 'default',
                label: 'Default',
                operations: const <AiOperation>{AiOperation.extractFields},
              ),
            ],
          ),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => ProviderRegistry(
        descriptors: <ProviderDescriptor>[
          ProviderDescriptor(
            id: ProviderRegistry.backendId,
            label: 'Backend',
            operations: const <AiOperation>{AiOperation.transcribe},
            keyCustody: ProviderKeyCustody.backend,
            deviceKeyAllowed: false,
            available: true,
            service: _TestAiService(),
            models: <ModelDescriptor>[
              ModelDescriptor(
                id: 'default',
                label: 'Default',
                operations: const <AiOperation>{AiOperation.extractFields},
              ),
            ],
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test(
    'connection test tells success, a rejected key and a network fault apart',
    () async {
      final ProviderRegistry registry = _registry(
        backend: _TestAiService(),
        device: _TestAiService(),
      );

      Future<ProviderTestOutcome> outcome(Failure failure) {
        return registry.testConnection(_TestAiService(readFailure: failure));
      }

      expect(
        await registry.testConnection(_TestAiService()),
        ProviderTestOutcome.success,
      );
      expect(
        await outcome(
          const ProviderFailure(
            message: 'Invalid API key',
            kind: ProviderFailureKind.authentication,
          ),
        ),
        ProviderTestOutcome.authentication,
      );
      expect(
        await outcome(
          const NetworkFailure(message: 'Offline.', recoveryAction: 'Retry.'),
        ),
        ProviderTestOutcome.network,
      );
      expect(
        await outcome(
          const ProviderFailure(
            message: 'Service unavailable (503).',
            kind: ProviderFailureKind.unavailable,
          ),
        ),
        ProviderTestOutcome.network,
      );
    },
  );

  test(
    'extraction connection tests carry no captured evidence or OCR call',
    () async {
      final _TestAiService service = _TestAiService();
      final ProviderRegistry registry = _registry(
        backend: service,
        device: service,
      );
      expect(
        await registry.testConnection(
          service,
          operation: AiOperation.extractFields,
        ),
        ProviderTestOutcome.success,
      );
      expect(service.readCalls, 0);
      expect(service.extractionRequests, hasLength(1));
      final ExtractFieldsRequest request = service.extractionRequests.single;
      expect(request.imagePaths, isEmpty);
      expect(request.ocrText, isEmpty);
      expect(request.transcripts, isEmpty);
      expect(request.captions, isEmpty);
      expect(request.fieldLabels, isEmpty);
    },
  );

  test(
    'privacy-disabled probes cannot dispatch through an available service',
    () async {
      final _TestAiService service = _TestAiService();
      final ProviderRegistry registry = ProviderRegistry(
        descriptors: <ProviderDescriptor>[_backend(service)],
        allows: (AiOperation _) => false,
      );
      expect(
        await registry.testConnection(
          service,
          operation: AiOperation.extractFields,
        ),
        ProviderTestOutcome.unavailable,
      );
      expect(service.readCalls, 0);
      expect(service.extractionRequests, isEmpty);
    },
  );

  test('a provider error that is not about the key is not called a network '
      'fault, and the message is never read', () async {
    final ProviderRegistry registry = _registry(
      backend: _TestAiService(),
      device: _TestAiService(),
    );

    Future<ProviderTestOutcome> outcome(Failure failure) {
      return registry.testConnection(_TestAiService(readFailure: failure));
    }

    expect(
      await outcome(
        const ProviderFailure(
          message: 'Too many requests.',
          kind: ProviderFailureKind.rateLimited,
        ),
      ),
      ProviderTestOutcome.failed,
    );
    expect(
      await outcome(
        const ProviderFailure(message: 'Credential rejected (401).'),
      ),
      ProviderTestOutcome.failed,
    );
    expect(
      await outcome(const ValidationFailure()),
      ProviderTestOutcome.validation,
    );
    expect(
      await registry.testConnection(const AiService.unavailable()),
      ProviderTestOutcome.unavailable,
    );
  });
}

ProviderRegistry _registry({
  required AiService backend,
  required AiService device,
  bool deviceAvailable = true,
}) {
  return ProviderRegistry(
    descriptors: <ProviderDescriptor>[
      _backend(backend),
      ProviderDescriptor(
        id: 'device',
        label: 'Device provider',
        operations: const <AiOperation>{AiOperation.extractFields},
        keyCustody: ProviderKeyCustody.device,
        deviceKeyAllowed: true,
        available: deviceAvailable,
        service: device,
        models: <ModelDescriptor>[
          ModelDescriptor(
            id: 'field-model',
            label: 'Field model',
            operations: const <AiOperation>{AiOperation.extractFields},
          ),
        ],
      ),
    ],
  );
}

ProviderDescriptor _backend(AiService service) {
  return ProviderDescriptor(
    id: ProviderRegistry.backendId,
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
  );
}

final class _TestAiService implements AiService {
  _TestAiService({this.readFailure});

  final Failure? readFailure;
  int readCalls = 0;
  final List<ExtractFieldsRequest> extractionRequests =
      <ExtractFieldsRequest>[];

  @override
  bool get isAvailable => true;

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) async {
    readCalls++;
    final Failure? failure = readFailure;
    return failure == null
        ? const Success<ReadTextResult>(ReadTextResult(text: 'ok'))
        : FailureResult<ReadTextResult>(failure);
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
    extractionRequests.add(request);
    return const Success<ExtractFieldsResult>(
      ExtractFieldsResult(fields: <String, String?>{}),
    );
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) async {
    return Success<RefineTextResult>(RefineTextResult(text: request.raw));
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) async {
    return const Success<TranscribeResult>(TranscribeResult(text: 'ok'));
  }
}

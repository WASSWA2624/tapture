import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
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

  test('invalid or unavailable saved ids fall back without mutating input', () {
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

    expect(selection.provider.id, ProviderRegistry.backendId);
    expect(selection.model.id, 'default');
    expect(selection.fellBack, isTrue);
    expect(saved, <String, String>{
      'provider': 'device',
      'model': 'field-model',
    });
  });

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
    'connection test distinguishes success, authentication, and network',
    () async {
      final ProviderRegistry registry = _registry(
        backend: _TestAiService(),
        device: _TestAiService(),
      );

      expect(
        await registry.testConnection(_TestAiService()),
        ProviderTestOutcome.success,
      );
      expect(
        await registry.testConnection(
          _TestAiService(
            readFailure: const ProviderFailure(
              message: 'Credential rejected (401).',
              recoveryAction: 'Replace it.',
            ),
          ),
        ),
        ProviderTestOutcome.authentication,
      );
      expect(
        await registry.testConnection(
          _TestAiService(
            readFailure: const NetworkFailure(
              message: 'Offline.',
              recoveryAction: 'Retry later.',
            ),
          ),
        ),
        ProviderTestOutcome.network,
      );
    },
  );
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

  @override
  bool get isAvailable => true;

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) async {
    final Failure? failure = readFailure;
    return failure == null
        ? const Success<ReadTextResult>(ReadTextResult(text: 'ok'))
        : FailureResult<ReadTextResult>(failure);
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
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

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/ai/server_provider_registry.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';

import '../../support/ai_catalogue_fixture.dart';

void main() {
  test(
    'disabled built-in zero costs do not hide a valid custom keyless account',
    () {
      final ServerAiCatalogue catalogue = ServerAiCatalogue(
        readSnapshot: () => <Object?>[
          <String, Object?>{
            ...aiProviderMetadata(id: 'gemini', managed: false),
            'protocol': 'gemini-generate-content',
            'modelCostCeilings': <String, Object?>{
              'standard': 0,
              'accurate': 0,
            },
          },
          aiProviderMetadata(id: 'local-compatible', authMode: 'none'),
        ],
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async => (status: 503, body: <String, Object?>{}),
      );
      addTearDown(catalogue.dispose);
      final ProviderRegistry registry = serverProviderRegistry(
        catalogue: catalogue,
        proxy: ProxyAiService(
          baseUrl: 'https://organisation.test',
          send:
              ({
                required String path,
                required Map<String, Object?> json,
              }) async => (status: 503, body: '{}'),
        ),
      );
      expect(catalogue.rows, hasLength(2));
      expect(catalogue.row('gemini'), isNotNull);
      expect(
        registry.catalog
            .singleWhere((row) => row.id == 'personal-gemini')
            .available,
        isFalse,
      );
      expect(
        registry.catalog
            .singleWhere((row) => row.id == 'keyless-local-compatible')
            .available,
        isTrue,
      );
    },
  );
  test(
    'configured identity binds exact keyless provider without a credential identity',
    () {
      int requests = 0;
      final ServerAiCatalogue catalogue = ServerAiCatalogue(
        readSnapshot: () => <Object?>[
          aiProviderMetadata(id: 'local-compatible', authMode: 'none'),
          aiProviderMetadata(id: 'gemini'),
        ],
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async => (status: 503, body: <String, Object?>{}),
      );
      addTearDown(catalogue.dispose);
      final ProviderRegistry registry = serverProviderRegistry(
        catalogue: catalogue,
        proxy: ProxyAiService(
          baseUrl: 'https://organisation.test',
          send:
              ({
                required String path,
                required Map<String, Object?> json,
              }) async {
                requests++;
                return (status: 503, body: '{}');
              },
        ),
      );
      final ProviderDescriptor keyless = registry.catalog.singleWhere(
        (row) => row.id == 'keyless-local-compatible',
      );
      expect(catalogue.managedProvider, 'gemini');
      expect(
        registry.catalog
            .singleWhere((row) => row.id == ProviderRegistry.backendId)
            .serverProvider,
        'gemini',
      );
      expect(keyless.serverProvider, 'local-compatible');
      expect(keyless.serverCredentialProvider, isNull);
      expect(keyless.deviceKeyAllowed, isFalse);
      expect(keyless.operations, <AiOperation>{
        AiOperation.extractFields,
        AiOperation.refineText,
      });
      final ProxyAiService service = keyless.service as ProxyAiService;
      expect(service.billingKind, 'managed');
      expect(service.billingProvider, 'local-compatible');
      expect(requests, 0);
      expect(
        registry.catalog.any((row) => row.id == 'personal-gemini'),
        isTrue,
      );
      expect(
        registry.catalog.any((row) => row.id == 'personal-openai'),
        isTrue,
      );
      final choice = registry.validateSelection(
        providerId: keyless.id,
        modelId: 'accurate',
        operation: AiOperation.extractFields,
        projectId: 'project',
      );
      expect(choice.provider.id, keyless.id);
      expect(choice.model.id, 'accurate');
      expect(choice.fellBack, isFalse);
      final unsupported = registry.validateSelection(
        providerId: keyless.id,
        modelId: 'accurate',
        operation: AiOperation.transcribe,
      );
      expect(unsupported.provider.id, keyless.id);
      expect(unsupported.provider.service.isAvailable, isFalse);
    },
  );
}

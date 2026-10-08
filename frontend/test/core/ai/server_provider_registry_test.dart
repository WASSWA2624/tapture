import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/ai/server_provider_registry.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';

import '../../support/ai_catalogue_fixture.dart';

void main() {
  test(
    'retained xAI identity stays unavailable until exact catalogue configuration',
    () async {
      final List<Object?> rows = <Object?>[];
      int requests = 0;
      final ServerAiCatalogue catalogue = ServerAiCatalogue(
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async => (
              status: 200,
              body: <String, Object?>{'providers': List<Object?>.of(rows)},
            ),
      );
      addTearDown(catalogue.dispose);
      final ProxyAiService proxy = ProxyAiService(
        baseUrl: 'https://organisation.test',
        send:
            ({required String path, required Map<String, Object?> json}) async {
              requests++;
              return (status: 503, body: '{}');
            },
      );
      ProviderDescriptor xai() => serverProviderRegistry(
        proxy: proxy,
        catalogue: catalogue,
      ).catalog.singleWhere((value) => value.id == 'personal-xai');
      expect(xai().available, isFalse);
      expect(xai().serverProvider, 'xai');
      expect(xai().serverCredentialProvider, isNull);
      expect(xai().operations, <AiOperation>{
        AiOperation.readText,
        AiOperation.extractFields,
        AiOperation.refineText,
      });
      for (final bool configured in <bool>[true, false, true]) {
        rows.clear();
        if (configured) rows.add(xaiProviderMetadata());
        await catalogue.refresh();
        final ProviderRegistry registry = serverProviderRegistry(
          proxy: proxy,
          catalogue: catalogue,
        );
        expect(
          registry.catalog.where((value) => value.serverProvider == 'xai'),
          hasLength(1),
        );
        expect(xai().available, configured);
        expect(xai().serverCredentialProvider, configured ? 'xai' : null);
        expect(xai().operations, isNot(contains(AiOperation.transcribe)));
        if (configured) {
          expect(xai().models.map((value) => value.id), contains('grok-4.7'));
        }
      }
      expect(requests, 0);
    },
  );
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
  for (final String providerId in <String>['local-compatible', 'xai']) {
    test(
      'configured identity binds exact keyless $providerId without a credential identity',
      () {
        int requests = 0;
        final ServerAiCatalogue catalogue = ServerAiCatalogue(
          readSnapshot: () => <Object?>[
            aiProviderMetadata(id: providerId, authMode: 'none'),
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
          (row) => row.id == 'keyless-$providerId',
        );
        expect(catalogue.managedProvider, 'gemini');
        expect(
          registry.catalog
              .singleWhere((row) => row.id == ProviderRegistry.backendId)
              .serverProvider,
          'gemini',
        );
        expect(keyless.serverProvider, providerId);
        expect(keyless.serverCredentialProvider, isNull);
        expect(keyless.deviceKeyAllowed, isFalse);
        expect(keyless.operations, <AiOperation>{
          AiOperation.extractFields,
          AiOperation.refineText,
        });
        final ProxyAiService service = keyless.service as ProxyAiService;
        expect(service.billingKind, 'managed');
        expect(service.billingProvider, providerId);
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
        final baseModel = registry.validateSelection(
          providerId: keyless.id,
          modelId: 'standard',
          operation: AiOperation.extractFields,
          projectId: 'project',
        );
        expect(baseModel.provider.id, keyless.id);
        expect(baseModel.model.id, 'standard');
        expect(baseModel.fellBack, isFalse);
        final unsupported = registry.validateSelection(
          providerId: keyless.id,
          modelId: 'accurate',
          operation: AiOperation.transcribe,
        );
        expect(unsupported.provider.id, keyless.id);
        expect(unsupported.provider.service.isAvailable, isFalse);
        expect(
          registry.catalog.where((row) => row.serverProvider == providerId),
          hasLength(1),
        );
      },
    );
  }
}

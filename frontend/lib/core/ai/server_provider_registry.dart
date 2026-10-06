import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';

/// One catalogue for managed AI and explicit personal server-held accounts.
ProviderRegistry serverProviderRegistry({
  required ProxyAiService proxy,
  bool Function(AiOperation operation)? allows,
  ServerAiCatalogue? catalogue,
}) {
  final Set<AiOperation> operations = AiOperation.values.toSet();
  final List<ModelDescriptor> models = <ModelDescriptor>[
    ModelDescriptor(
      id: 'default',
      label: 'Configured default',
      operations: operations,
    ),
  ];
  return ProviderRegistry(
    allows: allows,
    descriptors: <ProviderDescriptor>[
      ProviderDescriptor(
        id: ProviderRegistry.backendId,
        label: 'Organisation-managed account',
        operations: operations,
        keyCustody: ProviderKeyCustody.backend,
        deviceKeyAllowed: false,
        available: proxy.isAvailable,
        service: proxy,
        models: models,
        modelsLookup: catalogue == null ? null : () => catalogue.models(null),
      ),
      for (final String provider in <String>['gemini', 'openai'])
        ProviderDescriptor(
          id: 'personal-$provider',
          label: 'Your $provider account',
          operations: operations,
          keyCustody: ProviderKeyCustody.backend,
          deviceKeyAllowed: false,
          serverCredentialProvider: provider,
          available: proxy.isAvailable,
          service: proxy.forBilling(kind: 'personal', provider: provider),
          models: models,
          modelsLookup: catalogue == null
              ? null
              : () => catalogue.models(provider),
        ),
    ],
  );
}

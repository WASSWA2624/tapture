import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';

/// Configured server accounts. Metadata never contains endpoints or credentials.
ProviderRegistry serverProviderRegistry({
  required ProxyAiService proxy,
  bool Function(AiOperation operation)? allows,
  ServerAiCatalogue? catalogue,
}) {
  final Set<AiOperation> all = AiOperation.values.toSet();
  final String? managed = catalogue?.managedProvider;
  ProviderDescriptor descriptor({
    required String id,
    required String label,
    required String? provider,
    required String kind,
    required bool credentials,
  }) {
    final Map<String, Object?>? row = catalogue?.row(provider);
    final bool configured = row != null;
    final bool funded =
        (row?['modelCostCeilings'] as Map<String, double>?)?.values.any(
          (double cost) => cost > 0,
        ) ??
        false;
    final Set<AiOperation> operations = configured
        ? catalogue!.operations(provider)
        : all;
    final List<ModelDescriptor> models = configured
        ? catalogue!.models(provider)
        : <ModelDescriptor>[
            ModelDescriptor(
              id: 'default',
              label: 'Configured default',
              operations: operations,
            ),
          ];
    final ProxyAiService service = id == ProviderRegistry.backendId
        ? proxy
        : proxy.forBilling(kind: kind, provider: provider);
    return ProviderDescriptor(
      id: id,
      label: label,
      operations: operations,
      keyCustody: ProviderKeyCustody.backend,
      deviceKeyAllowed: false,
      available: configured && funded && service.isAvailable,
      service: configured && funded ? service : const AiService.unavailable(),
      models: models,
      serverProvider: provider,
      serverCredentialProvider: credentials ? provider : null,
    );
  }

  return ProviderRegistry(
    allows: allows,
    descriptors: <ProviderDescriptor>[
      descriptor(
        id: ProviderRegistry.backendId,
        label: 'Organisation-managed account',
        provider: managed,
        kind: 'managed',
        credentials: false,
      ),
      // Legacy identities remain visible, even before the first metadata refresh.
      for (final String provider in <String>['gemini', 'openai'])
        descriptor(
          id: 'personal-$provider',
          label:
              'Your ${catalogue?.row(provider)?['label'] ?? provider} account',
          provider: provider,
          kind: 'personal',
          credentials: true,
        ),
      for (final Map<String, Object?> row in catalogue?.rows ?? const [])
        if (row['provider'] != 'gemini' && row['provider'] != 'openai')
          descriptor(
            id: '${row['authMode'] == 'none' ? 'keyless' : 'personal'}-${row['provider']}',
            label: row['label']! as String,
            provider: row['provider']! as String,
            kind: row['authMode'] == 'none' ? 'managed' : 'personal',
            credentials: row['authMode'] != 'none',
          ),
    ],
  );
}

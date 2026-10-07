import { createHash } from 'node:crypto';
import type { AppConfig } from '../../config/schema.js';
import type { ProviderDefinition, ProviderName } from '../../domain/ai.js';
import { invalidRequest } from '../../domain/errors.js';

/** Legacy environment values remain authoritative for the two retained entries. */
export function providerDefinitions(
  config: AppConfig,
): readonly ProviderDefinition[] {
  const builtins = (['gemini', 'openai'] as const).map(
    (id): ProviderDefinition => {
      const model =
        id === 'gemini' ? config.aiGeminiModel : config.aiOpenaiModel;
      const models = [
        model,
        ...Object.keys(config.aiModelCostCeilings)
          .filter((entry) => entry.startsWith(`${id}:`))
          .map((entry) => entry.slice(id.length + 1))
          .filter((entry) => entry !== model),
      ];
      return {
        id,
        label: id === 'gemini' ? 'Gemini' : 'OpenAI',
        protocol:
          id === 'gemini' ? 'gemini-generate-content' : 'openai-responses',
        baseUrl: id === 'gemini' ? config.aiProviderUrl : config.aiOpenaiUrl,
        authMode: 'required',
        model,
        models,
        operations: ['ocr', 'extract', 'refine', 'transcribe'],
        currency: 'configured',
        modelCostCeilings: Object.fromEntries(
          models.map((name) => [
            name,
            config.aiModelCostCeilings[`${id}:${name}`] ??
              config.aiRequestCostCeiling,
          ]),
        ),
      };
    },
  );
  return [...builtins, ...config.aiProviderCatalogue];
}

export function providerDefinition(
  config: AppConfig,
  id: ProviderName,
): ProviderDefinition {
  const provider = providerDefinitions(config).find((entry) => entry.id === id);
  if (provider === undefined)
    throw invalidRequest('Unknown analysis provider.');
  return provider;
}

/** Credential services never look up or persist a key for a keyless account. */
export function credentialProvider(config: AppConfig, id: ProviderName): void {
  if (providerDefinition(config, id).authMode !== 'required')
    throw invalidRequest('This analysis provider does not use a credential.');
}

export function providerFingerprint(provider: ProviderDefinition): string {
  return createHash('sha256')
    .update(
      JSON.stringify([
        provider.id,
        provider.protocol,
        provider.baseUrl,
        provider.authMode,
        provider.model,
        [...provider.models].sort(),
        [...provider.operations].sort(),
        provider.currency,
        Object.entries(provider.modelCostCeilings).sort(([a], [b]) =>
          a.localeCompare(b),
        ),
      ]),
    )
    .digest('hex');
}
